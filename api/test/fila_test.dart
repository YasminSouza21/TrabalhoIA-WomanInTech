import 'dart:convert';
import 'dart:io';

import 'package:semana_academica_api/server.dart';
import 'package:test/test.dart';

Future<HttpResponse> request(ApiServer api, String method, String path,
    {String? user, Object? body}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(api.handle);
  final client = HttpClient();
  final request = await client.openUrl(
      method, Uri.parse('http://127.0.0.1:${server.port}$path'));
  if (user != null) request.headers.set('X-Usuario', user);
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(body is String ? body : jsonEncode(body));
  }
  final response = await request.close();
  final text = await utf8.decoder.bind(response).join();
  await server.close(force: true);
  client.close(force: true);
  return HttpResponse(response.statusCode, text);
}

class HttpResponse {
  HttpResponse(this.status, this.text);
  final int status;
  final String text;
  dynamic get json => text.isEmpty ? null : jsonDecode(text);
}

Future<String> criarAtividade(ApiServer api,
    {int vagas = 2,
    String dia = '2026-10-19',
    String inicio = '09:00',
    String fim = '10:00'}) async {
  final criada = await request(api, 'POST', '/atividades',
      user: 'org-ana',
      body: {
        'titulo': 'Alvo',
        'tipo': 'palestra',
        'salaId': 'sala-101',
        'vagas': vagas,
        'encontros': [
          {
            'inicio': '${dia}T$inicio:00-03:00',
            'fim': '${dia}T$fim:00-03:00'
          }
        ]
      });
  return criada.json['id'] as String;
}

Future<String> inscrever(ApiServer api, String atividadeId, String user) async {
  final resposta = await request(api, 'POST',
      '/atividades/$atividadeId/inscricoes',
      user: user);
  return resposta.json['id'] as String;
}

void main() {
  late ApiServer api;
  setUp(() => api = ApiServer(modoTeste: true));

  test(
      'cancela própria inscrição confirmada antes do início: 200 cancelada com posição e prazo nulos (R33)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final inscricaoId = await inscrever(api, atividadeId, 'p-carla');
    final cancelada = await request(api, 'POST',
        '/inscricoes/$inscricaoId/cancelamento',
        user: 'p-carla');
    expect(cancelada.status, 200);
    expect(cancelada.json['id'], inscricaoId);
    expect(cancelada.json['status'], 'cancelada');
    expect(cancelada.json['posicaoNaEspera'], isNull);
    expect(cancelada.json['convocadaAte'], isNull);
  });

  test(
      'iniciada (agora>=inicio inclusive) devolve ATIVIDADE_JA_INICIADA antes de INSCRICAO_INATIVA (R33, R34)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 3, dia: '2026-10-20');
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    expect((await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
            user: 'p-carla'))
        .status, 200);

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-20T09:00:00-03:00'});

    final ativa =
        await request(api, 'POST', '/inscricoes/$doDiego/cancelamento',
            user: 'p-diego');
    expect(ativa.status, 422);
    expect(ativa.json['erro'], 'ATIVIDADE_JA_INICIADA',
        reason: 'agora == inicio é borda inclusiva do início');

    final inativa =
        await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
            user: 'p-carla');
    expect(inativa.status, 422);
    expect(inativa.json['erro'], 'ATIVIDADE_JA_INICIADA',
        reason: 'início vem antes de INSCRICAO_INATIVA');
  });

  test('recusa cancelar inscrição já cancelada antes do início (R35)', () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final inscricaoId = await inscrever(api, atividadeId, 'p-carla');
    expect((await request(api, 'POST', '/inscricoes/$inscricaoId/cancelamento',
            user: 'p-carla'))
        .status, 200);
    final repetida =
        await request(api, 'POST', '/inscricoes/$inscricaoId/cancelamento',
            user: 'p-carla');
    expect(repetida.status, 422);
    expect(repetida.json['erro'], 'INSCRICAO_INATIVA');
    expect(
        (await request(api, 'GET', '/inscricoes/$inscricaoId',
                user: 'p-carla'))
            .json['status'],
        'cancelada', reason: 'recusa não desfaz o cancelamento');
  });

  test(
      'inscrição alheia devolve 404 em GET, cancelamento e confirmação antes do corpo (R37)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final respostaGet =
        await request(api, 'GET', '/inscricoes/$doDiego', user: 'p-carla');
    expect(respostaGet.status, 404);
    expect(respostaGet.json['erro'], 'NAO_ENCONTRADO');
    for (final rota in ['cancelamento', 'confirmacao']) {
      final alheia = await request(api, 'POST',
          '/inscricoes/$doDiego/$rota',
          user: 'p-carla', body: 'nao-json');
      expect(alheia.status, 404, reason: rota);
      expect(alheia.json['erro'], 'NAO_ENCONTRADO',
          reason: '$rota alheia precede corpo');
    }
    expect(
        (await request(api, 'GET', '/inscricoes/$doDiego', user: 'org-ana'))
            .json['id'],
        doDiego,
        reason: 'organização consulta todas, mas não muta');
  });

  test(
      'cancelar confirmada libera vaga e convoca o primeiro da fila com prazo agora+24h, ocupando a vaga (R19, R21, R43)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');

    final cancelada = await request(api, 'POST',
        '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    expect(cancelada.json['status'], 'cancelada');

    final convocada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocada.status, 200);
    expect(convocada.json['status'], 'convocada',
        reason: 'FIFO: elisa é a primeira da espera');
    expect(convocada.json['posicaoNaEspera'], isNull);
    expect(convocada.json['convocadaAte'], '2026-10-14T12:00:00Z',
        reason: 'agora+24h, dentro do início do primeiro encontro');

    final aindaEspera =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(aindaEspera.json['status'], 'em_espera');
    expect(aindaEspera.json['posicaoNaEspera'], 1,
        reason: 'fila recompactada com a saída de elisa');

    final detalhe =
        await request(api, 'GET', '/atividades/$atividadeId', user: 'p-carla');
    expect(detalhe.json['ocupadas'], 2,
        reason: 'convocada ocupa a vaga deixada pela cancelada');
    expect(detalhe.json['emEspera'], 1);
    expect(detalhe.json['vagasRestantes'], 0);
    final listaDaCarla = (await request(api, 'GET',
        '/inscricoes?atividadeId=$atividadeId',
        user: 'p-carla')).json as List;
    expect(listaDaCarla.map((item) => item['id']), [daCarla],
        reason: 'isolamento: o dono vê só a própria, e ela continua cancelada');
    expect(listaDaCarla.single['status'], 'cancelada');
  });

  test('convocação é limitada ao início do primeiro encontro quando agora+24h passa dele (R21)',
      () async {
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-18T20:00:00Z'});
    final atividadeId = await criarAtividade(api, vagas: 1);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    final convocada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocada.json['status'], 'convocada');
    expect(convocada.json['convocadaAte'], '2026-10-19T12:00:00Z',
        reason: 'prazo vira o início, não agora+24h que passaria dele');
  });

  test('cancelar convocada libera a vaga e convoca o próximo da fila em FIFO (R19)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');

    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    final convocada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocada.json['status'], 'convocada');

    final cancelada = await request(api, 'POST',
        '/inscricoes/$daElisa/cancelamento',
        user: 'p-elisa');
    expect(cancelada.status, 200);
    expect(cancelada.json['status'], 'cancelada');
    expect(cancelada.json['convocadaAte'], isNull,
        reason: 'prazo limpo na cancelada');

    final promovido =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(promovido.json['status'], 'convocada');
    expect(promovido.json['convocadaAte'], '2026-10-14T12:00:00Z');

    final restante =
        await request(api, 'GET', '/inscricoes/$daGabriela',
            user: 'p-gabriela');
    expect(restante.json['status'], 'em_espera');
    expect(restante.json['posicaoNaEspera'], 1);

    final detalhe =
        await request(api, 'GET', '/atividades/$atividadeId', user: 'p-carla');
    expect(detalhe.json['ocupadas'], 1);
    expect(detalhe.json['emEspera'], 1);
  });

  test('cancelar em_espera recompacta a fila sem liberar vaga nem ocupar (R18)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    await inscrever(api, atividadeId, 'p-carla');
    await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');

    final cancelada = await request(api, 'POST',
        '/inscricoes/$daElisa/cancelamento',
        user: 'p-elisa');
    expect(cancelada.status, 200);
    expect(cancelada.json['status'], 'cancelada');
    expect(cancelada.json['posicaoNaEspera'], isNull);

    final promovido =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(promovido.json['status'], 'em_espera',
        reason: 'saída de espera não convoca');
    expect(promovido.json['posicaoNaEspera'], 1,
        reason: 'fila recompactada de 1');
    final restante =
        await request(api, 'GET', '/inscricoes/$daGabriela',
            user: 'p-gabriela');
    expect(restante.json['posicaoNaEspera'], 2,
        reason: 'quem sai faz os demais subirem');

    final detalhe =
        await request(api, 'GET', '/atividades/$atividadeId', user: 'p-carla');
    expect(detalhe.json['ocupadas'], 2, reason: 'nenhuma vaga foi aberta');
    expect(detalhe.json['emEspera'], 2);
  });

  test('PATCH aumento de vagas convoca quantas couberem em FIFO sem pular (R19)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');

    final patched = await request(api, 'PATCH', '/atividades/$atividadeId',
        user: 'org-ana', body: {'vagas': 3});
    expect(patched.status, 200);
    expect(patched.json['vagas'], 3);
    expect(patched.json['ocupadas'], 3, reason: 'convocadas preenchem as novas vagas');
    expect(patched.json['emEspera'], 1);

    final convocada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocada.json['status'], 'convocada');
    expect(convocada.json['convocadaAte'], '2026-10-14T12:00:00Z');
    final segundo =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(segundo.json['status'], 'convocada',
        reason: 'segunda nova vaga convoca o próximo, sem pular');
    final restante =
        await request(api, 'GET', '/inscricoes/$daGabriela',
            user: 'p-gabriela');
    expect(restante.json['status'], 'em_espera');
    expect(restante.json['posicaoNaEspera'], 1);
  });

  test('redução de vagas abaixo de confirmadas+convocadas recusa e não muta (R19, R43)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    await inscrever(api, atividadeId, 'p-carla');
    await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    await request(api, 'PATCH', '/atividades/$atividadeId',
        user: 'org-ana', body: {'vagas': 3});

    final recusado = await request(api, 'PATCH', '/atividades/$atividadeId',
        user: 'org-ana', body: {'vagas': 2});
    expect(recusado.status, 409);
    expect(recusado.json['erro'], 'VAGAS_ABAIXO_DOS_INSCRITOS');

    final detalhe =
        await request(api, 'GET', '/atividades/$atividadeId', user: 'p-carla');
    expect(detalhe.json['vagas'], 3, reason: 'vagas não foram reduzidas');
    expect(detalhe.json['ocupadas'], 3,
        reason: 'convocada conta como ocupada e permanece');
    final convocada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocada.json['status'], 'convocada',
        reason: 'recusa não desfaz a convocação');
  });

  test('cancelar atividade converte ativas em cancelada, limpa prazos e esvazia a fila (R36)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    final convocada =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(convocada.json['status'], 'convocada');

    final cancelada = await request(api, 'POST',
        '/atividades/$atividadeId/cancelamento',
        user: 'org-ana');
    expect(cancelada.status, 200);
    expect(cancelada.json['situacao'], 'cancelada');

    final confirmada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(confirmada.json['status'], 'cancelada');
    final convocadaCancelada =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(convocadaCancelada.json['status'], 'cancelada',
        reason: 'convocada vira cancelada');
    expect(convocadaCancelada.json['convocadaAte'], isNull,
        reason: 'prazo limpo pelo cancelamento da atividade');
    final naEsperaCancelado =
        await request(api, 'GET', '/inscricoes/$doDiego', user: 'p-diego');
    expect(naEsperaCancelado.json['status'], 'cancelada');
    expect(naEsperaCancelado.json['posicaoNaEspera'], isNull);

    final inativo = await request(api, 'POST',
        '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    expect(inativo.json['erro'], 'INSCRICAO_INATIVA',
        reason: 'cancelada da atividade não é mais cancelável');

    final todas = (await request(api, 'GET', '/inscricoes', user: 'org-ana')).json;
    expect(todas.where((item) => item['status'] == 'em_espera'), isEmpty,
        reason: 'fila esvaziada');

    final obstruida = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla');
    expect(obstruida.json['erro'], 'ATIVIDADE_CANCELADA');
  });

  test('reinscrever cancelada cria novo id no fim da fila; convocada e espera seguem 409 (R13, R14)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final antiga = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    await inscrever(api, atividadeId, 'p-fabio');
    await request(api, 'POST', '/inscricoes/$antiga/cancelamento',
        user: 'p-carla');
    expect(
        (await request(api, 'GET', '/inscricoes/$daElisa',
                user: 'p-elisa'))
            .json['status'],
        'convocada', reason: 'vaga abriu pela cancelada de carla');
    expect(
        (await request(api, 'POST', '/atividades/$atividadeId/inscricoes',
                user: 'p-elisa'))
            .json['erro'],
        'JA_INSCRITO',
        reason: 'convocada é inscrição ativa: duplicidade recusada');
    expect(
        (await request(api, 'POST', '/atividades/$atividadeId/inscricoes',
                user: 'p-fabio'))
            .json['erro'],
        'JA_INSCRITO');

    final nova = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla');
    expect(nova.status, 201);
    expect(nova.json['id'], isNot(antiga),
        reason: 'reinscrição gera novo id, nunca reconvoca o antigo');
    expect(nova.json['status'], 'em_espera');
    expect(nova.json['posicaoNaEspera'], 2,
        reason: 'fim da fila, depois de fabio que já esperava');
    final antigaRegistro =
        await request(api, 'GET', '/inscricoes/$antiga', user: 'p-carla');
    expect(antigaRegistro.json['status'], 'cancelada',
        reason: 'registro antigo permanece cancelado');
  });

  test('após o início do primeiro encontro, aumento de vagas não convoca (R26 nesta fatia)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1, dia: '2026-10-20');
    await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-20T09:00:00-03:00'});

    final patched = await request(api, 'PATCH', '/atividades/$atividadeId',
        user: 'org-ana', body: {'vagas': 2});
    expect(patched.status, 200);
    expect(patched.json['vagas'], 2, reason: 'vagas sobem mesmo assim');
    expect(patched.json['ocupadas'], 1);
    expect(patched.json['emEspera'], 1);

    final naEspera =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(naEspera.json['status'], 'em_espera',
        reason: 'não há novas convocações após o início');
    expect(naEspera.json['convocadaAte'], isNull);
  });

  test(
      'cancelamento e confirmação recusam corpo malformado ou raiz não-objeto, aceitam ausente e objeto (R04)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 4);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    for (final malformado in ['nao-json', '"apenas-texto"', '[1,2]', '42']) {
      final cancelamento = await request(api, 'POST',
          '/inscricoes/$daCarla/cancelamento',
          user: 'p-carla', body: malformado);
      expect(cancelamento.status, 422, reason: 'corpo $malformado');
      expect(cancelamento.json['erro'], 'DADOS_INVALIDOS',
          reason: 'corpo $malformado');
      final confirmacao = await request(api, 'POST',
          '/inscricoes/$daCarla/confirmacao',
          user: 'p-carla', body: malformado);
      expect(confirmacao.status, 422, reason: 'confirmação corpo $malformado');
      expect(confirmacao.json['erro'], 'DADOS_INVALIDOS',
          reason: 'confirmação corpo $malformado');
    }

    final comObjeto = await request(api, 'POST',
        '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla', body: {});
    expect(comObjeto.status, 200, reason: 'objeto bem formado é ignorado');

    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final semCorpo = await request(api, 'POST',
        '/inscricoes/$doDiego/cancelamento',
        user: 'p-diego');
    expect(semCorpo.status, 200, reason: 'corpo ausente é aceito');

    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final confirmacaoPlaceholder = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa', body: {});
    expect(confirmacaoPlaceholder.status, 501,
        reason: 'objeto válido passa do corpo e mantém a confirmação como placeholder');
  });
}