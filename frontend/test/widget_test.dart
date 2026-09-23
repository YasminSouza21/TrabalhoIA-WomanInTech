import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/main.dart';
import 'package:frontend/api_client.dart';

void main() {
  testWidgets('mostra estado vazio depois do loading', (tester) async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    await tester.pumpWidget(GradeApp(client: client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma atividade encontrada.'), findsOneWidget);
  });

  testWidgets('mostra resultados e situação retornada pela API', (
    tester,
  ) async {
    final response = jsonEncode([
      {
        'id': 'atv_1',
        'titulo': 'Flutter',
        'tipo': 'palestra',
        'salaId': 'lab-3',
        'vagas': 20,
        'situacao': 'em_andamento',
        'cargaHorariaMinutos': 60,
        'vagasRestantes': 20,
      },
    ]);
    final client = ApiClient(
      client: MockClient((_) async => http.Response(response, 200)),
    );
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('em_andamento'), findsOneWidget);
  });

  testWidgets('mostra sala com capacidade e encontros no detalhe', (
    tester,
  ) async {
    final activity = {
      'id': 'atv_1',
      'titulo': 'Flutter',
      'tipo': 'palestra',
      'salaId': 'lab-3',
      'vagas': 20,
      'situacao': 'prevista',
      'cargaHorariaMinutos': 60,
      'vagasRestantes': 20,
      'encontros': [
        {'inicio': '2026-10-19T12:00:00Z', 'fim': '2026-10-19T13:00:00Z'},
      ],
    };
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/salas') {
          return http.Response(
            jsonEncode([
              {'id': 'lab-3', 'nome': 'Laboratório 3', 'capacidade': 20},
            ]),
            200,
          );
        }
        return http.Response(jsonEncode([activity]), 200);
      }),
    );
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Laboratório 3 (20 lugares)'), findsOneWidget);
    expect(find.textContaining('2026-10-19T12:00:00Z'), findsOneWidget);
  });

  testWidgets('mostra erro da API', (tester) async {
    final client = ApiClient(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'erro': 'USUARIO_DESCONHECIDO'}), 401),
      ),
    );
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    expect(find.text('USUARIO_DESCONHECIDO'), findsOneWidget);
  });

  testWidgets('seletor usa usuários do contrato e controla ações por papel', (
    tester,
  ) async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    expect(find.text('Nova atividade'), findsNothing);
    expect(find.byType(DropdownButton<String>), findsNWidgets(2));
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Beatriz Lima (organizacao)'));
    await tester.pumpAndSettle();
    expect(find.text('Nova atividade'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carla Mendes Souza (participante)'));
    await tester.pumpAndSettle();
    expect(find.text('Nova atividade'), findsNothing);
  });

  testWidgets('não oferece ações de organização para atividade cancelada', (
    tester,
  ) async {
    final activity = {
      'id': 'atv_cancelada',
      'titulo': 'Atividade cancelada',
      'tipo': 'palestra',
      'salaId': 'sala-101',
      'vagas': 10,
      'situacao': 'cancelada',
      'cargaHorariaMinutos': 60,
      'vagasRestantes': 10,
      'encontros': [
        {'inicio': '2026-10-19T12:00:00Z', 'fim': '2026-10-19T13:00:00Z'},
      ],
    };
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/salas') {
          return http.Response(
            jsonEncode([
              {'id': 'sala-101', 'nome': 'Sala 101', 'capacidade': 30},
            ]),
            200,
          );
        }
        return http.Response(jsonEncode([activity]), 200);
      }),
    );
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Beatriz Lima (organizacao)'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsNothing);
    await tester.tap(find.text('Atividade cancelada'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar atividade'), findsNothing);
  });
}
