import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/api_client.dart';

void main() {
  test('Inscricao expõe os campos exatos do contrato com nulos fora do caso',
      () {
    final ins = Inscricao({
      'id': 'ins_9c0d1e2f',
      'atividadeId': 'atv_1a2b3c4d',
      'participanteId': 'p-carla',
      'status': 'confirmada',
      'posicaoNaEspera': null,
      'convocadaAte': null,
      'criadaEm': '2026-10-19T18:00:00-03:00',
    });
    expect(ins.id, 'ins_9c0d1e2f');
    expect(ins.atividadeId, 'atv_1a2b3c4d');
    expect(ins.participanteId, 'p-carla');
    expect(ins.status, 'confirmada');
    expect(ins.posicaoNaEspera, isNull);
    expect(ins.convocadaAte, isNull);
    expect(ins.criadaEm, '2026-10-19T18:00:00-03:00');
  });

  test('listarInscricoes chama GET /inscricoes com filtro atividadeId e X-Usuario',
      () async {
    late Uri called;
    final client = MockClient((request) async {
      called = request.url;
      expect(request.method, 'GET');
      expect(request.headers['X-Usuario'], 'p-carla');
      return http.Response(jsonEncode([
        {
          'id': 'ins_9c0d1e2f',
          'atividadeId': 'atv_1a2b3c4d',
          'participanteId': 'p-carla',
          'status': 'em_espera',
          'posicaoNaEspera': 1,
          'convocadaAte': null,
          'criadaEm': '2026-10-19T18:00:00-03:00',
        },
      ]), 200);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    final result = await api.listarInscricoes(atividadeId: 'atv_1a2b3c4d');
    expect(result.single.id, 'ins_9c0d1e2f');
    expect(result.single.posicaoNaEspera, 1);
    expect(called.path, '/inscricoes');
    expect(called.queryParameters, {'atividadeId': 'atv_1a2b3c4d'});
  });

  test('inscricaoDetalhe chama GET /inscricoes/:id com X-Usuario', () async {
    late Uri called;
    final client = MockClient((request) async {
      called = request.url;
      expect(request.method, 'GET');
      expect(request.headers['X-Usuario'], 'p-carla');
      return http.Response(jsonEncode({
        'id': 'ins_9c0d1e2f',
        'atividadeId': 'atv_1a2b3c4d',
        'participanteId': 'p-carla',
        'status': 'convocada',
        'posicaoNaEspera': null,
        'convocadaAte': '2026-10-20T18:00:00-03:00',
        'criadaEm': '2026-10-19T18:00:00-03:00',
      }), 200);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    final result = await api.inscricaoDetalhe('ins_9c0d1e2f');
    expect(result.id, 'ins_9c0d1e2f');
    expect(result.status, 'convocada');
    expect(result.convocadaAte, '2026-10-20T18:00:00-03:00');
    expect(called.path, '/inscricoes/ins_9c0d1e2f');
  });

  test('inscrever chama POST /atividades/:id/inscricoes sem corpo e retorna Inscricao',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/atividades/atv_1a2b3c4d/inscricoes');
      expect(request.headers['X-Usuario'], 'p-carla');
      expect(request.body, isEmpty);
      return http.Response(jsonEncode({
        'id': 'ins_9c0d1e2f',
        'atividadeId': 'atv_1a2b3c4d',
        'participanteId': 'p-carla',
        'status': 'confirmada',
        'posicaoNaEspera': null,
        'convocadaAte': null,
        'criadaEm': '2026-10-19T18:00:00-03:00',
      }), 201);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    final result = await api.inscrever('atv_1a2b3c4d');
    expect(result.id, 'ins_9c0d1e2f');
    expect(result.status, 'confirmada');
  });

  test('cancelarInscricao chama POST /inscricoes/:id/cancelamento com X-Usuario',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/inscricoes/ins_9c0d1e2f/cancelamento');
      expect(request.headers['X-Usuario'], 'p-carla');
      return http.Response(jsonEncode({
        'id': 'ins_9c0d1e2f',
        'atividadeId': 'atv_1a2b3c4d',
        'participanteId': 'p-carla',
        'status': 'cancelada',
        'posicaoNaEspera': null,
        'convocadaAte': null,
        'criadaEm': '2026-10-19T18:00:00-03:00',
      }), 200);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    final result = await api.cancelarInscricao('ins_9c0d1e2f');
    expect(result.id, 'ins_9c0d1e2f');
    expect(result.status, 'cancelada');
  });

  test('confirmarConvocacao chama POST /inscricoes/:id/confirmacao sem corpo e com X-Usuario',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/inscricoes/ins_9c0d1e2f/confirmacao');
      expect(request.headers['X-Usuario'], 'p-carla');
      expect(request.body, isEmpty);
      return http.Response(jsonEncode({
        'id': 'ins_9c0d1e2f',
        'atividadeId': 'atv_1a2b3c4d',
        'participanteId': 'p-carla',
        'status': 'confirmada',
        'posicaoNaEspera': null,
        'convocadaAte': null,
        'criadaEm': '2026-10-19T18:00:00-03:00',
      }), 200);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    final result = await api.confirmarConvocacao('ins_9c0d1e2f');
    expect(result.id, 'ins_9c0d1e2f');
    expect(result.status, 'confirmada');
  });

  test('mutação do M2 preserva erro do envelope em ApiFailure', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'erro': 'JA_INSCRITO', 'mensagem': 'texto livre'}),
          409,
        ),
      ),
    )..user = 'p-carla';
    expect(
      () => api.inscrever('atv_1a2b3c4d'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.status, 'status', 409)
            .having((f) => f.code, 'code', 'JA_INSCRITO'),
      ),
    );
  });
}