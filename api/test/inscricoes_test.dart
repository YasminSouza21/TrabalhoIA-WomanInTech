import 'dart:convert';
import 'dart:io';

import 'package:semana_academica_api/server.dart';
import 'package:test/test.dart';

Future<Response> request(ApiServer api, String method, String path,
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
  return Response(response.statusCode, text);
}

class Response {
  Response(this.status, this.text);
  final int status;
  final String text;
  dynamic get json => text.isEmpty ? null : jsonDecode(text);
}

void main() {
  late ApiServer api;
  setUp(() => api = ApiServer(modoTeste: true));

  test('exige X-Usuario antes de qualquer regra nas cinco rotas do M2', () async {
    final rotas = <(String, String)>[
      ('GET', '/inscricoes'),
      ('GET', '/inscricoes/ins_x'),
      ('POST', '/atividades/atv_x/inscricoes'),
      ('POST', '/inscricoes/ins_x/cancelamento'),
      ('POST', '/inscricoes/ins_x/confirmacao'),
    ];
    for (final (method, rota) in rotas) {
      expect((await request(api, method, rota)).status, 401,
          reason: '$method $rota sem cabeçalho');
      expect(
          (await request(api, method, rota, user: 'nao-existe'))
              .json['erro'],
          'USUARIO_DESCONHECIDO',
          reason: '$method $rota com id inexistente');
    }
  });

  test('recusa organização nas três mutações com 403 SOMENTE_PARTICIPANTE',
      () async {
    final rotas = <(String, String)>[
      ('POST', '/atividades/atv_x/inscricoes'),
      ('POST', '/inscricoes/ins_x/cancelamento'),
      ('POST', '/inscricoes/ins_x/confirmacao'),
    ];
    for (final (method, rota) in rotas) {
      final resposta = await request(api, method, rota, user: 'org-ana');
      expect(resposta.status, 403, reason: '$method $rota');
      expect(resposta.json['erro'], 'SOMENTE_PARTICIPANTE',
          reason: '$method $rota');
    }
  });

  test('prioriza existência: 404 vem antes do corpo e vale nas rotas de leitura',
      () async {
    final criar = await request(api, 'POST', '/atividades/atv_x/inscricoes',
        user: 'p-carla', body: 'nao-json');
    expect(criar.status, 404, reason: 'atividade inexistente precede corpo');
    expect(criar.json['erro'], 'NAO_ENCONTRADO');
    expect(
        (await request(api, 'GET', '/inscricoes/ins_x', user: 'p-carla'))
            .json['erro'],
        'NAO_ENCONTRADO');
    for (final rota in [
      '/inscricoes/ins_x/cancelamento',
      '/inscricoes/ins_x/confirmacao'
    ]) {
      final resposta = await request(api, 'POST', rota,
          user: 'p-carla', body: 'nao-json');
      expect(resposta.status, 404, reason: rota);
      expect(resposta.json['erro'], 'NAO_ENCONTRADO', reason: rota);
    }
  });

  test('valida corpo após identificação, perfil e existência da atividade',
      () async {
    final criada = await request(api, 'POST', '/atividades',
        user: 'org-ana',
        body: {
          'titulo': 'Alvo',
          'tipo': 'palestra',
          'salaId': 'sala-101',
          'vagas': 2,
          'encontros': [
            {
              'inicio': '2026-10-19T09:00:00-03:00',
              'fim': '2026-10-19T10:00:00-03:00'
            }
          ]
        });
    final atividadeId = criada.json['id'];
    for (final malformado in ['nao-json', '"apenas-texto"', '[1,2]', '42']) {
      final resposta = await request(api, 'POST',
          '/atividades/$atividadeId/inscricoes',
          user: 'p-carla', body: malformado);
      expect(resposta.status, 422, reason: 'corpo $malformado');
      expect(resposta.json['erro'], 'DADOS_INVALIDOS',
          reason: 'corpo $malformado');
    }
    final objeto = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla', body: {});
    expect(objeto.json['erro'], isNot('DADOS_INVALIDOS'),
        reason: 'objeto bem formado é ignorado, não rejeitado');
  });

  test('reset zera o estado e a listagem começa vazia para todo identificado',
      () async {
    expect((await request(api, 'POST', '/_teste/reset')).status, 204);
    for (final user in ['p-carla', 'p-diego', 'org-ana']) {
      final lista =
          await request(api, 'GET', '/inscricoes', user: user);
      expect(lista.status, 200, reason: user);
      expect(lista.json, isEmpty, reason: user);
    }
    final filtro = await request(api, 'GET',
        '/inscricoes?atividadeId=atv_qualquer',
        user: 'p-carla');
    expect(filtro.status, 200);
    expect(filtro.json, isEmpty);
    expect(
        (await request(api, 'GET', '/inscricoes/ins_qualquer',
                user: 'p-carla'))
            .json['erro'],
        'NAO_ENCONTRADO');
  });

  test('inscreve com vaga disponível: 201 confirmada no modelo exato (R07, R42)',
      () async {
    final atividadeId = await criarAtividade(api);
    final resposta = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla');
    expect(resposta.status, 201);
    final inscricao = resposta.json;
    expect(inscricao.keys, [
      'id', 'atividadeId', 'participanteId', 'status',
      'posicaoNaEspera', 'convocadaAte', 'criadaEm'
    ]);
    expect(inscricao['id'], matches(RegExp(r'^ins_[0-9a-f]{8}$')));
    expect(inscricao['atividadeId'], atividadeId);
    expect(inscricao['participanteId'], 'p-carla');
    expect(inscricao['status'], 'confirmada');
    expect(inscricao['posicaoNaEspera'], isNull);
    expect(inscricao['convocadaAte'], isNull);
    expect(inscricao['criadaEm'], '2026-10-13T12:00:00Z');
    final erro = await request(api, 'GET',
        '/atividades/$atividadeId',
        user: 'p-carla');
    expect(erro.json['ocupadas'], 1, reason: 'erro jamais mascara resposta');
  });

  test(
      'lotada entra na espera com posição FIFO 1..N derivada e relógio parado (R07, R16, R17, R18)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final carla = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla');
    final diego = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-diego');
    expect(carla.json['status'], 'confirmada');
    expect(diego.json['status'], 'confirmada');
    expect(carla.json['criadaEm'], diego.json['criadaEm'],
        reason: 'relógio de teste parado: timestamps empatam');
    final elisa = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-elisa');
    final fabio = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-fabio');
    final gabriela = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-gabriela');
    for (final resposta in [elisa, fabio, gabriela]) {
      expect(resposta.status, 201);
      expect(resposta.json['status'], 'em_espera');
    }
    expect(elisa.json['posicaoNaEspera'], 1);
    expect(fabio.json['posicaoNaEspera'], 2);
    expect(gabriela.json['posicaoNaEspera'], 3);
    expect(elisa.json['convocadaAte'], isNull);
    final lista = (await request(api, 'GET', '/inscricoes',
            user: 'org-ana'))
        .json as List;
    expect(lista.map((item) => item['participanteId']),
        ['p-carla', 'p-diego', 'p-elisa', 'p-fabio', 'p-gabriela']);
    expect(lista.map((item) => item['posicaoNaEspera']),
        [isNull, isNull, 1, 2, 3]);
  });

  test(
      'recusa segunda inscrição ativa com 409 JA_INSCRITO em confirmada e em_espera (R13)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla');
    final repetida =
        await request(api, 'POST', '/atividades/$atividadeId/inscricoes',
            user: 'p-carla');
    expect(repetida.status, 409);
    expect(repetida.json['erro'], 'JA_INSCRITO');
    await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-diego');
    final repetidaNaEspera = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-diego');
    expect(repetidaNaEspera.status, 409);
    expect(repetidaNaEspera.json['erro'], 'JA_INSCRITO');
    expect((await request(api, 'GET', '/inscricoes',
            user: 'org-ana'))
        .json, hasLength(2));
  });

  test(
      'precede ATIVIDADE_CANCELADA e INSCRICOES_ENCERRADAS na frente de JA_INSCRITO (R12)',
      () async {
    final cancelada = await criarAtividade(api, dia: '2026-10-20');
    await request(api, 'POST', '/atividades/$cancelada/inscricoes',
        user: 'p-carla');
    expect(
        (await request(api, 'POST', '/atividades/$cancelada/cancelamento',
                user: 'org-ana'))
            .status,
        200);
    final apagada = await request(api, 'POST',
        '/atividades/$cancelada/inscricoes',
        user: 'p-carla');
    expect(apagada.status, 422);
    expect(apagada.json['erro'], 'ATIVIDADE_CANCELADA');

    final encerrada = await criarAtividade(api, dia: '2026-10-21');
    await request(api, 'POST', '/atividades/$encerrada/inscricoes',
        user: 'p-carla');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-21T09:00:00-03:00'});
    final terminada = await request(api, 'POST',
        '/atividades/$encerrada/inscricoes',
        user: 'p-carla');
    expect(terminada.status, 422);
    expect(terminada.json['erro'], 'INSCRICOES_ENCERRADAS');
  });

  test(
      'inscrições encerram em agora==inicio e em iniciada/encerrada; cancelada vence (R08, R09, R11)',
      () async {
    final id =
        await criarAtividade(api, vagas: 5, dia: '2026-10-21');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-21T09:00:00-03:00'});
    final borda = await request(api, 'POST',
        '/atividades/$id/inscricoes',
        user: 'p-carla');
    expect(borda.json['erro'], 'INSCRICOES_ENCERRADAS',
        reason: 'agora == inicio é borda inclusiva do encerramento');

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-21T09:30:00-03:00'});
    final emAndamento = await request(api, 'POST',
        '/atividades/$id/inscricoes',
        user: 'p-diego');
    expect(emAndamento.json['erro'], 'INSCRICOES_ENCERRADAS',
        reason: 'atividade em andamento não aceita inscrição');

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-21T10:00:00-03:00'});
    final encerrada = await request(api, 'POST',
        '/atividades/$id/inscricoes',
        user: 'p-elisa');
    expect(encerrada.json['erro'], 'INSCRICOES_ENCERRADAS');

    final cancelavel = await criarAtividade(api, vagas: 5, dia: '2026-10-22');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-13T09:00:00-03:00'});
    await request(api, 'POST', '/atividades/$cancelavel/cancelamento',
        user: 'org-ana');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-22T09:00:00-03:00'});
    final aposCancelamento = await request(api, 'POST',
        '/atividades/$cancelavel/inscricoes',
        user: 'p-carla');
    expect(aposCancelamento.json['erro'], 'ATIVIDADE_CANCELADA',
        reason: 'cancelada vence mesmo com relógio após o início');
  });

  test('aceita corpo ausente e objeto bem formado nas três tentativas (R04)',
      () async {
    final semCorpo = await criarAtividade(api);
    final ausente = await request(api, 'POST',
        '/atividades/$semCorpo/inscricoes',
        user: 'p-carla');
    expect(ausente.status, 201, reason: 'rotas de mutação sem corpo são aceitas');
    final comVazio = await criarAtividade(api, dia: '2026-10-20');
    final objeto = await request(api, 'POST',
        '/atividades/$comVazio/inscricoes',
        user: 'p-diego', body: {});
    expect(objeto.status, 201, reason: 'corpo {} ignorado');
    final comConteudo = await criarAtividade(api, dia: '2026-10-21');
    final campo =
        await request(api, 'POST', '/atividades/$comConteudo/inscricoes',
            user: 'p-elisa', body: {'qualquer': 'coisa'});
    expect(campo.status, 201, reason: 'objeto bem formado é ignorado');
    List<dynamic> inscricoes =
        (await request(api, 'GET', '/inscricoes', user: 'org-ana')).json;
    expect(inscricoes, hasLength(3));
  });

  test(
      'isola participante das alheias, mantém ordem de inserção e filtra por atividade (R37, R38, R39)',
      () async {
    final atvA = await criarAtividade(api, vagas: 5);
    final atvB = await criarAtividade(api, vagas: 5, dia: '2026-10-20');
    final insCarla = await request(api, 'POST',
        '/atividades/$atvA/inscricoes',
        user: 'p-carla');
    final insDiego = await request(api, 'POST',
        '/atividades/$atvB/inscricoes',
        user: 'p-diego');
    final insElisa = await request(api, 'POST',
        '/atividades/$atvA/inscricoes',
        user: 'p-elisa');

    final daCarla = (await request(api, 'GET', '/inscricoes',
        user: 'p-carla')).json as List;
    expect(daCarla, hasLength(1));
    expect(daCarla.single['id'], insCarla.json['id']);
    final daOrg = (await request(api, 'GET', '/inscricoes',
        user: 'org-ana')).json as List;
    expect(daOrg.map((item) => item['participanteId']),
        ['p-carla', 'p-diego', 'p-elisa'],
        reason: 'ordem ascendente de inserção');
    final filtroDoDiego = (await request(api, 'GET',
        '/inscricoes?atividadeId=$atvA',
        user: 'p-diego')).json as List;
    expect(filtroDoDiego, isEmpty,
        reason: 'filtro mantém o isolamento do participante');
    final filtroDaOrg = (await request(api, 'GET',
        '/inscricoes?atividadeId=$atvA',
        user: 'org-ana')).json as List;
    expect(filtroDaOrg.map((item) => item['participanteId']),
        ['p-carla', 'p-elisa']);
    expect(
        (await request(api, 'GET', '/inscricoes?atividadeId=atv_sem_inscricao',
                user: 'org-ana'))
            .json,
        isEmpty);

    expect(
        (await request(api, 'GET', '/inscricoes/${insElisa.json['id']}',
                user: 'p-carla'))
            .json['erro'],
        'NAO_ENCONTRADO');
    expect(
        (await request(api, 'GET', '/inscricoes/${insElisa.json['id']}',
                user: 'org-ana'))
            .json['id'],
        insElisa.json['id']);
    expect(
        (await request(api, 'GET', '/inscricoes/${insDiego.json['id']}',
                user: 'p-diego'))
            .json['id'],
        insDiego.json['id']);
  });

  test('reset realmente apaga as inscrições criadas (R06, R41)', () async {
    final atvA = await criarAtividade(api, vagas: 2);
    await request(api, 'POST', '/atividades/$atvA/inscricoes',
        user: 'p-carla');
    await request(api, 'POST', '/atividades/$atvA/inscricoes',
        user: 'p-diego');
    expect((await request(api, 'GET', '/inscricoes', user: 'org-ana')).json,
        hasLength(2));
    expect((await request(api, 'POST', '/_teste/reset')).status, 204);
    for (final user in ['p-carla', 'p-diego', 'p-elisa', 'org-ana']) {
      expect((await request(api, 'GET', '/inscricoes', user: user)).json,
          isEmpty,
          reason: user);
    }
    expect(
        (await request(api, 'GET', '/inscricoes?atividadeId=$atvA',
                user: 'org-ana'))
            .json,
        isEmpty);
    expect((await request(api, 'GET', '/inscricoes/ins_qualquer',
            user: 'org-ana')).json['erro'],
        'NAO_ENCONTRADO');
  });

  test('reflete inscrições nos calculados ocupadas/vagasRestantes/emEspera (R43)',
      () async {
    final atvA = await criarAtividade(api, vagas: 2);
    await request(api, 'POST', '/atividades/$atvA/inscricoes',
        user: 'p-carla');
    expect(
        (await request(api, 'GET', '/atividades/$atvA', user: 'p-carla'))
            .json['ocupadas'],
        1);
    await request(api, 'POST', '/atividades/$atvA/inscricoes',
        user: 'p-diego');
    final cheiaMeiaVaga =
        await request(api, 'GET', '/atividades/$atvA', user: 'p-carla');
    expect(cheiaMeiaVaga.json['ocupadas'], 2);
    expect(cheiaMeiaVaga.json['vagasRestantes'], 0);
    expect(cheiaMeiaVaga.json['emEspera'], 0);
    await request(api, 'POST', '/atividades/$atvA/inscricoes',
        user: 'p-elisa');
    final comEspera = await request(api, 'POST', '/atividades/$atvA/inscricoes',
        user: 'p-fabio');
    expect(comEspera.json['posicaoNaEspera'], 2);
    final detalhe =
        await request(api, 'GET', '/atividades/$atvA', user: 'p-carla');
    expect(detalhe.json['ocupadas'], 2);
    expect(detalhe.json['vagasRestantes'], 0);
    expect(detalhe.json['emEspera'], 2);
  });
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