import 'dart:convert';
import 'dart:io';

import 'package:semana_academica_api/server.dart';
import 'package:test/test.dart';

Future<_Response> httpCall(ApiServer api, String method, String path,
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
  return _Response(response.statusCode, text);
}

class _Response {
  _Response(this.status, this.text);
  final int status;
  final String text;
  dynamic get json => text.isEmpty ? null : jsonDecode(text);
}

Future<({String atividade, String encontro})> activity(ApiServer api,
    {int vagas = 3}) async {
  final response =
      await httpCall(api, 'POST', '/atividades', user: 'org-ana', body: {
    'titulo': 'Regressao M3',
    'tipo': 'palestra',
    'salaId': 'sala-101',
    'vagas': vagas,
    'encontros': [
      {
        'inicio': '2026-10-19T09:00:00-03:00',
        'fim': '2026-10-19T10:00:00-03:00'
      }
    ],
  });
  expect(response.status, 201);
  final json = response.json as Map;
  return (
    atividade: json['id'] as String,
    encontro: (json['encontros'] as List).single['id'] as String,
  );
}

Future<void> clock(ApiServer api, String value) async {
  await httpCall(api, 'PUT', '/_teste/relogio', body: {'agora': value});
}

void main() {
  late ApiServer api;
  setUp(() => api = ApiServer(modoTeste: true));

  test('GET M3 rejeita segmentos extras sem processar a rota', () async {
    final ids = await activity(api);
    final code = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo/extra',
        user: 'org-ana');
    final list = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/presencas/extra',
        user: 'org-ana');
    expect(code.status, 404);
    expect(list.status, 404);
  });

  test('fallbacks 404 M3 e rota desconhecida retornam envelope obrigatorio',
      () async {
    final ids = await activity(api);
    final m3Fallbacks = [
      await httpCall(api, 'DELETE', '/encontros/${ids.encontro}/codigo',
          user: 'org-ana'),
      await httpCall(api, 'GET', '/encontros/${ids.encontro}/presencas/manual',
          user: 'org-ana'),
      await httpCall(api, 'GET', '/encontros/${ids.encontro}/codigo/extra',
          user: 'org-ana'),
    ];
    for (final response in m3Fallbacks) {
      expect(response.status, 404);
      expect(response.json,
          {'erro': 'NAO_ENCONTRADO', 'mensagem': 'NAO_ENCONTRADO'});
    }

    final unknown =
        await httpCall(api, 'GET', '/rota-desconhecida', user: 'org-ana');
    expect(unknown.status, 404);
    expect(
        unknown.json, {'erro': 'NAO_ENCONTRADO', 'mensagem': 'NAO_ENCONTRADO'});
  });

  test('lidoEm presente nulo ou nao String retorna DADOS_INVALIDOS', () async {
    final ids = await activity(api);
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    await clock(api, '2026-10-19T08:45:00-03:00');
    final code = await httpCall(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');

    for (final value in [null, 123]) {
      final response = await httpCall(
          api, 'POST', '/encontros/${ids.encontro}/presencas',
          user: 'p-carla',
          body: {'codigo': code.json['codigo'], 'lidoEm': value});
      expect(response.status, 422);
      expect(response.json,
          {'erro': 'DADOS_INVALIDOS', 'mensagem': 'DADOS_INVALIDOS'});
    }
  });

  test('rotas M3 aplicam autenticacao e papel em todos os endpoints', () async {
    final ids = await activity(api);
    final routes = [
      ['GET', '/encontros/${ids.encontro}/codigo'],
      ['POST', '/encontros/${ids.encontro}/presencas'],
      ['POST', '/encontros/${ids.encontro}/presencas/manual'],
      ['GET', '/encontros/${ids.encontro}/presencas'],
    ];
    for (final route in routes) {
      final missing = await httpCall(api, route[0], route[1]);
      expect(missing.status, 401);
      expect(missing.json['erro'], 'USUARIO_DESCONHECIDO');
    }
    final organizationOnly = [routes[0], routes[2], routes[3]];
    for (final route in organizationOnly) {
      final forbidden = await httpCall(api, route[0], route[1],
          user: 'p-carla', body: route[0] == 'POST' ? {} : null);
      expect(forbidden.status, 403);
      expect(forbidden.json['erro'], 'SOMENTE_ORGANIZACAO');
    }
    final participantOnly =
        await httpCall(api, 'POST', routes[1][1], user: 'org-ana', body: {});
    expect(participantOnly.status, 403);
    expect(participantOnly.json['erro'], 'SOMENTE_PARTICIPANTE');
  });

  test('codigo antigo falha para registro QR ainda nao duplicado', () async {
    final ids = await activity(api);
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    await clock(api, '2026-10-19T08:45:00-03:00');
    final first = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    await clock(api, '2026-10-19T08:50:00-03:00');
    final result = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla',
        body: {
          'codigo': first.json['codigo'],
        });
    expect(result.status, 422);
    expect(result.json['erro'], 'CODIGO_INVALIDO');
  });

  test('presenca QR aceita limites inclusivos e rejeita leitura passada tardia',
      () async {
    final ids = await activity(api, vagas: 3);
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-diego');
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-elisa');
    await clock(api, '2026-10-19T08:45:00-03:00');
    final startCode = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final start = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla',
        body: {
          'codigo': startCode.json['codigo'],
        });
    expect(start.status, 201);
    await clock(api, '2026-10-19T10:15:00-03:00');
    final endCode = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final end = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-diego',
        body: {
          'codigo': endCode.json['codigo'],
        });
    expect(end.status, 201);
    await clock(api, '2026-10-19T08:55:00-03:00');
    final late = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-elisa',
        body: {
          'codigo': startCode.json['codigo'],
          'lidoEm': '2026-10-19T08:44:59-03:00',
        });
    expect(late.status, 422);
    expect(late.json['erro'], 'SINCRONIZACAO_TARDIA');
  });

  test(
      'QR recusa inscricao nao confirmada e manual recusa participante inexistente',
      () async {
    final ids = await activity(api, vagas: 1);
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-diego');
    await clock(api, '2026-10-19T08:45:00-03:00');
    final code = await httpCall(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final waiting = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-diego',
        body: {
          'codigo': code.json['codigo'],
        });
    final unknown = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-nao-existe',
          'justificativa': 'Participacao autorizada',
        });
    expect(waiting.status, 403);
    expect(waiting.json['erro'], 'NAO_INSCRITO');
    expect(unknown.status, 403);
    expect(unknown.json['erro'], 'NAO_INSCRITO');
  });

  test('manual valida branco, limite de 500 caracteres, janela e timestamps',
      () async {
    final ids = await activity(api, vagas: 3);
    for (final person in ['p-carla', 'p-diego', 'p-elisa']) {
      await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
          user: person);
    }
    await clock(api, '2026-10-19T08:45:00-03:00');
    Future<_Response> manual(String person, String justification) =>
        httpCall(api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
            user: 'org-ana',
            body: {
              'participanteId': person,
              'justificativa': justification,
            });
    expect((await manual('p-carla', ' ')).json['erro'],
        'JUSTIFICATIVA_OBRIGATORIA');
    final accepted = await manual('p-diego', 'a' * 500);
    expect(accepted.status, 201);
    expect(accepted.json['lidoEm'], '2026-10-19T11:45:00Z');
    expect(accepted.json['registradaEm'], '2026-10-19T11:45:00Z');
    expect((await manual('p-elisa', 'a' * 501)).json['erro'],
        'JUSTIFICATIVA_OBRIGATORIA');
    await clock(api, '2026-10-19T08:44:59-03:00');
    final outside = await manual('p-elisa', 'Participacao fora da janela');
    expect(outside.status, 422);
    expect(outside.json['erro'], 'FORA_DA_JANELA');
  });

  test('listagem ordena multiplas presencas, nao muta e reset isola estado',
      () async {
    final ids = await activity(api, vagas: 2);
    for (final person in ['p-carla', 'p-diego']) {
      await httpCall(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
          user: person);
    }
    await clock(api, '2026-10-19T08:45:00-03:00');
    final code = await httpCall(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final first = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla',
        body: {
          'codigo': code.json['codigo'],
        });
    await clock(api, '2026-10-19T08:50:00-03:00');
    final secondCode = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final second = await httpCall(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-diego',
        body: {
          'codigo': secondCode.json['codigo'],
        });
    final listed = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/presencas',
        user: 'org-ana');
    final again = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/presencas',
        user: 'org-ana');
    expect((listed.json as List).map((item) => item['id']),
        [first.json['id'], second.json['id']]);
    expect(again.json, listed.json);
    await httpCall(api, 'POST', '/_teste/reset');
    expect(
        (await httpCall(api, 'GET', '/encontros/${ids.encontro}/presencas',
                user: 'org-ana'))
            .status,
        404);
  });

  test('retrocesso preserva transicao de bucket ja materializada', () async {
    final ids = await activity(api);
    await clock(api, '2026-10-19T08:45:00-03:00');
    final first = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    await clock(api, '2026-10-19T08:50:00-03:00');
    final second = await httpCall(
        api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    await clock(api, '2026-10-19T08:45:00-03:00');
    final back = await httpCall(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    expect(second.json['codigo'], isNot(first.json['codigo']));
    expect(back.json['codigo'], first.json['codigo']);
  });

  test('reset em modo de teste nao toca o arquivo de producao', () async {
    final directory = Directory('.dart_tool').createTempSync('m3_isolamento_');
    final stateFile = '${directory.path}${Platform.pathSeparator}estado.json';
    final before = '{"producao":"intacta"}';
    File(stateFile).writeAsStringSync(before);
    try {
      final isolated = ApiServer(modoTeste: true, stateFile: stateFile);
      await httpCall(isolated, 'POST', '/_teste/reset');
      expect(File(stateFile).readAsStringSync(), before);
    } finally {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    }
  });
}
