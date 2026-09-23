import 'dart:convert';
import 'dart:async';

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

  testWidgets('participante registra QR offline e ve sucesso', (tester) async {
    Map<String, dynamic>? sent;
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
      if (request.method == 'POST') {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'pre_3a4b5c6d',
            'encontroId': 'enc_5e6f7a8b',
            'participanteId': 'p-carla',
            'origem': 'qr_offline',
            'lidoEm': sent!['lidoEm'],
            'registradaEm': '2026-10-19T12:01:00Z',
            'justificativa': null,
          }),
          201,
        );
      }
      return http.Response('{}', 404);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'K7M2QX');
    await tester.enterText(find.byType(TextField).last, '2026-10-19T12:00:00Z');
    await tester.tap(find.text('Registrar presença'));
    await tester.pumpAndSettle();
    expect(sent!['lidoEm'], '2026-10-19T12:00:00Z');
    expect(find.byKey(const ValueKey('presenca-sucesso')), findsOneWidget);
  });

  testWidgets('organizacao registra manual e atualiza a lista', (tester) async {
    var listed = false;
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
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(
            listed
                ? [
                    {
                      'id': 'pre_3a4b5c6d',
                      'encontroId': 'enc_5e6f7a8b',
                      'participanteId': 'p-carla',
                      'origem': 'manual',
                      'lidoEm': '2026-10-19T12:00:00Z',
                      'registradaEm': '2026-10-19T12:00:00Z',
                      'justificativa': 'Presenca autorizada',
                    },
                  ]
                : [],
          ),
          200,
        );
      }
      listed = true;
      return http.Response(
        jsonEncode({
          'id': 'pre_3a4b5c6d',
          'encontroId': 'enc_5e6f7a8b',
          'participanteId': 'p-carla',
          'origem': 'manual',
          'lidoEm': '2026-10-19T12:00:00Z',
          'registradaEm': '2026-10-19T12:00:00Z',
          'justificativa': 'Presenca autorizada',
        }),
        201,
      );
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'p-carla');
    await tester.enterText(fields.at(1), 'Presenca autorizada');
    await tester.tap(find.text('Registrar manual'));
    await tester.pumpAndSettle();
    expect(find.text('p-carla'), findsNWidgets(2));
    expect(find.text('manual'), findsOneWidget);
    expect(find.text('Presença manual registrada.'), findsOneWidget);
  });

  testWidgets('presencas mostra loading e erro da API', (tester) async {
    final gate = Completer<http.Response>();
    final client = MockClient((request) {
      if (request.url.path == '/atividades') return gate.future;
      return Future.value(http.Response('{}', 404));
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    gate.complete(
      http.Response(
        jsonEncode({'erro': 'ERRO_TESTE', 'mensagem': 'falha'}),
        422,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ERRO_TESTE'), findsOneWidget);
  });
}
