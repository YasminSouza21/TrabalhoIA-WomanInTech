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
}