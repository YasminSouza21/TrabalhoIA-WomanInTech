# Auditoria final M1 — Dart e Flutter pós-correção

## 1. Escopo e fontes

Auditoria somente leitura do estado final do M1 Grade de atividades, após os
testes regressivos e a correção da interface para atividades canceladas.

Fontes:

- `specs/M1-grade-atividades.md`.
- `contrato-api.md`.
- `api/lib/server.dart` e testes em `api/test/`.
- `frontend/lib/main.dart`, `frontend/lib/api_client.dart` e testes em `frontend/test/`.
- `auditorias/M1-dart-flutter-final.md` e `auditorias/M1-dart-flutter-corrigida.md`, somente como histórico.
- Reauditoria independente do agente `@auditor`, somente leitura.

Nenhuma spec, entrevista, contrato ou auditoria histórica foi alterada.

## 2. Matriz atual

| Regras/área | Evidência principal | Resultado |
|---|---|---|
| R01–R04, R10–R16, R21–R27, R32–R36 | `api/test/server_test.dart`; `api/test/m1_regressao_test.dart` | COMPROVADAS |
| R06–R09 | `api/test/server_test.dart`; `api/test/m1_regressao_test.dart` | COMPROVADAS no comportamento; origem de algumas regras é somente contratual |
| R18–R20 | `api/test/server_test.dart:163-190,434-458`; `api/test/m1_regressao_test.dart` | COMPROVADAS, incluindo duração de 1h/4h e sobreposição |
| R28–R31 | `api/test/fila_test.dart` | DEPENDÊNCIA M2 para estados de inscrição e convocação; não é lacuna de implementação M1 |
| R37–R43 | `api/test/server_test.dart`; `api/test/m1_regressao_test.dart` | COMPROVADAS, incluindo cancelamento definitivo e borda no início |
| R44–R48, R56–R59 | `api/test/server_test.dart`; `api/test/m1_regressao_test.dart` | COMPROVADAS nas bordas do relógio e do período |
| R49–R55 | `api/test/server_test.dart` | COMPROVADAS: ordenação, canceladas, detalhe e filtros combinados |
| R60 | `api/test/server_test.dart`; testes M2 integrados | COMPROVADA para exposição dos campos calculados no estado vazio e consumo M2 |
| Papéis e ações Flutter | `frontend/lib/main.dart`; `frontend/test/widget_test.dart:111-156`; `frontend/test/api_client_test.dart` | COMPROVADOS; participante não recebe ações de organização e cancelada não recebe editar/cancelar |
| Salas, detalhe, carga e encontros Flutter | `frontend/test/widget_test.dart:45-74` | COMPROVADOS |

## 3. Regressões adicionadas

`api/test/m1_regressao_test.dart` cobre, sem alterar testes existentes:

- autenticação em todas as rotas M1 identificadas;
- participante versus organização e ID inexistente no cancelamento;
- duração mínima e máxima para palestra e minicurso;
- `vagas` zero, negativa e não inteira como `DADOS_INVALIDOS`, sem inventar código;
- cancelamento exatamente no início do primeiro encontro;
- status `200` explícito no PATCH válido.

`frontend/test/widget_test.dart` cobre que atividade cancelada não oferece editar
nem cancelar. `frontend/lib/main.dart` aplica a mesma regra visual.

## 4. Achados e limites

- Não restou pendência real de implementação M1 identificada pela reauditoria.
- R28–R31 e cancelamento de inscrições ativas dependem dos estados e fluxos do
  M2; não foram reimplementados nem usados como critério extra do M1.
- Presença e certificados de atividade cancelada pertencem a M3/M4.
- N01–N10 permanecem regras não especificadas, incluindo tipo/dia inválidos,
  faixa horária diária, restrição de sala por tipo, bloqueio geral após início,
  precedência entre erros e código específico para `vagas < 1`; nenhum
  comportamento novo foi inventado.
- Algumas regras têm origem apenas no contrato, portanto a rastreabilidade de
  entrevista não pode ser ampliada sem alterar artefatos preservados.
- `flutter build web --release` permanece bloqueado pelo cache local incompleto,
  sem `dart2wasm_product.snapshot` e `dart2js_aot.dart.snapshot`.

## 5. Validação

- `api`: `dart test` — **108 testes aprovados**.
- `api`: `dart analyze` — **sem problemas**.
- `frontend`: `flutter test` — **51 testes aprovados**.
- `frontend`: `flutter analyze` — **sem problemas**.
- `api`: `dart run tool/smoke_m2.dart` — **16 cenários OK**.
- `api`: `dart run tool/smoke_m3.dart` — **OK**.
- `git diff --check` — **OK**.
- Build web — **BLOQUEADO pelo SDK/cache local**, conforme limitação acima.

## 6. Veredito

**PASSOU COM LIMITAÇÕES AMBIENTAIS E DE ESCOPO.**

O M1 implementável e especificado está coberto no estado atual. As pendências
abertas são justificadas por dependências M2+/M3/M4, ausência de especificação
ou bloqueio ambiental do build web, não por falha funcional M1 comprovada.
