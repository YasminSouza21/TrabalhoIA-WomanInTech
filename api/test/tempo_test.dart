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
    {int vagas = 1,
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

Future<void> relogio(ApiServer api, String agora) async {
  await request(api, 'PUT', '/_teste/relogio', body: {'agora': agora});
}

void main() {
  late ApiServer api;
  setUp(() => api = ApiServer(modoTeste: true));

  test(
      'leitura expira convocada vencida, libera a vaga e convoca o próximo no instante do vencimento (R23, R24)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');

    final convocada = await request(api, 'GET', '/inscricoes/$daElisa',
        user: 'p-elisa');
    expect(convocada.json['status'], 'convocada');
    expect(convocada.json['convocadaAte'], '2026-10-14T12:00:00Z',
        reason: 'agora+24h antes do início');

    await relogio(api, '2026-10-14T13:00:00Z');

    final expirada = await request(api, 'GET', '/inscricoes/$daElisa',
        user: 'p-elisa');
    expect(expirada.json['status'], 'expirada',
        reason: 'leitura reprocessa vencimentos pelo relógio (R23)');
    expect(expirada.json['convocadaAte'], isNull);

    final promovido = await request(api, 'GET', '/inscricoes/$doFabio',
        user: 'p-fabio');
    expect(promovido.json['status'], 'convocada',
        reason: 'expirada libera a vaga e convoca o próximo em FIFO (R24)');
    expect(promovido.json['convocadaAte'], '2026-10-15T12:00:00Z',
        reason: 'prazo usa o instante do vencimento anterior +24h, nunca agora final');

    final detalhe = await request(api, 'GET', '/atividades/$atividadeId',
        user: 'p-carla');
    expect(detalhe.json['ocupadas'], 1,
        reason: 'convocada promovida ocupa a vaga da expirada');
    expect(detalhe.json['emEspera'], 0);
    expect(detalhe.json['vagasRestantes'], 0);
  });

  test(
      'expirada por vencimento devolve CONVOCACAO_EXPIRADA mesmo após leitura e retrocesso; retrocesso não desfaz história (R31, R27)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');

    await relogio(api, '2026-10-14T13:00:00Z');
    final expirada = await request(api, 'GET', '/inscricoes/$daElisa',
        user: 'p-elisa');
    expect(expirada.json['status'], 'expirada',
        reason: 'leitura materializa a expiração');

    await relogio(api, '2026-10-13T09:00:00Z');
    final aposRetrocesso = await request(api, 'GET', '/inscricoes/$daElisa',
        user: 'p-elisa');
    expect(aposRetrocesso.json['status'], 'expirada',
        reason: 'retrocesso não desfaz transição histórica já observada (R27)');

    final confirmar = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa');
    expect(confirmar.status, 422);
    expect(confirmar.json['erro'], 'CONVOCACAO_EXPIRADA',
        reason: 'vencida pelo relógio precede SEM_CONVOCACAO mesmo expirada (R31)');
  });

  test(
      'no início do primeiro encontro: convocada vencida expira, espera expira, confirmada é preservada e cessam as convocações (R26)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');

    await relogio(api, '2026-10-18T00:00:00Z');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');

    final convocada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocada.json['status'], 'convocada');
    expect(convocada.json['convocadaAte'], '2026-10-19T00:00:00Z',
        reason: '10-18T00Z + 24h = 10-19T00Z, antes do início 10-19T12Z');

    await relogio(api, '2026-10-19T12:00:00Z');

    final vencidaNoInicio =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(vencidaNoInicio.json['status'], 'expirada',
        reason: 'convocada promovida no vencimento anterior tem prazo no início e expira nele (R26)');
    final esperaNoInicio =
        await request(api, 'GET', '/inscricoes/$daGabriela', user: 'p-gabriela');
    expect(esperaNoInicio.json['status'], 'expirada',
        reason: 'a fila em_espera encerra como expirada no início do encontro (R26)');
    expect(esperaNoInicio.json['convocadaAte'], isNull);
    final confirmada =
        await request(api, 'GET', '/inscricoes/$doDiego', user: 'p-diego');
    expect(confirmada.json['status'], 'confirmada',
        reason: 'confirmada não é tocada');

    final detalhe = await request(api, 'GET', '/atividades/$atividadeId',
        user: 'p-diego');
    expect(detalhe.json['ocupadas'], 1,
        reason: 'vaga do início aberta pela expiração não convoca ninguém (cessam convocações)');
    expect(detalhe.json['vagasRestantes'], 1);
    expect(detalhe.json['emEspera'], 0, reason: 'fila encerrada como expirada');
  });

  test(
      'salto reprocessa a cadeia cronológica: cada prazo vem do vencimento anterior, contadores e posições consistentes (R25, R43)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');
    final doHeitor = await inscrever(api, atividadeId, 'p-heitor');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');

    await relogio(api, '2026-10-14T13:00:00Z');
    final expirada1 =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(expirada1.json['status'], 'expirada');
    final promovido1 =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(promovido1.json['status'], 'convocada');
    expect(promovido1.json['convocadaAte'], '2026-10-15T12:00:00Z',
        reason: 'prazo = vencimento da anterior (10-14T12)+24h, não agora 10-14T13+24h');
    final aindaEspera =
        await request(api, 'GET', '/inscricoes/$daGabriela', user: 'p-gabriela');
    expect(aindaEspera.json['status'], 'em_espera');
    expect(aindaEspera.json['posicaoNaEspera'], 1);
    final detalhe1 =
        await request(api, 'GET', '/atividades/$atividadeId', user: 'p-carla');
    expect(detalhe1.json['ocupadas'], 1);
    expect(detalhe1.json['emEspera'], 2, reason: 'posições não foram perdidas');

    await relogio(api, '2026-10-15T13:00:00Z');
    final expirada2 =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(expirada2.json['status'], 'expirada',
        reason: 'segundo elo da cadeia vence no seu próprio prazo');
    final promovido2 =
        await request(api, 'GET', '/inscricoes/$daGabriela', user: 'p-gabriela');
    expect(promovido2.json['status'], 'convocada');
    expect(promovido2.json['convocadaAte'], '2026-10-16T12:00:00Z',
        reason: 'prazo = vencimento do elo anterior (10-15T12)+24h, não agora');
    final aindaEspera2 =
        await request(api, 'GET', '/inscricoes/$doHeitor', user: 'p-heitor');
    expect(aindaEspera2.json['status'], 'em_espera');
    final detalhe2 =
        await request(api, 'GET', '/atividades/$atividadeId', user: 'p-carla');
    expect(detalhe2.json['ocupadas'], 1);
    expect(detalhe2.json['emEspera'], 1);
    expect(detalhe2.json['vagasRestantes'], 0);
  });

  test(
      'múltiplas vagas e vencimentos no mesmo instante: cascata em FIFO e contadores consistentes (R43)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    await request(api, 'POST', '/inscricoes/$doDiego/cancelamento',
        user: 'p-diego');

    final esperaAposCancel =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(esperaAposCancel.json['status'], 'convocada');
    final conquistaAposCancel =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(conquistaAposCancel.json['status'], 'convocada',
        reason: 'segunda vaga aberta convoca o próximo em FIFO');

    await relogio(api, '2026-10-14T13:00:00Z');

    final expiradaBatch1 =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(expiradaBatch1.json['status'], 'expirada');
    final expiradaBatch2 =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(expiradaBatch2.json['status'], 'expirada',
        reason: 'vencimentos do mesmo instante (10-14T12) expiram juntos');
    final promovidaBatch =
        await request(api, 'GET', '/inscricoes/$daGabriela', user: 'p-gabriela');
    expect(promovidaBatch.json['status'], 'convocada',
        reason: 'as duas vagas liberadas convocam a primeira da fila');
    expect(promovidaBatch.json['convocadaAte'], '2026-10-15T12:00:00Z',
        reason: 'prazo = vencimento comum (10-14T12)+24h');

    final detalhe = await request(api, 'GET', '/atividades/$atividadeId',
        user: 'p-carla');
    expect(detalhe.json['ocupadas'], 1,
        reason: 'uma vaga segue livre: só uma espera restava na fila');
    expect(detalhe.json['vagasRestantes'], 1);
    expect(detalhe.json['emEspera'], 0);
  });

  test(
      'confirmar expirada por vencimento dá CONVOCACAO_EXPIRADA; expirada por fechamento dá SEM_CONVOCACAO (R31)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    final daGabriela = await inscrever(api, atividadeId, 'p-gabriela');

    await relogio(api, '2026-10-18T00:00:00Z');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    await relogio(api, '2026-10-19T12:00:00Z');

    expect(
        (await request(api, 'GET', '/inscricoes/$daElisa',
                user: 'p-elisa'))
            .json['status'],
        'expirada');

    expect(
        (await request(api, 'GET', '/inscricoes/$doFabio',
                user: 'p-fabio'))
            .json['status'],
        'expirada');
    expect(
        (await request(api, 'GET', '/inscricoes/$daGabriela',
                user: 'p-gabriela'))
            .json['status'],
        'expirada');

    final porVencimento = await request(api, 'POST',
        '/inscricoes/$doFabio/confirmacao',
        user: 'p-fabio');
    expect(porVencimento.status, 422);
    expect(porVencimento.json['erro'], 'CONVOCACAO_EXPIRADA',
        reason: 'fabio convocada com prazo no início expirou por vencimento');

    final porFechamento = await request(api, 'POST',
        '/inscricoes/$daGabriela/confirmacao',
        user: 'p-gabriela');
    expect(porFechamento.status, 422);
    expect(porFechamento.json['erro'], 'SEM_CONVOCACAO',
        reason: 'gabriela em_espera expirou por fechamento, sem convocação a confirmar');

    expect(
        (await request(api, 'POST', '/inscricoes/$doDiego/confirmacao',
                user: 'p-diego'))
            .json['erro'],
        'SEM_CONVOCACAO',
        reason: 'confirmada sem convocação permanece SEM_CONVOCACAO');
  });

  test('reinscrever expirada é como participante novo: novo id no fim da fila (R15)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    await request(api, 'POST', '/inscricoes/$doDiego/cancelamento',
        user: 'p-diego');

    await relogio(api, '2026-10-14T13:00:00Z');
    expect(
        (await request(api, 'GET', '/inscricoes/$daCarla',
                user: 'p-carla'))
            .json['status'],
        'expirada');
    expect(
        (await request(api, 'GET', '/inscricoes/$daElisa',
                user: 'p-elisa'))
            .json['status'],
        'convocada',
        reason: 'elisa promovida no vencimento da carla ocupa a única vaga');

    final nova = await request(api, 'POST',
        '/atividades/$atividadeId/inscricoes',
        user: 'p-carla');
    expect(nova.status, 201);
    expect(nova.json['id'], isNot(daCarla),
        reason: 'nova Inscricao, nunca reconvoca o registro antigo (R15)');
    expect(nova.json['status'], 'em_espera',
        reason: 'vaga ocupada pela convocada, sem privilégio nem punição');
    expect(nova.json['posicaoNaEspera'], 1,
        reason: 'fim da fila como se fosse participante novo');
    expect(
        (await request(api, 'GET', '/inscricoes/$daCarla',
                user: 'p-carla'))
            .json['status'],
        'expirada',
        reason: 'registro antigo permanece expirado');
  });

  test('cancelar expirada antes do início devolve INSCRICAO_INATIVA (R35)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 1);
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    await request(api, 'POST', '/inscricoes/$doDiego/cancelamento',
        user: 'p-diego');

    await relogio(api, '2026-10-14T13:00:00Z');
    expect(
        (await request(api, 'GET', '/inscricoes/$daCarla',
                user: 'p-carla'))
            .json['status'],
        'expirada');

    final cancelar = await request(api, 'POST',
        '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    expect(cancelar.status, 422);
    expect(cancelar.json['erro'], 'INSCRICAO_INATIVA',
        reason: 'expirada não pode ser cancelada (R35)');
    expect(
        (await request(api, 'GET', '/inscricoes/$daCarla',
                user: 'p-carla'))
            .json['status'],
        'expirada');
  });

  test('cancelar a atividade preserva expiradas; ativas viram cancelada (R36)',
      () async {
    final atividadeId = await criarAtividade(api, vagas: 2);
    final daCarla = await inscrever(api, atividadeId, 'p-carla');
    final doDiego = await inscrever(api, atividadeId, 'p-diego');
    final daElisa = await inscrever(api, atividadeId, 'p-elisa');
    final doFabio = await inscrever(api, atividadeId, 'p-fabio');
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');

    await relogio(api, '2026-10-14T13:00:00Z');
    expect(
        (await request(api, 'GET', '/inscricoes/$daElisa',
                user: 'p-elisa'))
            .json['status'],
        'expirada',
        reason: 'elisa venceu em 10-14T12Z');
    expect(
        (await request(api, 'GET', '/inscricoes/$doFabio',
                user: 'p-fabio'))
            .json['status'],
        'convocada',
        reason: 'fabio promovido no vencimento da elisa');

    final cancelada = await request(api, 'POST',
        '/atividades/$atividadeId/cancelamento',
        user: 'org-ana');
    expect(cancelada.status, 200);

    final preservada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(preservada.json['status'], 'expirada',
        reason: 'expirada não mexe no cancelamento da atividade (R36)');

    final virouCancelada =
        await request(api, 'GET', '/inscricoes/$doDiego', user: 'p-diego');
    expect(virouCancelada.json['status'], 'cancelada');
    final convocadaCancelada =
        await request(api, 'GET', '/inscricoes/$doFabio', user: 'p-fabio');
    expect(convocadaCancelada.json['status'], 'cancelada');
    expect(convocadaCancelada.json['convocadaAte'], isNull);
  });
}