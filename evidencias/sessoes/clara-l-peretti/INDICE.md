# Sessões — Clara L Peretti

Cada execução de teste é lida pelo que mudou desde a anterior:

- **Ciclo** — vermelho logo depois de mexer só em teste, e depois verde logo depois de mexer só em código. É o TDD.
- **Nasceu verde** — verde logo depois de mexer só em teste. Ou o comportamento já existia, ou o teste não testa o que diz.
- **Juntos** — teste e código mudaram antes da mesma execução. Não houve vermelho para ver.

**Alertas:** *colou* = prompt com 10 palavras seguidas ou mais iguais às do documento de requisitos (só aparece quando o resumo é gerado com `--requisitos`); *leu* = o agente acessou um arquivo de requisitos; *anexou* = o documento foi anexado à conversa.

Requisições são chamadas ao modelo: cada passo do agente é uma. Skills contam tanto a ferramenta `skill` quanto o comando `/nome`.

| Início | Sessão | Requisições | Skills | Subagentes | Vermelhas / verdes | Ciclos | Nasceu verde | Juntos | Alertas |
|---|---|---|---|---|---|---|---|---|---|
| 22/09 18:31 | [M2: rodada 1 de levantamento de inscricoes](ses_f34f80f66ffeyg6tcIUDSeyrgx.md) | 6 | grilling | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 18:40 | [M2: rodada 2 com decisoes delegadas](ses_f34efee55ffe0LgrL7M8dahs1N.md) | 11 | grilling | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 18:41 | [M2: preparar SDK Flutter e Dart](ses_f34eeacc4ffewc4E5GSwOBK35P.md) | 15 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 18:44 | [M2: especificacao verificavel com to-spec](ses_f34ebd369ffeoM2iZjnIgy2W0y.md) | 3 | to-spec | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 18:53 | [M2: spec concisa to-spec](ses_f34e3f8adffejmAHMh4juOmml2.md) | 8 | to-spec | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 18:56 | [M2: completar spec e preparar TDD Dart Flutter](ses_f34e17a13ffefEt45OFkI5chzp.md) | 22 | to-spec, tdd | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 18:57 | [M2-R01-R06: fundacoes HTTP em TDD](ses_f34e078c6ffeNM88OxV45BEnwO.md) | 39 | tdd | — | 2 / 7 | 1 | 4 | 0 | — |
| 22/09 19:00 | [M2-R42-R45: ApiClient Flutter em TDD](ses_f34dd2c4dffesf0nC1Z2FWAXsG.md) | 44 | tdd | — | 6 / 10 | 6 | 2 | 0 | — |
| 22/09 19:14 | [M2-R07-R18: inscricao e lista de espera em TDD](ses_f34d1018dffeoOVd6aBW1KfU2B.md) | 34 | tdd | — | 2 / 8 | 1 | 5 | 0 | — |
| 22/09 19:15 | [M2: skill de telas Flutter e revisor de contrato](ses_f34d01be0ffedZ2VVyGpAq6Wis.md) | 26 | customize-opencode, novo-subagente | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 19:17 | [M2-R44-R45: telas de inscricoes Flutter em TDD](ses_f34cdf268ffeLc2yygd4xs6nZg.md) | 71 | telas-flutter, tdd | — | 13 / 11 | 5 | 4 | 0 | — |
| 22/09 19:21 | [M2-R14-R21-R33-R36: cancelamento e promocao FIFO](ses_f34ca806fffeQawnQaU62vVQa4.md) | 73 | tdd | — | 14 / 17 | 6 | 9 | 0 | — |
| 22/09 19:27 | [M2: identificar responsavel na equipe](ses_f34c4f930ffenANpSVuRBSMDHO.md) | 4 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 19:30 | [M2: corrigir reconhecimento de evidencias Windows](ses_f34c19e88ffeW56S7IVEBLSz2B.md) | 7 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 19:33 | [M2-R20-R32: confirmacao conflitos e limite em TDD](ses_f34bf3c0fffebazGwKwY4R7mQT.md) | 27 | tdd | — | 2 / 2 | 1 | 0 | 0 | — |
| 22/09 19:34 | [M2: compatibilidade Windows do exportador de testes](ses_f34be9965ffeFam4Jmur164LLb.md) | 19 | — | — | 1 / 1 | 1 | 0 | 0 | — |
| 22/09 19:37 | [M2: consistencia da interface ao trocar usuario](ses_f34bba3c0ffejWUkpKLk1tIIR6.md) | 59 | tdd, telas-flutter | — | 11 / 3 | 0 | 1 | 0 | — |
| 22/09 19:39 | [M2: evitar falsos vermelhos no indice de evidencias](ses_f34b9e535ffed3QwMzWLqsv0ll.md) | 10 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 19:42 | [M2: finalizar regressao do exportador](ses_f34b70c03ffe3FE5m3kgoYpCC1.md) | 12 | — | — | 1 / 1 | 1 | 0 | 0 | — |
| 22/09 19:43 | [M2-R23-R27: expiracao cronologica e cascatas TDD](ses_f34b5b471ffelppgWSrIVrCZRN.md) | 75 | tdd | — | 15 / 12 | 1 | 9 | 0 | — |
| 22/09 19:45 | [M2: preparar smoke HTTP reproduzivel](ses_f34b45756ffevh5f69Kone4qC7.md) | 20 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 19:56 | [M2: validar build Flutter web release](ses_f34aaa9b6ffe3vSDJ3NFHZRSQb.md) | 4 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 20:00 | [M2-R40-R41: persistencia JSON e relogio real TDD](ses_f34a66b47ffeyyjh1Hb8RiM51I.md) | 41 | tdd | — | 1 / 5 | 1 | 2 | 0 | — |
| 22/09 20:01 | [M2: executar smoke HTTP das cinco rotas](ses_f34a5f946ffeJRwTS2u8ojp56H.md) | 8 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 20:02 | [M2: reinscricao no detalhe e cancelamento de convocada](ses_f34a44d17ffe5k93JEpAts6N0A.md) | 23 | tdd, telas-flutter | — | 1 / 2 | 1 | 0 | 0 | — |
| 22/09 20:11 | [M2-R40: gravacao concorrente sem perder estado](ses_f349ca796ffeYYbrhq4YiTr4xw.md) | 25 | tdd | — | 2 / 4 | 1 | 0 | 0 | — |
| 22/09 20:11 | [M2: instrucoes de execucao e entrega](ses_f349c1ddcffeCZIEQurE7OpPkJ.md) | 14 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 20:16 | [M2: auditoria final somente leitura](ses_f3497c89fffeilRD6mvqyNlcB2.md) | 5 | — | auditor | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 20:19 | [M2: registro de entrega e commits](ses_f349582bcffeH5nEpPseCy8TD9.md) | 15 | — | — | 2 / 2 | 0 | 0 | 0 | — |
| | **Total: 29 sessões** | 720 | grilling (2), to-spec (3), tdd (12), customize-opencode, novo-subagente, telas-flutter (3) | auditor | 73 / 85 | 26 | 36 | 0 | — |
