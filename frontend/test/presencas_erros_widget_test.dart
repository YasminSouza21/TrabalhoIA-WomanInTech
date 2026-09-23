import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/api_client.dart';
import 'package:frontend/presencas_page.dart';

const activityPayload = [
  {
    'id': 'atv_1a2b3c4d',
    'titulo': 'Palestra',
    'encontros': [
      {'id': 'enc_5e6f7a8b', 'inicio': '2026-10-19T12:00:00Z'},
    ],
  },
];

http.Response activitiesResponse() =>
    http.Response(jsonEncode(activityPayload), 200);

void main() {
  testWidgets('mostra erro ao obter QR com MockClient', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/atividades') return activitiesResponse();
      if (request.url.path.endsWith('/presencas')) return http.Response('[]', 200);
      return http.Response(
          jsonEncode({'erro': 'FORA_DA_JANELA', 'mensagem': 'erro'}), 422);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obter QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('presenca-erro')), findsOneWidget);
    expect(find.text('FORA_DA_JANELA'), findsOneWidget);
  });

  testWidgets('mostra erro ao listar presencas com MockClient', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/atividades') return activitiesResponse();
      return http.Response(
          jsonEncode({'erro': 'ERRO_LISTA', 'mensagem': 'erro'}), 500);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    expect(find.text('ERRO_LISTA'), findsOneWidget);
  });

  testWidgets('mostra erro ao registrar manual com MockClient', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/atividades') return activitiesResponse();
      if (request.method == 'GET') return http.Response('[]', 200);
      return http.Response(
          jsonEncode({'erro': 'JUSTIFICATIVA_OBRIGATORIA', 'mensagem': 'erro'}),
          422);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'p-carla');
    await tester.enterText(fields.at(1), 'Justificativa de teste');
    await tester.tap(find.text('Registrar manual'));
    await tester.pumpAndSettle();
    expect(find.text('JUSTIFICATIVA_OBRIGATORIA'), findsOneWidget);
  });

  testWidgets('mostra erro ao registrar QR online sem HTTP real',
      (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/atividades') return activitiesResponse();
      return http.Response(
          jsonEncode({'erro': 'CODIGO_INVALIDO', 'mensagem': 'erro'}), 422);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'K7M2QX');
    await tester.tap(find.text('Registrar presença'));
    await tester.pumpAndSettle();
    expect(find.text('CODIGO_INVALIDO'), findsOneWidget);
  });

  testWidgets('registra QR online sem enviar lidoEm e exibe sucesso',
      (tester) async {
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      if (request.url.path == '/atividades') return activitiesResponse();
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
          jsonEncode({...attendanceJson, 'origem': 'qr'}), 201);
    });
    final api = ApiClient(baseUrl: 'http://api.test', client: client)
      ..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: PresencasPage(client: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'K7M2QX');
    await tester.tap(find.text('Registrar presença'));
    await tester.pumpAndSettle();
    expect(sent, {'codigo': 'K7M2QX'});
    expect(find.byKey(const ValueKey('presenca-sucesso')), findsOneWidget);
  });
}

const attendanceJson = {
  'id': 'pre_3a4b5c6d',
  'encontroId': 'enc_5e6f7a8b',
  'participanteId': 'p-carla',
  'origem': 'qr',
  'lidoEm': '2026-10-19T12:00:00Z',
  'registradaEm': '2026-10-19T12:01:00Z',
  'justificativa': null,
};
