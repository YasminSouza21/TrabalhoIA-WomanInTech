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
| | **Total: 5 sessões** | 111 | grilling (2), to-spec, tdd | — | 4 / 8 | 0 | 0 | 1 | — |
