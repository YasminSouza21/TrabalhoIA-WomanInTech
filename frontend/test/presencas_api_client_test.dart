import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/api_client.dart';

Map<String, dynamic> attendanceJson() => {
  'id': 'pre_3a4b5c6d',
  'encontroId': 'enc_5e6f7a8b',
  'participanteId': 'p-carla',
  'origem': 'qr',
  'lidoEm': '2026-10-19T12:00:00Z',
  'registradaEm': '2026-10-19T12:01:00Z',
  'justificativa': null,
};

void main() {
  test('ApiClient chama os quatro endpoints M3 com X-Usuario', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add('${request.method} ${request.url.path}');
      expect(request.headers['X-Usuario'], 'org-ana');
      if (request.url.path.endsWith('/codigo')) {
        return http.Response(
          jsonEncode({
            'encontroId': 'enc_5e6f7a8b',
            'codigo': 'K7M2QX',
            'trocaEm': '2026-10-19T12:05:00Z',
            'validoAte': '2026-10-19T12:05:00Z',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/manual')) {
        return http.Response(
          jsonEncode({...attendanceJson(), 'origem': 'manual'}),
          201,
        );
      }
      if (request.method == 'POST') {
        return http.Response(jsonEncode(attendanceJson()), 201);
      }
      return http.Response(jsonEncode([attendanceJson()]), 200);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';

    expect((await api.meetingCode('enc_5e6f7a8b')).code, 'K7M2QX');
    expect((await api.registerQr('enc_5e6f7a8b', 'K7M2QX')).origin, 'qr');
    expect(
      (await api.registerManual(
        'enc_5e6f7a8b',
        'p-carla',
        'Participacao confirmada',
      )).origin,
      'manual',
    );
    expect((await api.attendances('enc_5e6f7a8b')).single.id, 'pre_3a4b5c6d');
    expect(paths, [
      'GET /encontros/enc_5e6f7a8b/codigo',
      'POST /encontros/enc_5e6f7a8b/presencas',
      'POST /encontros/enc_5e6f7a8b/presencas/manual',
      'GET /encontros/enc_5e6f7a8b/presencas',
    ]);
  });
}
