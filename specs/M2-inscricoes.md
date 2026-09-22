# Spec — M2 Inscrições e Lista de Espera

## 1. Objetivo
Permite que participantes se inscrevam em atividades da Semana Acadêmica 2026, entrem na lista de espera quando lotadas, sejam convocados automaticamente quando uma vaga abrir e confirmem a convocação dentro de um prazo. Participantes e organização consultam inscrições; apenas participantes mutam as próprias. Integra a entrega uma interface mínima Flutter — "Minhas inscrições" (participante) e consulta da organização — com inscrever/cancelar no detalhe, confirmação de convocação e estados de carregamento, vazio, erro e sucesso via `ApiClient` (R44, R45).

Nota de rastreabilidade: as decisões da Rodada 2 (P-01 a P-29) foram escolhidas por delegação expressa da usuária em 22/09/2026, com base no `contrato-api.md` e na spec do M1; **não foram conferidas contra requisitos externos do professor**. Valem como contrato local até verificação externa.

## 2. Fora de escopo
- Presença (M3), certificados e extrato (M4) e painel da organização (M5) não são implementados pelo M2.
- `INSCRICAO_BLOQUEADA` (M5) não é aplicada no M2. Origem: P-18.
- A interface mínima Flutter é parte da entrega do M2 (R44, R45); nesta rodada, apenas de entrevista, ela foi registrada sem implementação — não é exclusão permanente. Origem: P-34.
- P-35 (higiene de repositório, `.tools/` no `.gitignore`) não é regra de API.
- O relógio real (sem `MODO_TESTE`) não é controlado pelas rotas `/_teste/*`.

## 3. Modelo
Entidade `Inscricao` (campo — origem):
- `id`: gerado, prefixo `ins_` + 8 hexadecimais minúsculos (F-04).
- `atividadeId`: referência a atividade existente (F-04).
- `participanteId`: referência a usuário participante (F-04).
- `status`: `confirmada | em_espera | convocada | cancelada | expirada` (F-05).
- `posicaoNaEspera`: número só quando `em_espera`; derivado e compacto, nunca gravado como histórico (P-08).
- `convocadaAte`: instante só quando `convocada` (F-04).
- `criadaEm`: instante de criação (F-04).

Nenhum dos dados iniciais inclui inscrição (F-15). A ordem de inserção é persistida por uma sequência monotônica gravada na criação da inscrição (P-07, P-30).

No M2, os campos calculados da `Atividade` — `ocupadas`, `vagasRestantes` e `emEspera` — são derivados das inscrições do M2 conforme R43.

## 4. Endpoints
- `POST /atividades/:id/inscricoes` — participante; sem corpo na entrada; sucesso `201 Inscricao` (F-01).
- `POST /inscricoes/:id/cancelamento` — participante; sucesso `200 Inscricao` (F-02).
- `POST /inscricoes/:id/confirmacao` — participante; sucesso `200 Inscricao` (F-02).
- `GET /inscricoes` — todos identificados; participante vê só as próprias; filtro `?atividadeId=` (F-03).
- `GET /inscricoes/:id` — todos identificados; `200 Inscricao` (F-03).

## 5. Regras
- R01. Toda rota do M2 exige `X-Usuario`; sem cabeçalho ou id inexistente → `401 USUARIO_DESCONHECIDO` primeiro. Origem: P-36 (adoção do contrato) / F-06.
- R02. Rotas de participante (inscrever, cancelar, confirmar) recusam organização → `403 SOMENTE_PARTICIPANTE`. Origem: P-36 (adoção do contrato) / F-08.
- R03. Atividade ou inscrição inexistente → `404 NAO_ENCONTRADO` antes das regras do recurso. Origem: P-36 (adoção do contrato) / F-09.
- R04. Corpo ausente/vazio é aceito nas três rotas de mutação; JSON objeto bem formado é ignorado; JSON malformado ou raiz não-objeto → `422 DADOS_INVALIDOS`. Origem: P-27.
- R05. Ordem das verificações: identificação (401) → perfil (403) → existência (404) → corpo (422) → regras do recurso. Origem: P-36 (adoção do contrato) / F-07.
- R06. `POST /_teste/reset` recarrega dados iniciais sem nenhuma inscrição. Origem: F-15 / P-31.
- R07. Ao inscrever, há vaga disponível → `confirmada`; sem vaga → `em_espera` no fim da fila FIFO. `201 Inscricao`. Origem: P-33.
- R08. Inscrições encerram no início do primeiro encontro; `agora >= inicio` → `422 INSCRICOES_ENCERRADAS`. Origem: P-01.
- R09. Atividade iniciada ou encerrada (não cancelada) → `422 INSCRICOES_ENCERRADAS`; `ATIVIDADE_CANCELADA` só para atividade cancelada. Origem: P-02.
- R10. Inscrever em atividade cancelada → `422 ATIVIDADE_CANCELADA`. Origem: F-12 / P-02.
- R11. `agora == inicio` do primeiro encontro já é `INSCRICOES_ENCERRADAS` (borda inclusiva). Origem: P-03.
- R12. Precedência ao inscrever: `ATIVIDADE_CANCELADA` → `INSCRICOES_ENCERRADAS` → `JA_INSCRITO` → `CONFLITO_DE_HORARIO` → `LIMITE_DE_MINICURSOS`. Origem: P-18.
- R13. `JA_INSCRITO` (409) para `confirmada`, `em_espera` e `convocada`; `cancelada` e `expirada` liberam nova inscrição. Origem: P-23.
- R14. Reinscrição após cancelamento: nova `Inscricao`, novo `id`, fim da fila; nunca reconvoca o registro antigo. Origem: P-21.
- R15. Reinscrição após expirar: como participante novo, fim da fila, sem privilégio ou punição; nunca reconvoca o registro antigo. Origem: P-22.
- R16. A espera é FIFO estrita pela ordem de inserção persistida. Origem: P-06.
- R17. Empate desfeito pela sequência monotônica gravada na criação; nunca por `id` aleatório. Origem: P-07.
- R18. Posições são derivadas e compactas: quem sai da espera faz os demais subirem, re-enumerados de 1 em FIFO. Origem: P-08.
- R19. Toda abertura de vaga convoca automaticamente — cancelamento, expiração ou aumento de vagas — sempre em FIFO. Origem: P-09 / F-18.
- R20. Convocar é FIFO, sem pular; conflito de horário e limite de minicursos são revalidados na confirmação; se falhar, a convocação é preservada até `convocadaAte` e só então o próximo da fila é convocado. Origem: P-10.
- R21. `convocadaAte` = instante da convocação + 24 horas, limitado ao início do primeiro encontro. Origem: P-04.
- R22. `agora >= convocadaAte` → `422 CONVOCACAO_EXPIRADA` (borda inclusiva). Origem: P-05.
- R23. Expiração é processada a cada leitura, cronologicamente, inclusive cascatas ocorridas sem requisições; relógio de teste e leituras veem o resultado atualizado. Origem: P-11.
- R24. Expirada libera a vaga e convoca o próximo da fila usando o instante do vencimento anterior como instante de convocação; o expirado não mantém fila nem vaga. Origem: P-12.
- R25. Salto do relógio para frente reprocessa a cadeia completa de vencimentos/convocações até o instante final, deterministicamente; novas convocações param no início do primeiro encontro. Origem: P-13.
- R26. No início do primeiro encontro, convocadas vencidas expiram, a fila `em_espera` encerra como `expirada`, `confirmada` é preservada e novas convocações cessam. Origem: P-32.
- R27. O juiz de teste só avança o relógio; retrocesso não desfaz transições históricas já materializadas por leitura; cancelamentos permanecem. Origem: P-14 / P-29.
- R28. `CONFLITO_DE_HORARIO`: só inscrições `confirmadas` contam; na confirmação, excluir a própria inscrição da verificação. Origem: P-15.
- R29. Conflito existe quando qualquer encontro sobrepõe em `[inicio, fim)` (início inclusivo, fim exclusivo), independente da sala; terminar 10h e começar 10h é permitido; o intervalo mínimo de 15 minutos do conflito de sala do M1 não se aplica. Origem: P-16.
- R30. `LIMITE_DE_MINICURSOS`: máximo de 2 minicursos `confirmados` por participante por evento; `em_espera` e `convocada` não contam; validado ao inscrever e ao confirmar, excluindo a própria inscrição. Origem: P-17.
- R31. Confirmar convocação, em ordem: `CONVOCACAO_EXPIRADA` → `SEM_CONVOCACAO` → `CONFLITO_DE_HORARIO` → `LIMITE_DE_MINICURSOS`. Uma inscrição cuja convocação venceu pelo relógio — inclusive a materializada como `expirada` por vencimento em leitura anterior (P-29) — retorna `CONVOCACAO_EXPIRADA` antes da checagem de `SEM_CONVOCACAO`; apenas demais inscrições sem convocação ativa (`confirmada`, `em_espera`, `cancelada`, `expirada` por outro caminho) retornam `SEM_CONVOCACAO`; conflito e limite vêm depois. Origem: P-20.
- R32. Confirmar inscrição sem convocação ativa → `422 SEM_CONVOCACAO`. Origem: P-36 (adoção do contrato) / contrato-api.md.
- R33. Cancelar inscrição, em ordem: `ATIVIDADE_JA_INICIADA` → `INSCRICAO_INATIVA`; não existe `ATIVIDADE_CANCELADA` nesta rota (o cancelamento da atividade já converteu as ativas em `cancelada`). Sucesso `200 Inscricao`. Origem: P-19.
- R34. Cancelar inscrição de atividade já iniciada → `422 ATIVIDADE_JA_INICIADA`. Origem: P-36 (adoção do contrato) / F-13.
- R35. Cancelar inscrição já `cancelada` ou `expirada` → `422 INSCRICAO_INATIVA`. Origem: contrato-api.md / P-19.
- R36. No cancelamento da atividade, `confirmada`, `convocada` e `em_espera` viram `cancelada` com `posicaoNaEspera` e `convocadaAte` limpos; `expirada` é preservada; a fila é esvaziada. Origem: P-24 / F-19.
- R37. Participante só consulta/cancela/confirma as próprias; inscrição alheia → `404 NAO_ENCONTRADO`; organização consulta todas, mas não muta (`403 SOMENTE_PARTICIPANTE`). Origem: P-25.
- R38. `GET /inscricoes` inclui todos os status, inclusive `cancelada` e `expirada`; `?atividadeId=` mantém o isolamento e valor sem inscrições → lista vazia; organização vê todas. Origem: P-26.
- R39. `GET /inscricoes` retorna na ordem de inserção persistida, ascendente. Origem: P-28.
- R40. Sem `MODO_TESTE`, o estado M1/M2 e a sequência de ordem de inserção são persistidos em arquivo JSON local, sem serviços externos. Origem: P-30.
- R41. Com `MODO_TESTE=1`, o estado fica em memória isolada (não toca o arquivo de persistência); `POST /_teste/reset` apaga tudo e recarrega os dados iniciais; o relógio é controlado por `PUT/GET /_teste/relogio`. Origem: P-31.
- R42. `Inscricao` segue o modelo exato do contrato: `id` com prefixo `ins_` + 8 hexadecimais minúsculos; campos `atividadeId`, `participanteId`, `status`, `posicaoNaEspera`, `convocadaAte` e `criadaEm` nos tipos do contrato; `posicaoNaEspera` nulo exceto quando status `em_espera`; `convocadaAte` nulo exceto quando status `convocada`; erro sempre no envelope `{"erro","mensagem"}`. Origem: P-36 / F-04 / F-05 / contrato-api.md.
- R43. Os campos calculados da `Atividade` refletem o estado das inscrições do M2: `ocupadas` conta inscrições `confirmadas` e `convocadas`; `emEspera` conta inscrições `em_espera`; `vagasRestantes` = `vagas` − `ocupadas`. Origem: P-36 / F-16 / F-17 / M1 R60.
- R44. Interface mínima Flutter faz parte da entrega do M2, consumindo a API exclusivamente via `ApiClient`: participante vê "Minhas inscrições" com todas as próprias inscrições (todos os status), organização consulta todas; no detalhe da atividade o participante inscreve e cancela a própria inscrição; convocação é confirmável com exibição de status, posição na espera, prazo de convocação e contagem regressiva; a tela distingue carregamento, vazio, erro e sucesso. Origem: P-34.
- R45. A interface mínima é verificada por testes de `ApiClient` e de widget (`flutter_test`) com transporte HTTP fake (`MockClient`, `package:http/testing`), sem replicar regras de domínio no frontend; as regras de negócio continuam verificadas pela costura HTTP da API. Origem: P-34.

## 6. Critérios de aceite
1. (R01, R05) `GET /inscricoes` sem `X-Usuario` ou com id inexistente → `401 USUARIO_DESCONHECIDO`.
2. (R02, R05) `POST /atividades/:id/inscricoes` com usuário organização → `403 SOMENTE_PARTICIPANTE`.
3. (R03, R05) Inscrição ou atividade inexistente → `404 NAO_ENCONTRADO`.
4. (R04) Corpo ausente/vazio aceito nas três rotas; corpo `{}` ignorado; corpo com raiz não-objeto → `422 DADOS_INVALIDOS`.
5. (R06, R41) `POST /_teste/reset` → 204 e `GET /inscricoes` do participante → `200 []`.
6. (R07, R13) Inscrever com vaga → 201 `confirmada`; sem vaga → 201 `em_espera`; repetir com `confirmada`/`em_espera`/`convocada` → `409 JA_INSCRITO`.
7. (R08, R09, R10, R11) `agora >= inicio` (inclusive `==`) → `INSCRICOES_ENCERRADAS`; atividade cancelada → `ATIVIDADE_CANCELADA`.
8. (R12, R13) Atividade cancelada e com duplicidade simultâneas → `ATIVIDADE_CANCELADA` primeiro.
9. (R14, R15) Após `cancelada` ou `expirada`, reinscrever → nova `201 Inscricao` no fim da fila, novo `id`.
10. (R16, R17, R18) Três inscritos em atividade lotada → posições 1, 2, 3 na ordem de inserção; saída da fila renumera os demais de 1; empate desfeito pela sequência gravada.
11. (R19, R24) Cancelar `confirmada` ou expirar `convocada` libera vaga e convoca o primeiro da fila FIFO.
12. (R20) Convocado que falhar conflito/limite na confirmação permanece `convocada` até `convocadaAte`; após vencer, o próximo é convocado.
13. (R21, R22) Confirmar antes de `convocadaAte` → 200 `confirmada`; exatamente em `convocadaAte` → `CONVOCACAO_EXPIRADA`.
14. (R23, R25, R26) Salto do relógio sem requisições reprocessa a cadeia em cascata; no início do primeiro encontro `em_espera` → `expirada`, convocadas vencidas expiram, `confirmada` preservada, novas convocações cessam.
15. (R27) Retrocesso do relógio não desfaz expiração já observada por leitura.
16. (R28, R29) Inscrição de atividade com encontro sobreposto em `[inicio, fim)` a atividade já `confirmada` → `409 CONFLITO_DE_HORARIO`; fim 10h + início 10h é permitido; conflito indepente de sala e sem intervalo mínimo de 15 min.
17. (R30) Terceiro minicurso `confirmado` → `422 LIMITE_DE_MINICURSOS` ao inscrever e ao confirmar; `em_espera`/`convocada` não contam.
18. (R31, R32) Confirmar sem convocação ativa (`confirmada`, `em_espera`, `cancelada`, `expirada` por outro caminho) → `SEM_CONVOCACAO`; convocada vencida pelo relógio, inclusive já materializada como `expirada` por vencimento (P-29), → `CONVOCACAO_EXPIRADA` antes de `SEM_CONVOCACAO`.
19. (R33, R34, R35) Cancelar inscrição de atividade já iniciada → `ATIVIDADE_JA_INICIADA`; de inscrição já `cancelada`/`expirada` → `INSCRICAO_INATIVA`.
20. (R36) Cancelar a atividade converte ativas em `cancelada` com `posicaoNaEspera`/`convocadaAte` nulos; `expirada` preservada; novas inscrições bloqueadas.
21. (R37) Participante em inscrição alheia (consulta/cancelamento/confirmação) → `404 NAO_ENCONTRADO`; organização em cancelamento/confirmação → `403 SOMENTE_PARTICIPANTE`; organização vê todas.
22. (R38) `GET /inscricoes` mostra `cancelada`/`expirada`; `?atividadeId=` sem inscrições → `200 []`.
23. (R39) `GET /inscricoes` ordena pela ordem de inserção, ascendente.
24. (R40) Sem `MODO_TESTE`, inscrições sobrevivem a reinício via arquivo JSON local, sem serviço externo.
25. (R42) Toda `Inscricao` retornada tem `id` no formato `ins_` + 8 hexadecimais minúsculos e os campos exatos do contrato; `posicaoNaEspera` e `convocadaAte` nulos quando não se aplicam; erro no envelope `{"erro","mensagem"}`.
26. (R43) Com inscrições do M2 presentes, `Atividade.ocupadas` conta `confirmada` + `convocada`, `emEspera` conta `em_espera` e `vagasRestantes` = `vagas` − `ocupadas`.
27. (R44, R45) Teste de widget com HTTP fake: "Minhas inscrições" exibe todos os status com posição/prazo/contagem regressiva, e os estados de carregamento, vazio, erro e sucesso; inscrever/cancelar/confirmar chamam as rotas certas via `ApiClient`.
28. (R45) Teste de `ApiClient` com `MockClient` cobre consultas e mutações do M2 (inscrever, cancelar, confirmar, listar) com `X-Usuario`, sem HTTP real.

## 7. Como isto será verificado
Pela interface HTTP de `contrato-api.md` via servidor, com `MODO_TESTE=1`: `POST /_teste/reset` zera o estado e `PUT/GET /_teste/relogio` controlam o tempo para as regras temporais (P-11, P-13, P-27). É a costura mais externa existente; cobre autenticação, perfil, contrato de JSON, status HTTP, códigos de erro, fila, convocação e cascatas observáveis pelo cliente.

A interface mínima (R44, R45) é verificada no frontend por testes de `ApiClient` e de widget com `flutter_test`, usando transporte HTTP injetado (`MockClient` de `package:http/testing`) — nunca HTTP real — e sem replicar regras de domínio: os estados exibidos são os que a API calcula.

## 8. Fatias de entrega (TDD)
1. **Fundações**: identificação, perfil, existência, corpo e ordem de verificações; reset e dados iniciais; `GET /inscricoes` isolado e ordenado. Regras: R01–R06, R37–R39.
2. **Inscrição**: status inicial `confirmada`/`em_espera`, `JA_INSCRITO`, reinscrição, encerramento, borda e precedência. Regras: R07–R15.
3. **Fila**: FIFO, desempate por sequência, posições compactas e convocação automática em toda abertura de vaga. Regras: R16–R19.
4. **Convocação e confirmação**: janela de 24h, borda de expiração, `SEM_CONVOCACAO`/`CONVOCACAO_EXPIRADA`, conflito e limite na confirmação, precedência. Regras: R20–R22, R28–R32.
5. **Cascatas temporais**: expiração sob demanda, efeito sobre vaga/fila, salto para frente, início do primeiro encontro e retrocesso. Regras: R23–R27.
6. **Cancelamentos e persistência**: cancelar inscrição, cancelamento da atividade, isolamento completo, persistência JSON e memória isolada do modo de teste. Regras: R33–R36, R40–R41.
7. **Interface mínima (P-34)**: `ApiClient` do M2 e telas "Minhas inscrições" organizacional/participante, detalhe com inscrever/cancelar, confirmação de convocação, exibição de status/posição/prazo/contagem regressiva e estados de carregamento/vazio/erro/sucesso, provadas por testes de `ApiClient` e de widget com HTTP fake. Regras: R42–R45.