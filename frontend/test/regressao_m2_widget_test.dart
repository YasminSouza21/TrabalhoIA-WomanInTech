import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/api_client.dart';
import 'package:frontend/inscricoes_page.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets(
    'descarta resposta antiga de usuário trocado durante o carregamento',
    (tester) async {
      final gate = Completer<void>();
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/atividades') {
            if (request.headers['X-Usuario'] == 'p-carla') {
              await gate.future;
              return http.Response(
                jsonEncode([_atividade('atv_carla', 'Atividade da Carla')]),
                200,
              );
            }
            return http.Response(
              jsonEncode([_atividade('atv_org', 'Atividade da Organizacao')]),
              200,
            );
          }
          if (request.headers['X-Usuario'] == 'p-carla') {
            return http.Response(
              jsonEncode([
                _inscricao(
                  id: 'ins_carla',
                  atividadeId: 'atv_carla',
                  status: 'confirmada',
                ),
              ]),
              200,
            );
          }
          return http.Response(
            jsonEncode([
              _inscricao(
                id: 'ins_org',
                atividadeId: 'atv_org',
                status: 'confirmada',
              ),
            ]),
            200,
          );
        }),
      )..user = 'p-carla';
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('seletor-usuario')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Ana Beatriz Lima (organizacao)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
      expect(find.text('Atividade da Organizacao'), findsOneWidget);
      gate.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Atividade da Organizacao'), findsOneWidget);
      expect(find.text('Atividade da Carla'), findsNothing);
      expect(find.text('atv_carla'), findsNothing);
    },
  );

  testWidgets(
    'filtro trocado durante o carregamento descarta resposta antiga',
    (tester) async {
      final all = [
        _inscricao(
            id: 'ins_a', atividadeId: 'atv_2', status: 'confirmada'),
        _inscricao(
            id: 'ins_b', atividadeId: 'atv_1', status: 'confirmada'),
      ];
      final gate = Completer<void>();
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/atividades') {
            return http.Response(
              jsonEncode([
                _atividade('atv_1', 'Palestra de IA'),
                _atividade('atv_2', 'Minicurso Flutter'),
              ]),
              200,
            );
          }
          final filtered = request.url.queryParameters['atividadeId'];
          if (filtered == 'atv_2') {
            await gate.future;
            return http.Response(
              jsonEncode(
                all.where((ins) => ins['atividadeId'] == 'atv_2').toList(),
              ),
              200,
            );
          }
          if (filtered == null) {
            return http.Response(jsonEncode(all), 200);
          }
          return http.Response(
            jsonEncode(
              all.where((ins) => ins['atividadeId'] == filtered).toList(),
            ),
            200,
          );
        }),
      )..user = 'org-ana';
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
      await tester.pumpAndSettle();
      expect(find.text('Palestra de IA'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('filtro-atividade')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minicurso Flutter').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('filtro-atividade')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Palestra de IA').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Minicurso Flutter'), findsNothing);
      gate.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Minicurso Flutter'), findsNothing);
      expect(find.text('Palestra de IA'), findsWidgets);
    },
  );

  testWidgets('retorno das inscricoes sincroniza seletor e recarrega a grade', (
    tester,
  ) async {
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(
            jsonEncode([_atividade('atv_1', 'Palestra de IA')]),
            200,
          );
        }
        return http.Response(jsonEncode(<Object>[]), 200);
      }),
    )..user = 'p-carla';
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.event_note));
    await tester.pumpAndSettle();
    expect(find.text('Minhas inscrições'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('seletor-usuario')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Beatriz Lima (organizacao)'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Nova atividade'), findsOneWidget);
    expect(find.textContaining('Ana Beatriz Lima'), findsOneWidget);
  });

  testWidgets('fechar detalhe apos inscrever atualiza contadores da grade', (
    tester,
  ) async {
    var atividadeJson = _atividade('atv_1', 'Palestra de IA')
      ..['vagasRestantes'] = 19;
    var inscricoesAtv = <Map<String, dynamic>>[];
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
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode([atividadeJson]), 200);
        }
        if (request.url.path == '/atividades/atv_1/inscricoes') {
          atividadeJson = _atividade('atv_1', 'Palestra de IA')
            ..['vagasRestantes'] = 18;
          inscricoesAtv = [
            _inscricao(
                id: 'ins_1', atividadeId: 'atv_1', status: 'confirmada'),
          ];
          return http.Response(jsonEncode(inscricoesAtv.single), 201);
        }
        return http.Response(jsonEncode(inscricoesAtv), 200);
      }),
    )..user = 'p-carla';
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palestra de IA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vagas restantes: 19'), findsOneWidget);
    await tester.tap(find.text('Inscrever'));
    await tester.pumpAndSettle();
    expect(find.text('confirmada'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palestra de IA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vagas restantes: 18'), findsOneWidget);
  });

  testWidgets('lista permite cancelar inscricao convocada via POST e recarrega', (
    tester,
  ) async {
    final deadline = DateTime.now().add(const Duration(hours: 1));
    final inscricoesJson = [
      _inscricao(
        id: 'ins_convocada',
        atividadeId: 'atv_1',
        status: 'convocada',
        convocadaAte: deadline.toIso8601String(),
      ),
    ];
    var cancelCalls = 0;
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(
            jsonEncode([_atividade('atv_1', 'Palestra de IA')]),
            200,
          );
        }
        if (request.url.path == '/inscricoes/ins_convocada/cancelamento') {
          cancelCalls++;
          expect(request.method, 'POST');
          expect(request.headers['X-Usuario'], 'p-carla');
          inscricoesJson[0]['status'] = 'cancelada';
          inscricoesJson[0]['convocadaAte'] = null;
          return http.Response(jsonEncode(inscricoesJson[0]), 200);
        }
        return http.Response(jsonEncode(inscricoesJson), 200);
      }),
    )..user = 'p-carla';
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pump();
    await tester.pump();
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(cancelCalls, 1);
    await tester.pump();
    await tester.pump();
    expect(find.text('cancelada'), findsOneWidget);
    expect(find.text('Convocado até'), findsNothing);
  });

  testWidgets(
    'contagem regressiva reflete tempo decorrido real mesmo com callback atrasado',
    (tester) async {
      var fakeNow = DateTime(2026, 10, 19, 18, 0, 0);
      final deadline = fakeNow.add(const Duration(minutes: 1));
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/atividades') {
            return http.Response(
              jsonEncode([_atividade('atv_1', 'Palestra de IA')]),
              200,
            );
          }
          return http.Response(
            jsonEncode([
              _inscricao(
                id: 'ins_convocada',
                atividadeId: 'atv_1',
                status: 'convocada',
                convocadaAte: deadline.toIso8601String(),
              ),
            ]),
            200,
          );
        }),
      )..user = 'p-carla';
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: InscricoesPage(client: client, clock: () => fakeNow)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Restam 00:01:00'), findsOneWidget);
      fakeNow = fakeNow.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Restam 00:00:50'), findsOneWidget);
    },
  );
}

Map<String, dynamic> _atividade(String id, String titulo) => {
  'id': id,
  'titulo': titulo,
  'tipo': 'palestra',
  'salaId': 'lab-3',
  'vagas': 20,
  'situacao': 'prevista',
  'cargaHorariaMinutos': 60,
  'vagasRestantes': 19,
  'encontros': <Object>[],
};

Map<String, dynamic> _inscricao({
  required String id,
  required String atividadeId,
  required String status,
  int? posicaoNaEspera,
  String? convocadaAte,
}) =>
    {
      'id': id,
      'atividadeId': atividadeId,
      'participanteId': 'p-carla',
      'status': status,
      'posicaoNaEspera': posicaoNaEspera,
      'convocadaAte': convocadaAte,
      'criadaEm': '2026-10-19T18:00:00-03:00',
    };