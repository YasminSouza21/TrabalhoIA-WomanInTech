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

  test('começa vazio e expõe salas a qualquer usuário identificado', () async {
    expect((await request(api, 'GET', '/atividades', user: 'p-carla')).json,
        isEmpty);
    final rooms =
        (await request(api, 'GET', '/salas', user: 'p-carla')).json as List;
    expect(rooms.map((room) => room['id']),
        containsAll(['auditorio', 'sala-101', 'sala-102', 'lab-3']));
  });

  test('aplica autenticação e permissão antes do corpo', () async {
    expect((await request(api, 'POST', '/atividades', body: 'nao-json')).status,
        401);
    expect(
        (await request(api, 'POST', '/atividades', user: 'p-carla', body: {}))
            .json['erro'],
        'SOMENTE_ORGANIZACAO');
  });

  test('cria palestra e minicurso, calcula carga e ordena encontros', () async {
    final body = {
      'titulo': 'Mini',
      'tipo': 'minicurso',
      'salaId': 'lab-3',
      'vagas': 10,
      'cargaHorariaMinutos': 1,
      'encontros': [
        {
          'inicio': '2026-10-20T09:00:00-03:00',
          'fim': '2026-10-20T10:00:00-03:00'
        },
        {
          'inicio': '2026-10-19T09:00:00-03:00',
          'fim': '2026-10-19T11:00:00-03:00'
        },
      ]
    };
    final response =
        await request(api, 'POST', '/atividades', user: 'org-ana', body: body);
    expect(response.status, 201);
    expect(response.json['cargaHorariaMinutos'], 180);
    expect(response.json['encontros'][0]['inicio'], '2026-10-19T12:00:00Z');
  });

  test('rejeita corpo ausente, tipos errados e JSON extra', () async {
    final valid = jsonEncode({
      'titulo': 'P',
      'tipo': 'palestra',
      'salaId': 'sala-101',
      'vagas': 10,
      'encontros': [
        {
          'inicio': '2026-10-19T09:00:00-03:00',
          'fim': '2026-10-19T10:00:00-03:00'
        }
      ]
    });
    expect(
        (await request(api, 'POST', '/atividades', user: 'org-ana'))
            .json['erro'],
        'DADOS_INVALIDOS');
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: '$valid {}'))
            .json['erro'],
        'DADOS_INVALIDOS');
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: {...jsonDecode(valid), 'vagas': '10'}))
            .json['erro'],
        'DADOS_INVALIDOS');
  });

  test('aplica autenticação, perfil e existência também no detalhe e nas ações',
      () async {
    expect((await request(api, 'GET', '/atividades/atv_inexistente')).status,
        401);
    expect(
        (await request(api, 'GET', '/atividades/atv_inexistente',
                user: 'p-carla'))
            .json['erro'],
        'NAO_ENCONTRADO');
    expect(
        (await request(api, 'PATCH', '/atividades/atv_inexistente',
                user: 'p-carla', body: 'nao-json'))
            .json['erro'],
        'SOMENTE_ORGANIZACAO');
    expect(
        (await request(api, 'PATCH', '/atividades/atv_inexistente',
                user: 'org-ana', body: 'nao-json'))
            .json['erro'],
        'NAO_ENCONTRADO');
  });

  test('valida quantidade de encontros para cada tipo nos limites', () async {
    Future<String?> create(String type, int count) async {
      final date = DateTime.utc(2026, 10, 19);
      final encounters = List.generate(count, (index) {
        final day = date.add(Duration(days: index));
        final value =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        return meeting('${value}T09:00:00-03:00', '${value}T10:00:00-03:00');
      });
      final response = await request(api, 'POST', '/atividades',
          user: 'org-ana',
          body: {
            'titulo': '$type-$count',
            'tipo': type,
            'salaId': 'auditorio',
            'vagas': 1,
            'encontros': encounters,
          });
      return response.status == 201 ? null : response.json['erro'] as String;
    }

    expect(await create('palestra', 0), 'QUANTIDADE_DE_ENCONTROS');
    expect(await create('palestra', 1), isNull);
    expect(await create('palestra', 2), 'QUANTIDADE_DE_ENCONTROS');
    api.reset();
    expect(await create('minicurso', 1), 'QUANTIDADE_DE_ENCONTROS');
    api.reset();
    expect(await create('minicurso', 2), isNull);
    api.reset();
    expect(await create('minicurso', 5), isNull);
    expect(await create('minicurso', 6), 'QUANTIDADE_DE_ENCONTROS');
  });

  test('rejeita duração máxima e sobreposição interna', () async {
    expect(
        (await request(api, 'POST', '/atividades', user: 'org-ana', body: {
          'titulo': 'Longa',
          'tipo': 'palestra',
          'salaId': 'auditorio',
          'vagas': 1,
          'encontros': [
            meeting('2026-10-19T09:00:00-03:00',
                '2026-10-19T13:01:00-03:00')
          ]
        })).json['erro'],
        'ENCONTRO_INVALIDO');
    expect(
        (await request(api, 'POST', '/atividades', user: 'org-ana', body: {
          'titulo': 'Sobreposta',
          'tipo': 'minicurso',
          'salaId': 'auditorio',
          'vagas': 1,
          'encontros': [
            meeting('2026-10-19T09:00:00-03:00',
                '2026-10-19T11:00:00-03:00'),
            meeting('2026-10-19T10:00:00-03:00',
                '2026-10-19T12:00:00-03:00')
          ]
        })).json['erro'],
        'ENCONTRO_INVALIDO');
  });

  test('rejeita encontro fora do período inclusivo do evento', () async {
    final response = await request(api, 'POST', '/atividades',
        user: 'org-ana',
        body: activityBody('Fora do evento', date: '2026-10-18'));
    expect(response.status, 422);
    expect(response.json['erro'], 'ENCONTRO_INVALIDO');
  });

  test('rejeita sobreposição de atividades ativas na mesma sala', () async {
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: activityBody('Primeira')))
            .status,
        201);
    final response = await request(api, 'POST', '/atividades',
        user: 'org-ana',
        body: activityBody('Sobreposta',
            start: '09:30', end: '10:30', room: 'sala-101'));
    expect(response.status, 409);
    expect(response.json['erro'], 'CONFLITO_DE_SALA');
  });

  test('aplica conflito com fim igual ao início e intervalo de 15 minutos',
      () async {
    final first = {
      'titulo': 'Primeira',
      'tipo': 'palestra',
      'salaId': 'sala-101',
      'vagas': 10,
      'encontros': [
        {
          'inicio': '2026-10-19T09:00:00-03:00',
          'fim': '2026-10-19T10:00:00-03:00'
        }
      ]
    };
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: first))
            .status,
        201);
    final equal = {
      ...first,
      'titulo': 'Igual',
      'encontros': [
        {
          'inicio': '2026-10-19T10:00:00-03:00',
          'fim': '2026-10-19T11:00:00-03:00'
        }
      ]
    };
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: equal))
            .json['erro'],
        'CONFLITO_DE_SALA');
  });

  test('edita título e aumento de vagas, mas preserva campos imutáveis',
      () async {
    final created =
        await request(api, 'POST', '/atividades', user: 'org-ana', body: {
      'titulo': 'Original',
      'tipo': 'palestra',
      'salaId': 'sala-101',
      'vagas': 10,
      'encontros': [
        {
          'inicio': '2026-10-23T09:00:00-03:00',
          'fim': '2026-10-23T10:00:00-03:00'
        }
      ]
    });
    final id = created.json['id'];
    expect(
        (await request(api, 'PATCH', '/atividades/$id',
                user: 'org-ana', body: {'titulo': 'Novo', 'vagas': 20}))
            .json['vagas'],
        20);
    expect(
        (await request(api, 'PATCH', '/atividades/$id',
                user: 'org-ana', body: {'tipo': 'palestra'}))
            .json['erro'],
        'CAMPO_NAO_EDITAVEL');
  });

  test('cancelamento e situações respeitam relógio e filtros', () async {
    final created =
        await request(api, 'POST', '/atividades', user: 'org-ana', body: {
      'titulo': 'Último',
      'tipo': 'palestra',
      'salaId': 'sala-101',
      'vagas': 10,
      'encontros': [
        {
          'inicio': '2026-10-23T09:00:00-03:00',
          'fim': '2026-10-23T10:00:00-03:00'
        }
      ]
    });
    final id = created.json['id'];
    expect(
        (await request(api, 'PUT', '/_teste/relogio',
                body: {'agora': '2026-10-23T09:00:00-03:00'}))
            .status,
        200);
    expect(
        (await request(api, 'GET', '/atividades/$id', user: 'p-carla'))
            .json['situacao'],
        'em_andamento');
    expect(
        (await request(api, 'POST', '/atividades/$id/cancelamento',
                user: 'org-ana'))
            .json['erro'],
        'ATIVIDADE_JA_INICIADA');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-13T09:00:00-03:00'});
    expect(
        (await request(api, 'POST', '/atividades/$id/cancelamento',
                user: 'org-ana'))
            .json['situacao'],
        'cancelada');
    expect(
        (await request(api, 'GET', '/atividades?dia=2026-10-23',
                user: 'p-carla'))
            .json,
        hasLength(1));
  });

  test('gera IDs contratados, ordena a lista e filtra por Brasília', () async {
    final first = await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Zeta', date: '2026-10-20'));
    final second = await request(api, 'POST', '/atividades',
        user: 'org-ana',
        body: activityBody('Alfa', date: '2026-10-20', room: 'sala-102'));
    expect(first.json['id'], matches(RegExp(r'^atv_[0-9a-f]{8}$')));
    expect(first.json['encontros'][0]['id'],
        matches(RegExp(r'^enc_[0-9a-f]{8}$')));
    final listed = (await request(api, 'GET', '/atividades', user: 'p-carla'))
        .json as List;
    expect(listed.map((item) => item['titulo']), ['Alfa', 'Zeta']);
    final brasilia = await request(api, 'POST', '/atividades',
        user: 'org-ana',
        body: activityBody('Virada UTC',
            date: '2026-10-20',
            start: '01:00',
            end: '02:00',
            room: 'auditorio',
            utc: true));
    expect(brasilia.status, 201);
    expect(
        (await request(api, 'GET', '/atividades?dia=2026-10-19',
                user: 'p-carla'))
            .json
            .map((item) => item['titulo']),
        contains('Virada UTC'));
    expect(
        (await request(api, 'GET', '/atividades?dia=2026-10-20',
                user: 'p-carla'))
            .json
            .map((item) => item['titulo']),
        isNot(contains('Virada UTC')));
    expect(second.status, 201);
  });

  test('PATCH valida tudo antes de persistir qualquer campo', () async {
    final created = await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Original'));
    final id = created.json['id'];
    final failed = await request(api, 'PATCH', '/atividades/$id',
        user: 'org-ana',
        body: {'titulo': 'Nao persistir', 'vagas': 'invalido'});
    expect(failed.json['erro'], 'DADOS_INVALIDOS');
    expect(
        (await request(api, 'GET', '/atividades/$id', user: 'p-carla'))
            .json['titulo'],
        'Original');
  });

  test('aplica as regras comuns a palestra e minicurso', () async {
    for (final type in ['palestra', 'minicurso']) {
      api.reset();
      final meetings = type == 'palestra'
          ? [meeting('2026-10-19T09:00:00-03:00', '2026-10-19T09:59:00-03:00')]
          : [
              meeting('2026-10-19T09:00:00-03:00', '2026-10-19T09:59:00-03:00'),
              meeting('2026-10-20T09:00:00-03:00', '2026-10-20T09:59:00-03:00')
            ];
      final invalidDuration =
          await request(api, 'POST', '/atividades', user: 'org-ana', body: {
        'titulo': type,
        'tipo': type,
        'salaId': 'sala-101',
        'vagas': 10,
        'encontros': meetings
      });
      expect(invalidDuration.json['erro'], 'ENCONTRO_INVALIDO');
      final invalidCapacity =
          await request(api, 'POST', '/atividades', user: 'org-ana', body: {
        'titulo': type,
        'tipo': type,
        'salaId': 'lab-3',
        'vagas': 21,
        'encontros': type == 'palestra'
            ? [
                meeting(
                    '2026-10-19T09:00:00-03:00', '2026-10-19T10:00:00-03:00')
              ]
            : [
                meeting(
                    '2026-10-19T09:00:00-03:00', '2026-10-19T10:00:00-03:00'),
                meeting(
                    '2026-10-20T09:00:00-03:00', '2026-10-20T10:00:00-03:00')
              ]
      });
      expect(invalidCapacity.json['erro'], 'VAGAS_ACIMA_DA_CAPACIDADE');
    }
  });

  test('rejeita campos imutáveis com valores estruturalmente válidos',
      () async {
    final created = await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Imutavel'));
    final id = created.json['id'];
    final changes = <Map<String, dynamic>>[
      {'salaId': 'sala-102'},
      {'tipo': 'palestra'},
      {
        'encontros': [
          meeting('2026-10-19T09:00:00-03:00', '2026-10-19T10:00:00-03:00')
        ]
      },
    ];
    for (final change in changes) {
      expect(
          (await request(api, 'PATCH', '/atividades/$id',
                  user: 'org-ana', body: change))
              .json['erro'],
          'CAMPO_NAO_EDITAVEL');
    }
  });

  test('encontro atravessando meia-noite e bordas do evento', () async {
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana',
                body: activityBody('Meia noite',
                    start: '23:30',
                    end: '00:30',
                    date: '2026-10-19',
                    endDate: '2026-10-20')))
            .json['erro'],
        'ENCONTRO_INVALIDO');
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana',
                body: activityBody('Dia 19', date: '2026-10-19')))
            .status,
        201);
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana',
                body: activityBody('Dia 23',
                    date: '2026-10-23', room: 'sala-102')))
            .status,
        201);
  });

  test('intervalo de 14 minutos conflita e 15 minutos permite', () async {
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: activityBody('Base')))
            .status,
        201);
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana',
                body: activityBody('Quatorze', start: '10:14', end: '11:14')))
            .json['erro'],
        'CONFLITO_DE_SALA');
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana',
                body: activityBody('Quinze', start: '10:15', end: '11:15')))
            .status,
        201);
  });

  test('atividade cancelada libera a sala', () async {
    final created = await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Cancelada'));
    final id = created.json['id'];
    expect(
        (await request(api, 'POST', '/atividades/$id/cancelamento',
                user: 'org-ana'))
            .status,
        200);
    expect(
        (await request(api, 'POST', '/atividades',
                user: 'org-ana', body: activityBody('Substituta')))
            .status,
        201);
  });

  test('expõe estados nas bordas, detalhe, cancelada e filtros combinados',
      () async {
    final created = await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Palestra alvo', date: '2026-10-21'));
    final id = created.json['id'] as String;
    expect(created.json['ocupadas'], 0);
    expect(created.json['vagasRestantes'], 10);
    expect(created.json['emEspera'], 0);
    expect(created.json['situacao'], 'prevista');

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-21T09:00:00-03:00'});
    expect(
        (await request(api, 'GET', '/atividades/$id', user: 'p-carla'))
            .json['situacao'],
        'em_andamento');
    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-21T10:00:00-03:00'});
    expect(
        (await request(api, 'GET', '/atividades/$id', user: 'p-carla'))
            .json['situacao'],
        'encerrada');

    await request(api, 'PUT', '/_teste/relogio',
        body: {'agora': '2026-10-13T09:00:00-03:00'});
    expect(
        (await request(api, 'POST', '/atividades/$id/cancelamento',
                user: 'org-ana'))
            .json['situacao'],
        'cancelada');
    expect(
        (await request(api, 'POST', '/atividades/$id/cancelamento',
                user: 'org-ana'))
            .json['erro'],
        'ATIVIDADE_CANCELADA');
    expect(
        (await request(api, 'PATCH', '/atividades/$id',
                user: 'org-ana', body: {'titulo': 'Tentativa'}))
            .json['erro'],
        'ATIVIDADE_CANCELADA');
    expect(
        (await request(api, 'GET', '/atividades?dia=2026-10-21&tipo=palestra',
                user: 'p-carla'))
            .json,
        hasLength(1));
    expect(
        (await request(api, 'GET', '/atividades/$id', user: 'p-carla')).status,
        200);
  });

  test('aplica filtros de dia e tipo com exclusão efetiva', () async {
    await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Palestra do dia'));
    await request(api, 'POST', '/atividades',
        user: 'org-ana',
        body: activityBody('Minicurso de outro dia',
            type: 'minicurso', date: '2026-10-20', room: 'sala-102'));
    final filtered = await request(api, 'GET',
        '/atividades?dia=2026-10-19&tipo=palestra',
        user: 'p-carla');
    expect(filtered.json, hasLength(1));
    expect(filtered.json.single['titulo'], 'Palestra do dia');
  });

  test('rejeita capacidade na criação e no PATCH sem mutar o título', () async {
    final created = await request(api, 'POST', '/atividades',
        user: 'org-ana', body: activityBody('Intacta', room: 'lab-3', slots: 20));
    final id = created.json['id'] as String;
    final failed = await request(api, 'PATCH', '/atividades/$id',
        user: 'org-ana', body: {'titulo': 'Nao salvar', 'vagas': 21});
    expect(failed.json['erro'], 'VAGAS_ACIMA_DA_CAPACIDADE');
    final detail =
        await request(api, 'GET', '/atividades/$id', user: 'p-carla');
    expect(detail.json['titulo'], 'Intacta');
    expect(detail.json['vagas'], 20);
  });
}

Map<String, dynamic> meeting(String start, String end) =>
    {'inicio': start, 'fim': end};

Map<String, dynamic> activityBody(String title,
    {String type = 'palestra',
    String room = 'sala-101',
    int slots = 10,
    String date = '2026-10-19',
    String start = '09:00',
    String end = '10:00',
    String? endDate,
    bool utc = false}) {
  final firstStart = utc ? '${date}T$start:00Z' : '${date}T$start:00-03:00';
  final firstEnd =
      utc ? '${endDate ?? date}T$end:00Z' : '${endDate ?? date}T$end:00-03:00';
  final encounters = [meeting(firstStart, firstEnd)];
  if (type == 'minicurso')
    encounters.add(meeting('${date}T09:00:00-03:00', '${date}T10:00:00-03:00'));
  return {
    'titulo': title,
    'tipo': type,
    'salaId': room,
    'vagas': slots,
    'encontros': encounters
  };
}
