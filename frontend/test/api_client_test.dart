import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/api_client.dart';

void main() {
  test('ApiClient envia filtros e X-Usuario', () async {
    late Uri called;
    final client = MockClient((request) async {
      called = request.url;
      expect(request.headers['X-Usuario'], 'p-carla');
      return http.Response(
        jsonEncode([
          {
            'id': 'atv_1',
            'titulo': 'P',
            'tipo': 'palestra',
            'salaId': 'sala-101',
            'vagas': 1,
            'situacao': 'prevista',
            'cargaHorariaMinutos': 60,
          },
        ]),
        200,
      );
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    final result = await api.activities(type: 'palestra', day: '2026-10-19');
    expect(result.single['titulo'], 'P');
    expect(called.queryParameters, {'tipo': 'palestra', 'dia': '2026-10-19'});
  });

  test('ApiClient transforma erro HTTP em ApiFailure', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'erro': 'SOMENTE_ORGANIZACAO'}), 403),
      ),
    );
    expect(() => api.activities(), throwsA(isA<ApiFailure>()));
  });

  test('ApiClient centraliza criação, edição e cancelamento', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add('${request.method} ${request.url.path}');
      return http.Response(jsonEncode({'id': 'atv_1'}), 200);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';
    await api.create({'titulo': 'P'});
    await api.update('atv_1', {'titulo': 'Nova'});
    await api.cancel('atv_1');
    expect(paths, [
      'POST /atividades',
      'PATCH /atividades/atv_1',
      'POST /atividades/atv_1/cancelamento',
    ]);
  });

  test('ApiClient consulta salas e detalhe pelo transporte centralizado', () async {
    final paths = <String>[];
    final api = ApiClient(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        if (request.url.path == '/salas') {
          return http.Response(
              jsonEncode([{'id': 'lab-3', 'nome': 'Laboratório 3', 'capacidade': 20}]), 200);
        }
        return http.Response(jsonEncode({
          'id': 'atv_1',
          'titulo': 'Flutter',
          'tipo': 'palestra',
          'salaId': 'lab-3',
          'vagas': 10,
          'encontros': [],
          'cargaHorariaMinutos': 60,
          'situacao': 'prevista',
        }), 200);
      }),
    )..user = 'p-carla';
    final rooms = await api.rooms();
    final activity = await api.activity('atv_1');
    expect(Room(rooms.single).name, 'Laboratório 3');
    expect(Activity(activity).meetings, isEmpty);
    expect(paths, ['GET /salas', 'GET /atividades/atv_1']);
  });
}
