import 'dart:convert';
import 'dart:io';

import 'package:semana_academica_api/server.dart';
import 'package:test/test.dart';

Future<_Response> call(ApiServer api, String method, String path,
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

Future<({String atividade, String encontro})> createActivity(
    ApiServer api) async {
  final response =
      await call(api, 'POST', '/atividades', user: 'org-ana', body: {
    'titulo': 'Presenca por QR',
    'tipo': 'palestra',
    'salaId': 'sala-101',
    'vagas': 2,
    'encontros': [
      {
        'inicio': '2026-10-19T09:00:00-03:00',
        'fim': '2026-10-19T10:00:00-03:00',
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

void main() {
  late ApiServer api;

  setUp(() => api = ApiServer(modoTeste: true));

  test('obtem codigo deterministico por encontro dentro da janela inclusiva',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });

    final first = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final second = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');

    expect(first.status, 200);
    expect(first.json['encontroId'], ids.encontro);
    expect(first.json['codigo'], matches(RegExp(r'^[A-Z0-9]{6}$')));
    expect(first.json['trocaEm'], '2026-10-19T11:50:00Z');
    expect(first.json['validoAte'], '2026-10-19T11:50:00Z');
    expect(second.json['codigo'], first.json['codigo']);
  });

  test('troca codigo no limite de cinco minutos e recusa fora da janela',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:50:00-03:00',
    });
    final rotated = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    expect(rotated.status, 200);
    expect(rotated.json['trocaEm'], '2026-10-19T11:55:00Z');

    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:44:59-03:00',
    });
    final before = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    expect(before.json['erro'], 'FORA_DA_JANELA');

    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T10:15:01-03:00',
    });
    final after = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    expect(after.json['erro'], 'FORA_DA_JANELA');
  });

  test('presenca QR exige confirmacao e e idempotente', () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final semInscricao = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': code.json['codigo']});
    expect(semInscricao.status, 403);
    expect(semInscricao.json['erro'], 'NAO_INSCRITO');

    final inscription = await call(
        api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    expect(inscription.status, 201);
    final first = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': code.json['codigo']});
    final second = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': 'INVALIDO'});
    expect(first.status, 201);
    expect(first.json['origem'], 'qr');
    expect(second.status, 200);
    expect(second.json, first.json);
  });

  test('leitura offline aceita tolerancia de dez minutos e rejeita futuro',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-diego');
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:55:00-03:00',
    });
    final offline = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla',
        body: {
          'codigo': code.json['codigo'],
          'lidoEm': '2026-10-19T08:45:00-03:00',
        });
    expect(offline.status, 201);
    expect(offline.json['origem'], 'qr_offline');

    final future = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-diego',
        body: {
          'codigo': code.json['codigo'],
          'lidoEm': '2026-10-19T09:00:01-03:00',
        });
    expect(future.status, 422);
    expect(future.json['erro'], 'SINCRONIZACAO_TARDIA');
  });

  test('presenca manual valida justificativa, janela e duplicidade global',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    final curta = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {'participanteId': 'p-carla', 'justificativa': 'curta'});
    expect(curta.status, 422);
    expect(curta.json['erro'], 'JUSTIFICATIVA_OBRIGATORIA');

    final first = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-carla',
          'justificativa': 'Participacao confirmada',
        });
    final duplicate = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-bruno',
        body: {
          'participanteId': 'p-carla',
          'justificativa': 'Outra justificativa diferente',
        });
    expect(first.status, 201);
    expect(first.json['origem'], 'manual');
    expect(first.json['justificativa'], 'Participacao confirmada');
    expect(duplicate.status, 200);
    expect(duplicate.json, first.json);
  });

  test('atividade cancelada impede codigo e presenca manual', () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    await call(api, 'POST', '/atividades/${ids.atividade}/cancelamento',
        user: 'org-ana', body: {});
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    expect(code.status, 422);
    expect(code.json['erro'], 'ATIVIDADE_CANCELADA');
  });

  test('atividade cancelada precede duplicidade em QR e manual', () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final first = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': code.json['codigo']});
    expect(first.status, 201);
    final manual = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-carla',
          'justificativa': 'Tentativa manual posterior',
        });
    expect(manual.status, 200);

    await call(api, 'POST', '/atividades/${ids.atividade}/cancelamento',
        user: 'org-ana', body: {});
    final repeatedQr = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': 'INVALIDO'});
    final repeatedManual = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-carla',
          'justificativa': 'Outra justificativa valida',
        });
    expect(repeatedQr.json['erro'], 'ATIVIDADE_CANCELADA');
    expect(repeatedManual.json['erro'], 'ATIVIDADE_CANCELADA');
  });

  test('corpo manual sem justificativa retorna JUSTIFICATIVA_OBRIGATORIA',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    final missing = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana', body: {'participanteId': 'p-carla'});
    expect(missing.status, 422);
    expect(missing.json['erro'], 'JUSTIFICATIVA_OBRIGATORIA');
    final wrongType = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {'participanteId': 'p-carla', 'justificativa': 10});
    expect(wrongType.status, 422);
    expect(wrongType.json['erro'], 'DADOS_INVALIDOS');
  });

  test(
      'rotas M3 rejeitam corpos malformados, timestamps e codigo fora da regra',
      () async {
    final ids = await createActivity(api);
    final malformed = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: '[');
    expect(malformed.status, 422);
    expect(malformed.json['erro'], 'DADOS_INVALIDOS');

    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    final invalidTimestamp = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla',
        body: {'codigo': code.json['codigo'], 'lidoEm': 'not-a-date'});
    expect(invalidTimestamp.json['erro'], 'DADOS_INVALIDOS');

    final oldCode = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla',
        body: {
          'codigo': code.json['codigo'],
          'lidoEm': '2026-10-19T09:00:01-03:00',
        });
    expect(oldCode.json['erro'], 'SINCRONIZACAO_TARDIA');

    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T10:15:01-03:00',
    });
    final outside = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': code.json['codigo']});
    expect(outside.json['erro'], 'FORA_DA_JANELA');
  });

  test('limite manual e por participante e duplicidade compartilhada',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    for (final participant in ['p-carla', 'p-diego']) {
      await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
          user: participant);
    }
    final carla = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-carla',
          'justificativa': 'Registro de Carla',
        });
    final carlaAgain = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-bruno',
        body: {
          'participanteId': 'p-carla',
          'justificativa': 'Registro duplicado de Carla',
        });
    final diego = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-diego',
          'justificativa': 'Registro de Diego',
        });
    expect(carla.status, 201);
    expect(carlaAgain.status, 200);
    expect(carlaAgain.json, carla.json);
    expect(diego.status, 201);
    expect(diego.json['participanteId'], 'p-diego');
    expect(diego.json['erro'], isNull);
  });

  test('retroceder o relogio nao desfaz presenca ja materializada', () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    final created = await call(
        api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': code.json['codigo']});
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:44:00-03:00',
    });
    final listed = await call(
        api, 'GET', '/encontros/${ids.encontro}/presencas',
        user: 'org-ana');
    expect(listed.status, 200);
    expect((listed.json as List).single['id'], created.json['id']);
  });

  test('aplica autenticacao, papel e existencia antes das regras M3', () async {
    final semUsuario =
        await call(api, 'GET', '/encontros/enc_inexistente/codigo');
    expect(semUsuario.status, 401);
    expect(semUsuario.json['erro'], 'USUARIO_DESCONHECIDO');
    final papel = await call(api, 'GET', '/encontros/enc_inexistente/codigo',
        user: 'p-carla');
    expect(papel.status, 403);
    expect(papel.json['erro'], 'SOMENTE_ORGANIZACAO');
    final inexistente = await call(
        api, 'GET', '/encontros/enc_inexistente/codigo',
        user: 'org-ana');
    expect(inexistente.status, 404);
    expect(inexistente.json['erro'], 'NAO_ENCONTRADO');
  });

  test('lista presencas por encontro em ordem de registro e reset limpa tudo',
      () async {
    final ids = await createActivity(api);
    await call(api, 'PUT', '/_teste/relogio', body: {
      'agora': '2026-10-19T08:45:00-03:00',
    });
    await call(api, 'POST', '/atividades/${ids.atividade}/inscricoes',
        user: 'p-carla');
    final code = await call(api, 'GET', '/encontros/${ids.encontro}/codigo',
        user: 'org-ana');
    await call(api, 'POST', '/encontros/${ids.encontro}/presencas',
        user: 'p-carla', body: {'codigo': code.json['codigo']});
    final listed = await call(
        api, 'GET', '/encontros/${ids.encontro}/presencas',
        user: 'org-ana');
    expect(listed.status, 200);
    expect((listed.json as List).single['participanteId'], 'p-carla');
    await call(api, 'POST', '/_teste/reset');
    final afterReset = await call(
        api, 'GET', '/encontros/${ids.encontro}/presencas',
        user: 'org-ana');
    expect(afterReset.status, 404);
    final clock = await call(api, 'GET', '/_teste/relogio');
    expect(clock.json['agora'], '2026-10-13T12:00:00Z');
  });

  test('presenca persiste no arquivo e sobrevive a reinicio', () async {
    final directory = Directory('.dart_tool').createTempSync('m3_');
    final stateFile = '${directory.path}${Platform.pathSeparator}estado.json';
    var now = DateTime.utc(2026, 10, 19, 11, 45);
    ApiServer production() => ApiServer(
          modoTeste: false,
          stateFile: stateFile,
          clockProvider: () => now,
        );
    try {
      final firstApi = production();
      final ids = await createActivity(firstApi);
      await call(firstApi, 'POST', '/atividades/${ids.atividade}/inscricoes',
          user: 'p-carla');
      final code = await call(
          firstApi, 'GET', '/encontros/${ids.encontro}/codigo',
          user: 'org-ana');
      final created = await call(
          firstApi, 'POST', '/encontros/${ids.encontro}/presencas',
          user: 'p-carla', body: {'codigo': code.json['codigo']});
      expect(created.status, 201);
      now = DateTime.utc(2026, 10, 19, 11, 46);
      final secondApi = production();
      final listed = await call(
          secondApi, 'GET', '/encontros/${ids.encontro}/presencas',
          user: 'org-ana');
      expect(listed.status, 200);
      expect((listed.json as List).single['id'], created.json['id']);
    } finally {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    }
  });
}
