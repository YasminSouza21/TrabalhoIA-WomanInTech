# M2-R07-R18: inscricao e lista de espera em TDD

| | |
|---|---|
| Sessão | `ses_f34d1018dffeoOVd6aBW1KfU2B` |
| Pasta | Clara L Peretti/TrabalhoIA-WomanInTech |
| Período | 22/09 19:14 → 22/09 19:20 |
| Modelo | opencode/big-pickle |
| Requisições ao modelo | 34 |
| Tokens de entrada / saída | 55.592 / 25.226 |
| Skills | tdd |
| Subagentes | — |
| Execuções de teste | 2 vermelhas, 8 verdes |
| TDD | 1 ciclo(s) vermelho → verde · 5 teste(s) que já nasceram verdes · 0 vez(es) teste e código juntos |
| Arquivos editados | 7 de teste, 4 de código, 0 de entrevista, 0 de spec, 0 de contexto, 0 de auditoria |
| Alertas | — |

## Linha do tempo

- `22/09 19:14` **prompt** — "Use tdd. Implemente fatia 2 de specs/M2-inscricoes.md em api: inscricao confirmada quando vaga disponivel, em_espera quando lota, FIFO insercao empatando relogio, posicao derivada nao armazenada, id unico ins_8hex e JSON exato, duplicidade ativa, encerramento inclusive borda e atividade cancelada, listagem/detalhe isolados todos registros e filtro atividadeId. R07-R18 R37-R39 R42-R43. Continue t…
- `22/09 19:14` carrega a skill **tdd**
- `22/09 19:15` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (27 passaram)
- `22/09 19:16` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:16` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → **vermelho** (5 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:16` edita código `api/lib/server.dart` (4×)
- `22/09 19:16` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (28 passaram) — _fecha um ciclo vermelho → verde_
- `22/09 19:16` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:16` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → **vermelho** (6 passaram, 1 falharam) — _teste novo falhando, como deve ser_
- `22/09 19:16` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:16` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (29 passaram) — _teste novo já nasceu verde_
- `22/09 19:16` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:17` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (9 passaram) — _teste novo já nasceu verde_
- `22/09 19:17` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:17` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (10 passaram) — _teste novo já nasceu verde_
- `22/09 19:17` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:17` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (11 passaram) — _teste novo já nasceu verde_
- `22/09 19:18` edita teste `api/test/inscricoes_test.dart`
- `22/09 19:18` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (14 passaram) — _teste novo já nasceu verde_
- `22/09 19:18` roda `& "C:\Users\Clara L Peretti\TrabalhoIA-WomanInTech\.tools\flutter\bin\cache\dar…` → verde (36 passaram)
