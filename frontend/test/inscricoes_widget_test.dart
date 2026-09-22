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
  testWidgets('mostra estado vazio depois do loading', (tester) async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('[]', 200)),
    )..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Você ainda não tem inscrições.'), findsOneWidget);
  });

  testWidgets('mostra erro e tenta novamente recarregando', (tester) async {
    var calls = 0;
    final client = ApiClient(
      client: MockClient((_) async {
        calls++;
        if (calls == 1) {
          return http.Response(jsonEncode({'erro': 'ERRO_TESTE'}), 500);
        }
        return http.Response('[]', 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pumpAndSettle();
    expect(find.text('ERRO_TESTE'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('ERRO_TESTE'), findsNothing);
    expect(find.text('Você ainda não tem inscrições.'), findsOneWidget);
  });

  testWidgets(
    'mostra todos os status identificados pelo titulo com posicao, prazo e contagem',
    (tester) async {
      final deadline = DateTime.now().add(const Duration(hours: 1));
      final activities = [
        _atividade('atv_1', 'Palestra de IA'),
        _atividade('atv_2', 'Minicurso Flutter'),
        _atividade('atv_3', 'Oficina de Design'),
        _atividade('atv_4', 'Mesa Redonda'),
        _atividade('atv_5', 'Hackathon'),
      ];
      final inscricoes = [
        _inscricao(
            id: 'ins_confirmada',
            atividadeId: 'atv_1',
            status: 'confirmada'),
        _inscricao(
            id: 'ins_espera',
            atividadeId: 'atv_2',
            status: 'em_espera',
            posicaoNaEspera: 3),
        _inscricao(
            id: 'ins_convocada',
            atividadeId: 'atv_3',
            status: 'convocada',
            convocadaAte: deadline.toIso8601String()),
        _inscricao(
            id: 'ins_cancelada',
            atividadeId: 'atv_4',
            status: 'cancelada'),
        _inscricao(id: 'ins_expirada', atividadeId: 'atv_5', status: 'expirada'),
      ];
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/atividades') {
            return http.Response(jsonEncode(activities), 200);
          }
          return http.Response(jsonEncode(inscricoes), 200);
        }),
      )..user = 'p-carla';
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
      await tester.pump();
      await tester.pump();
      expect(find.text('Palestra de IA'), findsOneWidget);
      expect(find.text('Minicurso Flutter'), findsOneWidget);
      expect(find.text('Oficina de Design'), findsOneWidget);
      expect(find.text('Mesa Redonda'), findsOneWidget);
      expect(find.text('Hackathon'), findsOneWidget);
      expect(find.text('confirmada'), findsOneWidget);
      expect(find.text('em_espera'), findsOneWidget);
      expect(find.text('convocada'), findsOneWidget);
      expect(find.text('cancelada'), findsOneWidget);
      expect(find.text('expirada'), findsOneWidget);
      expect(find.text('Posição na espera: 3'), findsOneWidget);
      expect(find.textContaining('Convocado até'), findsOneWidget);
      expect(find.textContaining('Restam'), findsOneWidget);
    },
  );

  testWidgets('contagem regressiva da convocacao muda com o tempo', (
    tester,
  ) async {
    var fakeNow = DateTime(2026, 10, 19, 12, 0, 0);
    final deadline = fakeNow.add(const Duration(minutes: 2));
    final activities = [_atividade('atv_3', 'Oficina de Design')];
    final inscricoes = [
      _inscricao(
        id: 'ins_convocada',
        atividadeId: 'atv_3',
        status: 'convocada',
        convocadaAte: deadline.toIso8601String(),
      ),
    ];
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode(activities), 200);
        }
        return http.Response(jsonEncode(inscricoes), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(
      MaterialApp(
        home: InscricoesPage(client: client, clock: () => fakeNow),
      ),
    );
    await tester.pump();
    await tester.pump();
    final antes = tester
        .widget<Text>(find.textContaining('Restam'))
        .data;
    fakeNow = fakeNow.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    final depois = tester
        .widget<Text>(find.textContaining('Restam'))
        .data;
    expect(antes, isNot(equals(depois)));
  });

  testWidgets(
    'participante cancela inscricao via POST com X-Usuario, desabilita durante envio e recarrega',
    (tester) async {
      final activities = [_atividade('atv_1', 'Palestra de IA')];
      final inscricoesJson = [
        _inscricao(
            id: 'ins_1', atividadeId: 'atv_1', status: 'confirmada'),
      ];
      final gate = Completer<void>();
      var mutationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/atividades') {
            return http.Response(jsonEncode(activities), 200);
          }
          if (request.url.path == '/inscricoes/ins_1/cancelamento') {
            mutationCalls++;
            expect(request.method, 'POST');
            expect(request.headers['X-Usuario'], 'p-carla');
            await gate.future;
            inscricoesJson[0]['status'] = 'cancelada';
            return http.Response(jsonEncode(inscricoesJson[0]), 200);
          }
          return http.Response(jsonEncode(inscricoesJson), 200);
        }),
      )..user = 'p-carla';
      await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
      await tester.pump();
      await tester.pump();
      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      expect(mutationCalls, 1);
      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancelar'),
      );
      expect(cancelButton.onPressed, isNull);
      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Cancelar'), findsNothing);
      expect(find.text('cancelada'), findsOneWidget);
      expect(find.text('Inscrição cancelada.'), findsOneWidget);
    },
  );

  testWidgets(
    'participante confirma convocacao via POST com X-Usuario e recarrega',
    (tester) async {
      final deadline = DateTime.now().add(const Duration(minutes: 5));
      final activities = [_atividade('atv_3', 'Oficina de Design')];
      final inscricoesJson = [
        _inscricao(
          id: 'ins_2',
          atividadeId: 'atv_3',
          status: 'convocada',
          convocadaAte: deadline.toIso8601String(),
        ),
      ];
      var mutationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/atividades') {
            return http.Response(jsonEncode(activities), 200);
          }
          if (request.url.path == '/inscricoes/ins_2/confirmacao') {
            mutationCalls++;
            expect(request.method, 'POST');
            expect(request.headers['X-Usuario'], 'p-carla');
            inscricoesJson[0]['status'] = 'confirmada';
            inscricoesJson[0]['convocadaAte'] = null;
            return http.Response(jsonEncode(inscricoesJson[0]), 200);
          }
          return http.Response(jsonEncode(inscricoesJson), 200);
        }),
      )..user = 'p-carla';
      await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
      await tester.pump();
      await tester.pump();
      expect(find.text('Confirmar convocação'), findsOneWidget);
      await tester.tap(find.text('Confirmar convocação'));
      await tester.pump();
      expect(mutationCalls, 1);
      await tester.pump();
      expect(find.text('Confirmar convocação'), findsNothing);
      expect(find.text('confirmada'), findsOneWidget);
      expect(find.text('Inscrição confirmada.'), findsOneWidget);
    },
  );

  testWidgets('organizacao consulta todas as inscricoes sem botao de mutacao', (
    tester,
  ) async {
    final activities = [
      _atividade('atv_1', 'Palestra de IA'),
      _atividade('atv_2', 'Minicurso Flutter'),
    ];
    final inscricoes = [
      _inscricao(
          id: 'ins_a', atividadeId: 'atv_1', status: 'confirmada'),
      _inscricao(
          id: 'ins_b',
          atividadeId: 'atv_2',
          status: 'em_espera',
          posicaoNaEspera: 1),
    ];
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          fail('organização não deve mutar inscrição: ${request.url.path}');
        }
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode(activities), 200);
        }
        expect(request.headers['X-Usuario'], 'org-ana');
        return http.Response(jsonEncode(inscricoes), 200);
      }),
    )..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pump();
    await tester.pump();
    expect(find.text('Inscrições'), findsOneWidget);
    expect(find.text('Palestra de IA'), findsOneWidget);
    expect(find.text('Minicurso Flutter'), findsOneWidget);
    expect(find.text('Posição na espera: 1'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Confirmar convocação'), findsNothing);
  });

  testWidgets('organizacao filtra inscricoes por atividade pelo dropdown', (
    tester,
  ) async {
    final activities = [
      _atividade('atv_1', 'Palestra de IA'),
      _atividade('atv_2', 'Minicurso Flutter'),
    ];
    final all = [
      _inscricao(
          id: 'ins_a', atividadeId: 'atv_1', status: 'confirmada'),
      _inscricao(
          id: 'ins_b', atividadeId: 'atv_2', status: 'confirmada'),
      _inscricao(
          id: 'ins_c',
          atividadeId: 'atv_1',
          status: 'em_espera',
          posicaoNaEspera: 2),
    ];
    final requestedQueries = <Uri>[];
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode(activities), 200);
        }
        requestedQueries.add(request.url);
        final filtered = request.url.queryParameters['atividadeId'];
        if (filtered == null) return http.Response(jsonEncode(all), 200);
        return http.Response(
          jsonEncode(
            all.where((ins) => ins['atividadeId'] == filtered).toList(),
          ),
          200,
        );
      }),
    )..user = 'org-ana';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pump();
    await tester.pump();
    expect(find.text('Palestra de IA'), findsNWidgets(2));
    expect(find.text('Minicurso Flutter'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('filtro-atividade')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palestra de IA').last);
    await tester.pumpAndSettle();
    expect(
      requestedQueries.last.queryParameters['atividadeId'],
      'atv_1',
    );
    expect(find.text('Minicurso Flutter'), findsNothing);
    expect(find.text('Palestra de IA'), findsNWidgets(3));
  });

  testWidgets('troca de usuario limpa dados e recarrega com novo perfil', (
    tester,
  ) async {
    final activities = [
      _atividade('atv_1', 'Palestra de IA'),
      _atividade('atv_2', 'Minicurso Flutter'),
    ];
    final participantes = [
      _inscricao(
          id: 'ins_p', atividadeId: 'atv_1', status: 'confirmada'),
    ];
    final organizacao = [
      _inscricao(
          id: 'ins_o',
          atividadeId: 'atv_2',
          status: 'confirmada'),
    ];
    final gate = Completer<void>();
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode(activities), 200);
        }
        if (request.headers['X-Usuario'] == 'p-carla') {
          return http.Response(jsonEncode(participantes), 200);
        }
        await gate.future;
        return http.Response(jsonEncode(organizacao), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pump();
    await tester.pump();
    expect(find.text('Palestra de IA'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('seletor-usuario')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Beatriz Lima (organizacao)'));
    await tester.pump();
    expect(find.text('Palestra de IA'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Palestra de IA'), findsNothing);
    expect(find.text('Minicurso Flutter'), findsOneWidget);
  });

  testWidgets('nao estoura layout em tela de 360px com convocada e contagem', (
    tester,
  ) async {
    final deadline = DateTime.now().add(const Duration(hours: 2));
    final activities = [
      _atividade('atv_1', 'Palestra de IA'),
      _atividade('atv_2', 'Minicurso Flutter'),
    ];
    final inscricoes = [
      _inscricao(
        id: 'ins_convocada',
        atividadeId: 'atv_1',
        status: 'convocada',
        convocadaAte: deadline.toIso8601String(),
      ),
      _inscricao(
        id: 'ins_espera',
        atividadeId: 'atv_2',
        status: 'em_espera',
        posicaoNaEspera: 5,
      ),
    ];
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode(activities), 200);
        }
        return http.Response(jsonEncode(inscricoes), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Restam'), findsOneWidget);
  });

  testWidgets('dispose da pagina descarta o timer da contagem', (tester) async {
    final deadline = DateTime.now().add(const Duration(minutes: 30));
    final activities = [_atividade('atv_1', 'Palestra de IA')];
    final inscricoes = [
      _inscricao(
        id: 'ins_convocada',
        atividadeId: 'atv_1',
        status: 'convocada',
        convocadaAte: deadline.toIso8601String(),
      ),
    ];
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/atividades') {
          return http.Response(jsonEncode(activities), 200);
        }
        return http.Response(jsonEncode(inscricoes), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(MaterialApp(home: InscricoesPage(client: client)));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Restam'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detalhe do participante inscreve via POST com X-Usuario e passa a mostrar cancelar', (
    tester,
  ) async {
    var inscricoesAtv = <Map<String, dynamic>>[];
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/salas') {
          return http.Response(
            jsonEncode([
              {
                'id': 'lab-3',
                'nome': 'Laboratório 3',
                'capacidade': 20,
              }
            ]),
            200,
          );
        }
        if (request.url.path == '/atividades') {
          return http.Response(
            jsonEncode([_atividade('atv_2', 'Palestra de IA')]),
            200,
          );
        }
        if (request.url.path == '/atividades/atv_2/inscricoes') {
          expect(request.method, 'POST');
          expect(request.headers['X-Usuario'], 'p-carla');
          inscricoesAtv = [
            _inscricao(
                id: 'ins_9', atividadeId: 'atv_2', status: 'confirmada'),
          ];
          return http.Response(jsonEncode(inscricoesAtv.single), 201);
        }
        return http.Response(jsonEncode(inscricoesAtv), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palestra de IA'));
    await tester.pumpAndSettle();
    expect(find.text('Inscrever'), findsOneWidget);
    await tester.tap(find.text('Inscrever'));
    await tester.pumpAndSettle();
    expect(find.text('Inscrever'), findsNothing);
    expect(find.text('Cancelar inscrição'), findsOneWidget);
    expect(find.text('confirmada'), findsOneWidget);
  });

  testWidgets('detalhe do participante confirma convocacao via POST com X-Usuario', (
    tester,
  ) async {
    final deadline = DateTime.now().add(const Duration(hours: 1));
    final conversa = <Map<String, dynamic>>[
      _inscricao(
        id: 'ins_9',
        atividadeId: 'atv_2',
        status: 'convocada',
        convocadaAte: deadline.toIso8601String(),
      ),
    ];
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/salas') {
          return http.Response(
            jsonEncode([
              {
                'id': 'lab-3',
                'nome': 'Laboratório 3',
                'capacidade': 20,
              }
            ]),
            200,
          );
        }
        if (request.url.path == '/atividades') {
          return http.Response(
            jsonEncode([_atividade('atv_2', 'Palestra de IA')]),
            200,
          );
        }
        if (request.url.path == '/inscricoes/ins_9/confirmacao') {
          expect(request.method, 'POST');
          expect(request.headers['X-Usuario'], 'p-carla');
          conversa[0]['status'] = 'confirmada';
          conversa[0]['convocadaAte'] = null;
          return http.Response(jsonEncode(conversa.single), 200);
        }
        return http.Response(jsonEncode(conversa), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palestra de IA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Convocado até'), findsOneWidget);
    await tester.tap(find.text('Confirmar convocação'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar convocação'), findsNothing);
    expect(find.text('Cancelar inscrição'), findsOneWidget);
    expect(find.text('confirmada'), findsOneWidget);
  });

  testWidgets(
    'detalhe apos cancelar e reinscrever escolhe a inscricao ativa confirmada e nao a cancelada antiga',
    (tester) async {
      final inscricoesAtv = [
        _inscricao(
          id: 'ins_antiga',
          atividadeId: 'atv_2',
          status: 'cancelada',
          criadaEm: '2026-10-18T10:00:00-03:00',
        ),
        _inscricao(
          id: 'ins_nova',
          atividadeId: 'atv_2',
          status: 'confirmada',
          criadaEm: '2026-10-19T18:00:00-03:00',
        ),
      ];
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/salas') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'lab-3',
                  'nome': 'Laboratório 3',
                  'capacidade': 20,
                }
              ]),
              200,
            );
          }
          if (request.url.path == '/atividades') {
            return http.Response(
              jsonEncode([_atividade('atv_2', 'Palestra de IA')]),
              200,
            );
          }
          return http.Response(jsonEncode(inscricoesAtv), 200);
        }),
      )..user = 'p-carla';
      await tester.pumpWidget(GradeApp(client: client));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Palestra de IA'));
      await tester.pumpAndSettle();
      expect(find.text('confirmada'), findsOneWidget);
      expect(find.text('cancelada'), findsNothing);
      expect(find.text('Cancelar inscrição'), findsOneWidget);
    },
  );

  testWidgets(
    'detalhe com apenas historicas mostra a mais recente (expirada antiga vs cancelada nova)',
    (tester) async {
      final inscricoesAtv = [
        _inscricao(
          id: 'ins_expirada',
          atividadeId: 'atv_2',
          status: 'expirada',
          criadaEm: '2026-10-18T10:00:00-03:00',
        ),
        _inscricao(
          id: 'ins_cancelada',
          atividadeId: 'atv_2',
          status: 'cancelada',
          criadaEm: '2026-10-19T18:00:00-03:00',
        ),
      ];
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/salas') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'lab-3',
                  'nome': 'Laboratório 3',
                  'capacidade': 20,
                }
              ]),
              200,
            );
          }
          if (request.url.path == '/atividades') {
            return http.Response(
              jsonEncode([_atividade('atv_2', 'Palestra de IA')]),
              200,
            );
          }
          return http.Response(jsonEncode(inscricoesAtv), 200);
        }),
      )..user = 'p-carla';
      await tester.pumpWidget(GradeApp(client: client));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Palestra de IA'));
      await tester.pumpAndSettle();
      expect(find.text('expirada'), findsNothing);
      expect(find.text('cancelada'), findsOneWidget);
    },
  );

  testWidgets(
    'detalhe de convocada permite cancelar inscricao via POST com X-Usuario',
    (tester) async {
      final deadline = DateTime.now().add(const Duration(hours: 1));
      final conversa = [
        _inscricao(
          id: 'ins_10',
          atividadeId: 'atv_2',
          status: 'convocada',
          convocadaAte: deadline.toIso8601String(),
        ),
      ];
      var cancelCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/salas') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'lab-3',
                  'nome': 'Laboratório 3',
                  'capacidade': 20,
                }
              ]),
              200,
            );
          }
          if (request.url.path == '/atividades') {
            return http.Response(
              jsonEncode([_atividade('atv_2', 'Palestra de IA')]),
              200,
            );
          }
          if (request.url.path == '/inscricoes/ins_10/cancelamento') {
            cancelCalls++;
            expect(request.method, 'POST');
            expect(request.headers['X-Usuario'], 'p-carla');
            conversa[0]['status'] = 'cancelada';
            conversa[0]['convocadaAte'] = null;
            return http.Response(jsonEncode(conversa.single), 200);
          }
          return http.Response(jsonEncode(conversa), 200);
        }),
      )..user = 'p-carla';
      await tester.pumpWidget(GradeApp(client: client));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Palestra de IA'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Convocado até'), findsOneWidget);
      await tester.tap(find.text('Cancelar inscrição'));
      await tester.pump();
      expect(cancelCalls, 1);
      await tester.pump();
      await tester.pump();
      expect(find.text('Cancelar inscrição'), findsNothing);
      expect(find.text('Confirmar convocação'), findsNothing);
      expect(find.text('cancelada'), findsOneWidget);
    },
  );

  testWidgets('detalhe M1 preserva sala, capacidade e encontros quando a consulta de inscricao falha', (
    tester,
  ) async {
    final atividade = {
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
              {
                'id': 'lab-3',
                'nome': 'Laboratório 3',
                'capacidade': 20,
              }
            ]),
            200,
          );
        }
        return http.Response(jsonEncode([atividade]), 200);
      }),
    )..user = 'p-carla';
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Laboratório 3 (20 lugares)'), findsOneWidget);
    expect(find.textContaining('2026-10-19T12:00:00Z'), findsOneWidget);
    expect(find.text('Não foi possível consultar sua inscrição.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navega para a pagina de inscricoes a partir da grade', (
    tester,
  ) async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('[]', 200)),
    )..user = 'p-carla';
    await tester.pumpWidget(GradeApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.event_note));
    await tester.pumpAndSettle();
    expect(find.text('Minhas inscrições'), findsOneWidget);
    expect(find.byType(InscricoesPage), findsOneWidget);
  });
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
  String criadaEm = '2026-10-19T18:00:00-03:00',
}) =>
    {
      'id': id,
      'atividadeId': atividadeId,
      'participanteId': 'p-carla',
      'status': status,
      'posicaoNaEspera': posicaoNaEspera,
      'convocadaAte': convocadaAte,
      'criadaEm': criadaEm,
    };