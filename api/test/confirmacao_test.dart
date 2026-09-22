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
    {String titulo = 'Alvo',
    String tipo = 'palestra',
    String salaId = 'sala-101',
    int vagas = 5,
    List<(String, String)>? encontros}) async {
  final lista = encontros ??
      [('2026-10-19T09:00:00-03:00', '2026-10-19T10:00:00-03:00')];
  final criada = await request(api, 'POST', '/atividades',
      user: 'org-ana',
      body: {
        'titulo': titulo,
        'tipo': tipo,
        'salaId': salaId,
        'vagas': vagas,
        'encontros': [
          for (final (inicio, fim) in lista)
            {'inicio': inicio, 'fim': fim}
        ]
      });
  return criada.json['id'] as String;
}

Future<HttpResponse> inscrever(
    ApiServer api, String atividadeId, String user) {
  return request(api, 'POST', '/atividades/$atividadeId/inscricoes',
      user: user);
}

void main() {
  late ApiServer api;
  setUp(() => api = ApiServer(modoTeste: true));

  test(
      'confirmar sem convocação ativa devolve SEM_CONVOCACAO para confirmada, em_espera e cancelada (R31, R32)',
      () async {
    final a1 = await criarAtividade(api);
    final daCarla = (await inscrever(api, a1, 'p-carla')).json['id'] as String;
    final repetidaConvocacao = await request(api, 'POST',
        '/inscricoes/$daCarla/confirmacao',
        user: 'p-carla');
    expect(repetidaConvocacao.status, 422, reason: 'repetição depois de confirmar');
    expect(repetidaConvocacao.json['erro'], 'SEM_CONVOCACAO');

    final a2 = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T11:00:00-03:00', '2026-10-19T12:00:00-03:00')
        ],
        vagas: 1);
    await inscrever(api, a2, 'p-diego');
    final daEspera = (await inscrever(api, a2, 'p-carla')).json['id'] as String;
    expect(
        (await request(api, 'GET', '/inscricoes/$daEspera',
                user: 'p-carla'))
            .json['status'],
        'em_espera');
    final emEspera = await request(api, 'POST',
        '/inscricoes/$daEspera/confirmacao',
        user: 'p-carla');
    expect(emEspera.status, 422);
    expect(emEspera.json['erro'], 'SEM_CONVOCACAO');

    final a3 = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T13:00:00-03:00', '2026-10-19T14:00:00-03:00')
        ]);
    final daCancelada = (await inscrever(api, a3, 'p-carla')).json['id'] as String;
    await request(api, 'POST', '/inscricoes/$daCancelada/cancelamento',
        user: 'p-carla');
    final cancelada = await request(api, 'POST',
        '/inscricoes/$daCancelada/confirmacao',
        user: 'p-carla');
    expect(cancelada.status, 422);
    expect(cancelada.json['erro'], 'SEM_CONVOCACAO');
  });

  test(
      'confirmar convocada antes do prazo: 200 confirmada, mesma id, posição e prazo nulos e ocupação preservada (R21, R22)',
      () async {
    final id = await criarAtividade(api, vagas: 1);
    final daCarla = (await inscrever(api, id, 'p-carla')).json['id'] as String;
    final daElisa = (await inscrever(api, id, 'p-elisa')).json['id'] as String;
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    final convocadaTela =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(convocadaTela.json['status'], 'convocada');
    expect(convocadaTela.json['convocadaAte'], '2026-10-14T12:00:00Z');

    final confirmada = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa');
    expect(confirmada.status, 200);
    expect(confirmada.json['id'], daElisa, reason: 'mesma inscrição');
    expect(confirmada.json['status'], 'confirmada');
    expect(confirmada.json['posicaoNaEspera'], isNull);
    expect(confirmada.json['convocadaAte'], isNull);

    final consultada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(consultada.json['status'], 'confirmada',
        reason: 'mutação é observável na leitura');
    final detalhe = await request(api, 'GET', '/atividades/$id',
        user: 'p-carla');
    expect(detalhe.json['ocupadas'], 1,
        reason: 'convocada já ocupava a vaga e confirmada a mantém');
    expect(detalhe.json['vagasRestantes'], 0);
    expect(detalhe.json['emEspera'], 0);
  });

  test(
      'confirmar convocada com agora == convocadaAte devolve CONVOCACAO_EXPIRADA (R22, R31)',
      () async {
    final id = await criarAtividade(api, vagas: 1);
    final daCarla = (await inscrever(api, id, 'p-carla')).json['id'] as String;
    final daElisa = (await inscrever(api, id, 'p-elisa')).json['id'] as String;
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    expect(
        (await request(api, 'GET', '/inscricoes/$daElisa',
                user: 'p-elisa'))
            .json['status'],
        'convocada');

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-14T12:00:00Z'});
    final exato = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa');
    expect(exato.status, 422, reason: 'borda inclusiva do vencimento');
    expect(exato.json['erro'], 'CONVOCACAO_EXPIRADA');

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-14T12:00:01Z'});
    final vencida = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa');
    expect(vencida.status, 422);
    expect(vencida.json['erro'], 'CONVOCACAO_EXPIRADA',
        reason: 'vencida pelo relógio precede SEM_CONVOCACAO');
  });

  test(
      'inscrever recusa sobreposição em [inicio,fim) de qualquer encontro, independente da sala; fim==inicio é permitido (R28, R29)',
      () async {
    final mini = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T09:00:00-03:00', '2026-10-19T11:00:00-03:00'),
          ('2026-10-20T09:00:00-03:00', '2026-10-20T11:00:00-03:00')
        ]);
    await inscrever(api, mini, 'p-carla');

    final sobreposto = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-20T10:00:00-03:00', '2026-10-20T12:00:00-03:00')
        ]);
    final conflito = await request(api, 'POST',
        '/atividades/$sobreposto/inscricoes',
        user: 'p-carla');
    expect(conflito.status, 409, reason: 'sobrepõe o segundo encontro, outra sala');
    expect(conflito.json['erro'], 'CONFLITO_DE_HORARIO');

    final contigua = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T11:00:00-03:00', '2026-10-19T12:00:00-03:00')
        ]);
    final permitida = await request(api, 'POST',
        '/atividades/$contigua/inscricoes',
        user: 'p-carla');
    expect(permitida.status, 201,
        reason: 'fim 10h e começar 10h é permitido (início incluso, fim excluso)');
    expect(permitida.json['status'], 'confirmada');
  });

  test('conflito considera apenas as confirmadas do participante: em_espera não bloqueia (R28)',
      () async {
    final base = await criarAtividade(api);
    await inscrever(api, base, 'p-carla');

    final cheia = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T11:00:00-03:00', '2026-10-19T12:00:00-03:00')
        ],
        vagas: 1);
    await inscrever(api, cheia, 'p-diego');
    await inscrever(api, cheia, 'p-carla');

    final sobreposta = await criarAtividade(api,
        encontros: [
          ('2026-10-19T11:30:00-03:00', '2026-10-19T12:30:00-03:00')
        ]);
    final nova = await request(api, 'POST',
        '/atividades/$sobreposta/inscricoes',
        user: 'p-carla');
    expect(nova.status, 201,
        reason: 'em_espera da própria participante não gera conflito');
    expect(nova.json['status'], 'confirmada');
  });

  test(
      'confirmar com conflito preserva convocação, prazo e vaga; cancelando o conflito, confirma com sucesso (R20, R28, R29)',
      () async {
    final a = await criarAtividade(api, vagas: 1);
    final b = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T09:30:00-03:00', '2026-10-19T10:30:00-03:00')
        ]);
    final daCarla = (await inscrever(api, a, 'p-carla')).json['id'] as String;
    final daElisa = (await inscrever(api, a, 'p-elisa')).json['id'] as String;
    final daElisaB = (await inscrever(api, b, 'p-elisa')).json['id'] as String;
    await request(api, 'POST', '/inscricoes/$daCarla/cancelamento',
        user: 'p-carla');
    expect(
        (await request(api, 'GET', '/inscricoes/$daElisa',
                user: 'p-elisa'))
            .json['status'],
        'convocada');

    final falha = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa');
    expect(falha.status, 409);
    expect(falha.json['erro'], 'CONFLITO_DE_HORARIO');

    final preservada =
        await request(api, 'GET', '/inscricoes/$daElisa', user: 'p-elisa');
    expect(preservada.json['status'], 'convocada',
        reason: 'falha não muda o status');
    expect(preservada.json['convocadaAte'], '2026-10-14T12:00:00Z',
        reason: 'prazo preservado até convocadaAte');
    expect(
        (await request(api, 'GET', '/atividades/$a', user: 'p-elisa'))
            .json['ocupadas'],
        1,
        reason: 'convocações falhas não abrem a vaga para o próximo');

    await request(api, 'POST', '/inscricoes/$daElisaB/cancelamento',
        user: 'p-elisa');
    final confirmada = await request(api, 'POST',
        '/inscricoes/$daElisa/confirmacao',
        user: 'p-elisa');
    expect(confirmada.status, 200, reason: 'cancelado o conflito, confirma');
    expect(confirmada.json['status'], 'confirmada');
    expect(confirmada.json['convocadaAte'], isNull);
  });

  test(
      'terceiro minicurso confirmado devolve LIMITE_DE_MINICURSOS ao inscrever, mesmo quando a vaga seria em_espera (R30)',
      () async {
    final m1 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T09:00:00-03:00', '2026-10-19T11:00:00-03:00'),
          ('2026-10-21T09:00:00-03:00', '2026-10-21T11:00:00-03:00')
        ]);
    await inscrever(api, m1, 'p-carla');
    final m2 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T14:00:00-03:00', '2026-10-19T16:00:00-03:00'),
          ('2026-10-22T09:00:00-03:00', '2026-10-22T11:00:00-03:00')
        ]);
    await inscrever(api, m2, 'p-carla');

    final m3 = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        vagas: 1,
        encontros: [
          ('2026-10-20T09:00:00-03:00', '2026-10-20T11:00:00-03:00'),
          ('2026-10-20T14:00:00-03:00', '2026-10-20T16:00:00-03:00')
        ]);
    await inscrever(api, m3, 'p-diego');
    final recusada = await request(api, 'POST',
        '/atividades/$m3/inscricoes',
        user: 'p-carla');
    expect(recusada.status, 422);
    expect(recusada.json['erro'], 'LIMITE_DE_MINICURSOS',
        reason: 'm3 lotada: carla entraria em espera, mas o limite recusa');
    final minhas =
        (await request(api, 'GET', '/inscricoes', user: 'p-carla')).json
            as List;
    expect(minhas, hasLength(2), reason: 'recusa não cria inscrição');
  });

  test(
      'espera, cancelada e convocada não contam no limite; palestras nunca contam (R30)',
      () async {
    final m1 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T09:00:00-03:00', '2026-10-19T11:00:00-03:00'),
          ('2026-10-21T09:00:00-03:00', '2026-10-21T11:00:00-03:00')
        ]);
    await inscrever(api, m1, 'p-carla');

    final emEspera = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        vagas: 1,
        encontros: [
          ('2026-10-20T09:00:00-03:00', '2026-10-20T11:00:00-03:00'),
          ('2026-10-20T14:00:00-03:00', '2026-10-20T16:00:00-03:00')
        ]);
    await inscrever(api, emEspera, 'p-diego');
    await inscrever(api, emEspera, 'p-carla');

    final cancelavel = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        encontros: [
          ('2026-10-22T09:00:00-03:00', '2026-10-22T11:00:00-03:00'),
          ('2026-10-22T14:00:00-03:00', '2026-10-22T16:00:00-03:00')
        ]);
    final daCanc = (await inscrever(api, cancelavel, 'p-carla')).json['id'] as String;
    await request(api, 'POST', '/inscricoes/$daCanc/cancelamento',
        user: 'p-carla');

    final convocadaAtv = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        vagas: 1,
        encontros: [
          ('2026-10-23T09:00:00-03:00', '2026-10-23T11:00:00-03:00'),
          ('2026-10-23T14:00:00-03:00', '2026-10-23T16:00:00-03:00')
        ]);
    await inscrever(api, convocadaAtv, 'p-heitor');
    final daConvocada = (await inscrever(api, convocadaAtv, 'p-carla')).json['id'] as String;
    expect(
        (await request(api, 'PATCH', '/atividades/$convocadaAtv',
                user: 'org-ana', body: {'vagas': 2}))
            .json['vagas'],
        2);
    expect(
        (await request(api, 'GET', '/inscricoes/$daConvocada',
                user: 'p-carla'))
            .json['status'],
        'convocada');

    final palestra1 = await criarAtividade(api,
        encontros: [
          ('2026-10-19T16:00:00-03:00', '2026-10-19T17:00:00-03:00')
        ]);
    await inscrever(api, palestra1, 'p-carla');
    final palestra2 = await criarAtividade(api,
        encontros: [
          ('2026-10-21T16:00:00-03:00', '2026-10-21T17:00:00-03:00')
        ]);
    await inscrever(api, palestra2, 'p-carla');

    final novoMini = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T11:00:00-03:00', '2026-10-19T13:00:00-03:00'),
          ('2026-10-21T11:00:00-03:00', '2026-10-21T13:00:00-03:00')
        ]);
    final permitido = await request(api, 'POST',
        '/atividades/$novoMini/inscricoes',
        user: 'p-carla');
    expect(permitido.status, 201,
        reason: 'só confirmadas contam; espera/cancelada/convocada/palestras não');
    expect(permitido.json['status'], 'confirmada');
  });

  test(
      'confirmar convocada que estouraria o limite devolve LIMITE_DE_MINICURSOS (R30, R31)',
      () async {
    final m1 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T09:00:00-03:00', '2026-10-19T11:00:00-03:00'),
          ('2026-10-19T14:00:00-03:00', '2026-10-19T16:00:00-03:00')
        ]);
    await inscrever(api, m1, 'p-carla');

    final x = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        vagas: 1,
        encontros: [
          ('2026-10-20T09:00:00-03:00', '2026-10-20T11:00:00-03:00'),
          ('2026-10-20T14:00:00-03:00', '2026-10-20T16:00:00-03:00')
        ]);
    await inscrever(api, x, 'p-diego');
    final daX = (await inscrever(api, x, 'p-carla')).json['id'] as String;

    final m2 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-21T09:00:00-03:00', '2026-10-21T11:00:00-03:00'),
          ('2026-10-21T14:00:00-03:00', '2026-10-21T16:00:00-03:00')
        ]);
    await inscrever(api, m2, 'p-carla');

    expect(
        (await request(api, 'PATCH', '/atividades/$x', user: 'org-ana',
                body: {'vagas': 2}))
            .json['vagas'],
        2);

    final recusada = await request(api, 'POST',
        '/inscricoes/$daX/confirmacao',
        user: 'p-carla');
    expect(recusada.status, 422);
    expect(recusada.json['erro'], 'LIMITE_DE_MINICURSOS',
        reason: 'confirmar tornaria 3 minicursos confirmados');
    final preservada =
        await request(api, 'GET', '/inscricoes/$daX', user: 'p-carla');
    expect(preservada.json['status'], 'convocada',
        reason: 'falha não desfaz a convocação');
    expect(preservada.json['convocadaAte'], '2026-10-14T12:00:00Z');
  });

  test('confirmação aplica CONFLITO_DE_HORARIO antes de LIMITE_DE_MINICURSOS (R31)',
      () async {
    final m1 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T09:00:00-03:00', '2026-10-19T11:00:00-03:00'),
          ('2026-10-22T09:00:00-03:00', '2026-10-22T11:00:00-03:00')
        ]);
    await inscrever(api, m1, 'p-carla');

    final x = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'sala-102',
        vagas: 1,
        encontros: [
          ('2026-10-21T09:00:00-03:00', '2026-10-21T11:00:00-03:00'),
          ('2026-10-21T14:00:00-03:00', '2026-10-21T16:00:00-03:00')
        ]);
    await inscrever(api, x, 'p-diego');
    final daX = (await inscrever(api, x, 'p-carla')).json['id'] as String;

    final m2 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-20T09:00:00-03:00', '2026-10-20T11:00:00-03:00'),
          ('2026-10-23T09:00:00-03:00', '2026-10-23T11:00:00-03:00')
        ]);
    await inscrever(api, m2, 'p-carla');

    final conflitante = await criarAtividade(api,
        encontros: [
          ('2026-10-21T10:00:00-03:00', '2026-10-21T12:00:00-03:00')
        ]);
    await inscrever(api, conflitante, 'p-carla');

    expect(
        (await request(api, 'PATCH', '/atividades/$x', user: 'org-ana',
                body: {'vagas': 2}))
            .json['vagas'],
        2);

    final resposta = await request(api, 'POST',
        '/inscricoes/$daX/confirmacao',
        user: 'p-carla');
    expect(resposta.status, 409, reason: 'conflito vem antes do limite');
    expect(resposta.json['erro'], 'CONFLITO_DE_HORARIO');
  });

  test('inscrever: JA_INSCRITO vence conflito e CONFLITO_DE_HORARIO vence LIMITE_DE_MINICURSOS (R12)',
      () async {
    final a = await criarAtividade(api,
        tipo: 'minicurso',
        vagas: 1,
        encontros: [
          ('2026-10-19T09:00:00-03:00', '2026-10-19T11:00:00-03:00'),
          ('2026-10-21T09:00:00-03:00', '2026-10-21T11:00:00-03:00')
        ]);
    await inscrever(api, a, 'p-diego');
    await inscrever(api, a, 'p-carla');

    final b = await criarAtividade(api,
        salaId: 'sala-102',
        encontros: [
          ('2026-10-19T10:00:00-03:00', '2026-10-19T12:00:00-03:00')
        ]);
    await inscrever(api, b, 'p-carla');

    final repetida = await request(api, 'POST',
        '/atividades/$a/inscricoes',
        user: 'p-carla');
    expect(repetida.status, 409);
    expect(repetida.json['erro'], 'JA_INSCRITO',
        reason: 'duplicidade vem antes do conflito de horário');

    final m1 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-19T16:00:00-03:00', '2026-10-19T18:00:00-03:00'),
          ('2026-10-21T16:00:00-03:00', '2026-10-21T18:00:00-03:00')
        ]);
    await inscrever(api, m1, 'p-carla');
    final m2 = await criarAtividade(api,
        tipo: 'minicurso',
        encontros: [
          ('2026-10-20T09:00:00-03:00', '2026-10-20T11:00:00-03:00'),
          ('2026-10-23T09:00:00-03:00', '2026-10-23T11:00:00-03:00')
        ]);
    await inscrever(api, m2, 'p-carla');

    final c = await criarAtividade(api,
        tipo: 'minicurso',
        salaId: 'lab-3',
        encontros: [
          ('2026-10-19T11:00:00-03:00', '2026-10-19T13:00:00-03:00'),
          ('2026-10-21T11:00:00-03:00', '2026-10-21T13:00:00-03:00')
        ]);
    final terceiro = await request(api, 'POST',
        '/atividades/$c/inscricoes',
        user: 'p-carla');
    expect(terceiro.status, 409, reason: 'conflito vem antes do limite');
    expect(terceiro.json['erro'], 'CONFLITO_DE_HORARIO');
  });
}