# Sessões — YasminSouza21

Cada execução de teste é lida pelo que mudou desde a anterior:

- **Ciclo** — vermelho logo depois de mexer só em teste, e depois verde logo depois de mexer só em código. É o TDD.
- **Nasceu verde** — verde logo depois de mexer só em teste. Ou o comportamento já existia, ou o teste não testa o que diz.
- **Juntos** — teste e código mudaram antes da mesma execução. Não houve vermelho para ver.

**Alertas:** *colou* = prompt com 10 palavras seguidas ou mais iguais às do documento de requisitos (só aparece quando o resumo é gerado com `--requisitos`); *leu* = o agente acessou um arquivo de requisitos; *anexou* = o documento foi anexado à conversa.

Requisições são chamadas ao modelo: cada passo do agente é uma. Skills contam tanto a ferramenta `skill` quanto o comando `/nome`.

| Início | Sessão | Requisições | Skills | Subagentes | Vermelhas / verdes | Ciclos | Nasceu verde | Juntos | Alertas |
|---|---|---|---|---|---|---|---|---|---|
| 19/09 19:12 | [Análise inicial e requisitos do Marco 1 em Go](ses_f44454556ffenD5ir1G15EWtyW.md) | 39 | grilling | — | 0 / 2 | 0 | 0 | 1 | — |
| 19/09 19:52 | [Rodada 2 do M1: Grade de Atividades](ses_f442087b9ffephBjXWFQ4Sj5hM.md) | 26 | grilling | — | 0 / 0 | 0 | 0 | 0 | — |
| 21/09 23:43 | [Verificação de rastreabilidade M1 Rodada 2](ses_f39009e72ffePa1iCYmX6DP4p4.md) | 2 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 21/09 23:45 | [Criar spec formal do M1 grade de atividades](ses_f38ff03c4ffeSgCXrMAJBQYekK.md) | 12 | to-spec | — | 0 / 0 | 0 | 0 | 0 | — |
| 21/09 23:48 | [Implementação TDD do M1 Grade de Atividades](ses_f38fbc23dffe7p1lwmEVGYXe0e.md) | 32 | tdd | — | 4 / 6 | 0 | 0 | 0 | — |
| 21/09 23:56 | [Auditoria formal do módulo M1 — Grade de Atividades](ses_f38f4949effeMH4U268gEv13a2.md) | 11 | — | auditor | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 00:13 | [Correção TDD para rejeitar JSON extra em atividades](ses_f38e4e25fffeSovqi8CuDkig5k.md) | 19 | — | — | 2 / 3 | 0 | 0 | 0 | — |
| 22/09 00:16 | [Restaurar linha original de M1 em EQUIPE.md](ses_f38e23ff3ffe2wolkCb2kbRKaw.md) | 4 | — | — | 0 / 0 | 0 | 0 | 0 | — |
| 22/09 00:18 | [Auditoria pós-correção do M1 — Grade de Atividades](ses_f38e0c288ffeDitumIH6beGSrE.md) | 10 | — | auditor | 0 / 1 | 0 | 0 | 0 | — |
| 22/09 06:54 | [Fechamento de lacunas da auditoria backend M1](ses_f377669ccffefG3qjwSh41RyKu.md) | 25 | tdd | — | 0 / 11 | 0 | 0 | 0 | — |
| 22/09 06:59 | [Migração do backend Go para Dart e frontend Flutter web](ses_f3771c42dffed4lZdlkUWFnb4B.md) | 56 | tdd | — | 7 / 9 | 0 | 0 | 0 | — |
| 22/09 07:48 | [Auditoria final do Módulo 1 em Dart e Flutter](ses_f37448d0bffeasRT1Cf8TIJxMA.md) | 10 | — | auditor | 0 / 2 | 0 | 0 | 0 | — |
| 22/09 07:56 | [Correção completa do Módulo 1 Dart/Flutter](ses_f373d903fffecpVnrKTRcQ5sQV.md) | 28 | tdd | auditor (2) | 1 / 6 | 0 | 0 | 0 | — |
| 22/09 20:57 | [Auditoria do Módulo 2: Inscrições e Lista de Espera](ses_f34725ab5ffe7WJthhXz5Dhsip.md) | 17 | — | auditor (2) | 0 / 2 | 0 | 0 | 0 | — |
| 22/09 21:11 | [Entrevista M3: perguntas sobre QR, presença e integrações](ses_f3465c1f2ffemfPF8NB2zix838.md) | 59 | grilling, to-spec, tdd | — | 4 / 12 | 0 | 0 | 0 | — |
| | **Total: 15 sessões** | 350 | grilling (3), to-spec (2), tdd (5) | auditor (7) | 18 / 54 | 0 | 0 | 1 | — |
