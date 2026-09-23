import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/api_client.dart';
import 'package:frontend/presencas_page.dart';

void main() {
  testWidgets('organizacao ve codigo e estado vazio da lista M3', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/atividades') {
        return http.Response(
          jsonEncode([
            {
              'id': 'atv_1a2b3c4d',
              'titulo': 'Palestra',
              'encontros': [
                {'id': 'enc_5e6f7a8b', 'inicio': '2026-10-19T12:00:00Z'},
              ],
            },
          ]),
          200,
        );
      }
      if (request.url.path.endsWith('/presencas')) {
        return http.Response('[]', 200);
      }
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
      return http.Response('{}', 404);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma presença registrada.'), findsOneWidget);
    await tester.tap(find.text('Obter QR'));
    await tester.pumpAndSettle();
    expect(find.text('Código: K7M2QX'), findsOneWidget);
  });
}
