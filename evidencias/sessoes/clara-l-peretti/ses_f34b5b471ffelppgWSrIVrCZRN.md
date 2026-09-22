# M2-R23-R27: expiracao cronologica e cascatas TDD

| | |
|---|---|
| Sessão | `ses_f34b5b471ffelppgWSrIVrCZRN` |
| Pasta | Clara L Peretti/TrabalhoIA-WomanInTech |
| Período | 22/09 19:43 → 22/09 20:00 |
| Modelo | opencode/big-pickle |
| Requisições ao modelo | 75 |
| Tokens de entrada / saída | 197.257 / 72.437 |
| Skills | tdd |
| Subagentes | — |
| Execuções de teste | 15 vermelhas, 12 verdes |
| TDD | 1 ciclo(s) vermelho → verde · 9 teste(s) que já nasceram verdes · 0 vez(es) teste e código juntos |
| Arquivos editados | 17 de teste, 6 de código, 0 de entrevista, 0 de spec, 0 de contexto, 0 de auditoria |
| Alertas | — |

## Linha do tempo

- `22/09 19:43` **prompt** — "Use skill tdd. Leia AGENTS api/AGENTS contrato specs/M2 entrevista e backend/tests. Escopo SOMENTE api/lib/server.dart api/test/tempo_test.dart e unica correcao provisoria em fila_test.dart descrita abaixo. Baseline61 testes. Implemente R15 R23-R27 R31 R36 R43: expirar convocada em agora>=prazo com causa persistivel expirouConvocacao; toda leitura e mutacao deve reconciliar tempo; salto relogio …
- `22/09 19:44` carrega a skill **tdd**
- `22/09 19:44` roda `dart test 2>&1 | Select-Object -Last 30` → verde (61 passaram)
- `22/09 19:48` edita teste `api/test/tempo_test.dart`
- `22/09 19:48` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 25` → **vermelho** (0 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:48` edita código `api/lib/server.dart` (4×)
- `22/09 19:48` roda `dart test 2>&1 | Select-Object -Last 15` → **vermelho** (60 passaram, 2 falharam)
- `22/09 19:49` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 30` → **vermelho** (0 passaram, 1 falharam)
- `22/09 19:49` edita teste `api/test/tempo_test.dart`
- `22/09 19:49` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 12` → verde (1 passaram) — _teste novo já nasceu verde_
- `22/09 19:49` roda `dart test test/confirmacao_test.dart 2>&1 | Select-Object -Last 30` → **vermelho** (10 passaram, 1 falharam)
- `22/09 19:49` edita teste `api/test/tempo_test.dart`
- `22/09 19:50` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 20` → **vermelho** (1 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:50` edita código `api/lib/server.dart`
- `22/09 19:50` roda `dart test 2>&1 | Select-Object -Last 8` → verde (63 passaram) — _fecha um ciclo vermelho → verde_
- `22/09 19:50` edita teste `api/test/tempo_test.dart`
- `22/09 19:51` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 20` → **vermelho** (2 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:51` edita teste `api/test/tempo_test.dart`
- `22/09 19:51` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 20` → **vermelho** (2 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:52` edita código `api/lib/server.dart`
- `22/09 19:52` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 12` → **vermelho** (2 passaram, 1 falharam)
- `22/09 19:52` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 14` → **vermelho** (2 passaram, 1 falharam)
- `22/09 19:52` roda `dart test test/tempo_test.dart 2>&1` → **vermelho** (2 passaram, 1 falharam)
- `22/09 19:53` edita teste `api/test/tempo_test.dart`
- `22/09 19:53` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 12` → verde (3 passaram) — _teste novo já nasceu verde_
- `22/09 19:53` roda `dart test 2>&1 | Select-Object -Last 20` → **vermelho** (63 passaram, 1 falharam)
- `22/09 19:53` edita teste `api/test/fila_test.dart`
- `22/09 19:54` roda `dart test 2>&1 | Select-Object -Last 6` → verde (64 passaram) — _teste novo já nasceu verde_
- `22/09 19:54` edita teste `api/test/tempo_test.dart`
- `22/09 19:54` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 10` → **vermelho** (3 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:54` roda `dart test test/tempo_test.dart 2>&1` → **vermelho** (3 passaram, 1 falharam)
- `22/09 19:55` edita teste `api/test/tempo_test.dart`
- `22/09 19:55` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 8` → verde (4 passaram) — _teste novo já nasceu verde_
- `22/09 19:55` edita teste `api/test/tempo_test.dart`
- `22/09 19:55` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 8` → verde (5 passaram) — _teste novo já nasceu verde_
- `22/09 19:55` edita teste `api/test/tempo_test.dart`
- `22/09 19:55` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 8` → verde (6 passaram) — _teste novo já nasceu verde_
- `22/09 19:56` edita teste `api/test/tempo_test.dart`
- `22/09 19:57` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 8` → verde (7 passaram) — _teste novo já nasceu verde_
- `22/09 19:57` edita teste `api/test/tempo_test.dart`
- `22/09 19:57` roda `dart test test/tempo_test.dart 2>&1 | Select-Object -Last 10` → verde (9 passaram) — _teste novo já nasceu verde_
- `22/09 19:57` roda `dart test 2>&1 | Select-Object -Last 4` → verde (70 passaram)
- `22/09 19:58` edita teste `api/test/tempo_test.dart` (3×)
- `22/09 19:58` roda `dart test 2>&1 | Select-Object -Last 3` → **vermelho** — _teste novo falhando, como deve ser_
- `22/09 19:58` roda `dart test 2>&1 | Select-Object -Last 6` → **vermelho**
- `22/09 19:59` edita teste `api/test/tempo_test.dart`
- `22/09 19:59` roda `dart analyze 2>&1 | Select-Object -Last 3; dart test 2>&1 | Select-Object -Last…` → verde (70 passaram) — _teste novo já nasceu verde_
