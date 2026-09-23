import 'dart:convert';
import 'dart:io';

import 'package:semana_academica_api/server.dart';
import 'package:test/test.dart';

Future<_Response> regressionRequest(ApiServer api, String method, String path,
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

void main() {
  late ApiServer api;
  setUp(() => api = ApiServer(modoTeste: true));

  test('cancelamento valida autenticação, papel e ID inexistente', () async {
    final body = activityBody('Cancelável');
    final created = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana', body: body);
    final id = created.json['id'] as String;

    expect(
        (await regressionRequest(api, 'POST', '/atividades/$id/cancelamento'))
            .json['erro'],
        'USUARIO_DESCONHECIDO');
    expect(
        (await regressionRequest(api, 'POST', '/atividades/$id/cancelamento',
                user: 'p-carla'))
            .json['erro'],
        'SOMENTE_ORGANIZACAO');
    expect(
        (await regressionRequest(
                api, 'POST', '/atividades/atv_inexistente/cancelamento',
                user: 'org-ana'))
            .json['erro'],
        'NAO_ENCONTRADO');
  });

  test('exige usuário em todas as rotas M1 identificadas', () async {
    expect((await regressionRequest(api, 'GET', '/salas')).status, 401);
    expect((await regressionRequest(api, 'GET', '/atividades')).status, 401);
    expect(
        (await regressionRequest(api, 'GET', '/atividades/atv_inexistente'))
            .status,
        401);
    expect(
        (await regressionRequest(api, 'POST', '/atividades', body: {})).status,
        401);

    final created = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Autorização'));
    final id = created.json['id'] as String;
    expect(
        (await regressionRequest(api, 'PATCH', '/atividades/$id', body: {}))
            .status,
        401);
    expect(
        (await regressionRequest(api, 'POST', '/atividades/$id/cancelamento'))
            .status,
        401);
  });

  test('aceita duração mínima e máxima e rejeita vagas inválidas', () async {
    final oneHour = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Uma hora'));
    expect(oneHour.status, 201);
    api.reset();
    final fourHours = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Quatro horas', end: '13:00'));
    expect(fourHours.status, 201);
    api.reset();
    final minicurso = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana',
        body: {
          'titulo': 'Minicurso no limite',
          'tipo': 'minicurso',
          'salaId': 'sala-101',
          'vagas': 10,
          'encontros': [
            meeting('2026-10-19T09:00:00-03:00', '2026-10-19T13:00:00-03:00'),
            meeting('2026-10-20T09:00:00-03:00', '2026-10-20T13:00:00-03:00'),
          ],
        });
    expect(minicurso.status, 201);

    for (final slots in [0, -1, '10']) {
      api.reset();
      final response = await regressionRequest(api, 'POST', '/atividades',
          user: 'org-ana',
          body: {...activityBody('Vagas inválidas'), 'vagas': slots});
      expect(response.status, 422);
      expect(response.json['erro'], 'DADOS_INVALIDOS');
    }
  });

  test('recusa cancelamento exatamente no início do encontro', () async {
    final created = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Começando'));
    final id = created.json['id'] as String;
    await regressionRequest(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-19T09:00:00-03:00'});

    final response = await regressionRequest(
        api, 'POST', '/atividades/$id/cancelamento',
        user: 'org-ana');
    expect(response.status, 422);
    expect(response.json['erro'], 'ATIVIDADE_JA_INICIADA');
  });

  test('PATCH válido retorna explicitamente 200', () async {
    final created = await regressionRequest(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Antes'));
    final id = created.json['id'] as String;
    final response = await regressionRequest(api, 'PATCH', '/atividades/$id',
        user: 'org-ana', body: {'titulo': 'Depois'});
    expect(response.status, 200);
    expect(response.json['titulo'], 'Depois');
  });
}

Map<String, dynamic> activityBody(String title,
        {String start = '09:00', String end = '10:00'}) =>
    {
      'titulo': title,
      'tipo': 'palestra',
      'salaId': 'sala-101',
      'vagas': 10,
      'encontros': [
        {
          'inicio': '2026-10-19T$start:00-03:00',
          'fim': '2026-10-19T$end:00-03:00',
        }
      ],
    };

Map<String, dynamic> meeting(String start, String end) =>
    {'inicio': start, 'fim': end};
