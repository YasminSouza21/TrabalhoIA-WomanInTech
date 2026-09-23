# Entrevista — M3 Presenca por QR

## Rodada 1 — perguntas

As perguntas abaixo foram feitas para fechar as regras de negocio que o contrato da
API nao define. A recomendacao de cada pergunta foi aceita integralmente pela usuaria.

| # | Pergunta | Recomendacao | Decisao |
|---|---|---|---|
| P1 | A janela do QR usa cada encontro ou a atividade inteira? | Cada encontro individualmente. | Aceita |
| P2 | Quais sao os limites da janela? | Comeca 15 minutos antes e termina 15 minutos depois; limites inclusivos. | Aceita |
| P3 | Quando o QR troca? | A cada 5 minutos. | Aceita |
| P4 | O codigo anterior permanece valido apos a troca? | Nao; invalidacao imediata. | Aceita |
| P5 | Qual relogio e fuso valem? | Relogio controlado em teste e comparacao de instantes absolutos. | Aceita |
| P6 | Qual instante `lidoEm` representa? | `lidoEm` e o instante usado pelas regras; `registradaEm` e o recebimento. | Aceita |
| P7 | Qual a tolerancia de sincronizacao offline? | 10 minutos entre `lidoEm` e o relogio da API; leitura futura e invalida. | Aceita |
| P8 | Como validar QR offline? | Validar codigo e `lidoEm` contra a janela vigente no instante da leitura. | Aceita |
| P9 | Qual inscricao permite presenca? | Somente status `confirmada`. | Aceita |
| P10 | O que ocorre sem inscricao elegivel? | `403 NAO_INSCRITO`. | Aceita |
| P11 | O que ocorre com atividade cancelada ou encontro fora da janela? | Cancelada retorna `ATIVIDADE_CANCELADA`; fora da janela retorna `FORA_DA_JANELA`. | Aceita |
| P12 | Qual a precedencia dos erros? | Identificacao, papel, existencia, corpo; depois encontro, cancelamento, inscricao, sincronizacao, janela e codigo. | Aceita |
| P13 | Como funciona a duplicidade? | QR ou manual para o mesmo encontro/participante retorna `200` com a primeira presenca. | Aceita |
| P14 | Qual origem prevalece em conflito QR/manual? | A primeira presenca e preservada integralmente. | Aceita |
| P15 | Quem pode registrar manualmente? | Organizacao, mas somente para participante confirmado. | Aceita |
| P16 | Qual validacao da justificativa? | `trim` nao vazio, minimo 10 e maximo 500 caracteres. | Aceita |
| P17 | Qual limite de manuais? | 1 registro por participante/encontro por organizacao. | Aceita |
| P18 | O limite manual e compartilhado? | Sim, compartilhado entre as organizacoes. | Aceita |
| P19 | Duplicidade manual conta no limite? | Nao; a duplicidade retorna `200` com a presenca existente. | Aceita |
| P20 | Como ficam persistencia e reset? | Presencas persistem em producao; reset apaga presencas, codigos e sequencias e restaura o relogio. | Aceita |
| P21 | Retrocesso desfaz transicoes? | Nao; transicoes materializadas permanecem. | Aceita |
| P22 | Qual o escopo Flutter? | Organizacao obtem QR e lista presencas; participante registra QR; organizacao registra manualmente; todos os fluxos com loading/vazio/erro/sucesso via `ApiClient`. | Aceita |
| P23 | O que smoke e evidencias devem cobrir? | Casos felizes, erros, bordas, offline, duplicidade, limite manual, cancelamento, persistencia e reset. | Aceita |

## Rodada 2 — fechamento

Nao ha perguntas pendentes. Os defaults acima foram confirmados pela usuaria com
"aceito todos os defaults". O contrato continua sendo a fonte dos nomes de rotas,
campos, status e envelopes; esta entrevista define apenas o comportamento de M3.
