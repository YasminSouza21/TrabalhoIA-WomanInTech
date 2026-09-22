# Entrevista — M2 Inscrições e Lista de Espera

## Registro

Os fatos abaixo já estão fixados pelo contrato da API (`contrato-api.md`) e pela
spec do M1 (`specs/M1-grade-atividades.md`). Eles **não** são perguntados na
entrevista. As perguntas P-xx da Rodada 1 são regras de negócio ainda **PENDENTE**,
que o contrato não decide.

**Rodada 2 — fechamento por delegação.** Em 22/09/2026 a usuária autorizou
expressamente que o agente decidisse e respondesse todas as perguntas pendentes com
base no contrato da API e na spec do M1 já disponíveis, sem nova consulta a um
documento de requisitos. Cada pergunta virou **decisão de projeto** registrada abaixo
com número, resposta e fonte. A fonte de verdade é essa delegação expressa; não há RN
inventada fora das tabelas da Rodada 2.

## Fatos já definidos (não perguntar)

| # | Fato | Fonte |
|---|---|---|
| F-01 | `POST /atividades/:id/inscricoes` cria inscrição, é exclusivo de participante e **não recebe corpo na entrada**; sucesso retorna `201 Inscricao`. | contrato-api.md, rotas M2 |
| F-02 | `POST /inscricoes/:id/cancelamento` e `POST /inscricoes/:id/confirmacao` são exclusivos de participante e retornam `200 Inscricao`. | contrato-api.md, rotas M2 |
| F-03 | `GET /inscricoes` e `GET /inscricoes/:id` são acessíveis a todos os usuários identificados. Em `GET /inscricoes` o participante recebe **apenas as próprias** inscrições, e existe o filtro `?atividadeId=`. | contrato-api.md, rotas M2 |
| F-04 | `Inscricao` tem `id` (`ins_` + 8 hexadecimais), `atividadeId`, `participanteId`, `status`, `posicaoNaEspera` (número só quando `em_espera`), `convocadaAte` (instante só quando `convocada`) e `criadaEm`. | contrato-api.md, modelo Inscricao |
| F-05 | Os status de inscrição são: `confirmada`, `em_espera`, `convocada`, `cancelada` e `expirada`. | contrato-api.md, modelo Inscricao |
| F-06 | Toda rota identificada exige `X-Usuario`; sem cabeçalho ou com id inexistente → `401 USUARIO_DESCONHECIDO`. | contrato-api.md, convenções |
| F-07 | Ordem das verificações: identificação (401) → perfil (403) → existência (404 `NAO_ENCONTRADO`) → corpo (422 `DADOS_INVALIDOS`) → regras do recurso. Quando mais de uma regra do recurso recusa a mesma operação, a ordem entre elas é regra de negócio (**PENDENTE**). | contrato-api.md, convenções |
| F-08 | Operações de participante recusam organização com `403 SOMENTE_PARTICIPANTE`. | contrato-api.md, convenções e rotas M2 |
| F-09 | Recurso inexistente (atividade ou inscrição) → `404 NAO_ENCONTRADO`. | contrato-api.md, convenções |
| F-10 | Corpo que não é JSON, campo obrigatório ausente ou de tipo errado → `422 DADOS_INVALIDOS`. | contrato-api.md, convenções |
| F-11 | Códigos de erro do M2 presentes no contrato: `ATIVIDADE_CANCELADA` (422), `INSCRICOES_ENCERRADAS` (422), `INSCRICAO_BLOQUEADA` (422, só grupos com M5), `JA_INSCRITO` (409), `CONFLITO_DE_HORARIO` (409), `LIMITE_DE_MINICURSOS` (422), `INSCRICAO_INATIVA` (422), `SEM_CONVOCACAO` (422), `CONVOCACAO_EXPIRADA` (422) e `ATIVIDADE_JA_INICIADA` (422, para cancelamento de inscrição). | contrato-api.md, códigos de retorno |
| F-12 | Inscrever em atividade cancelada → `ATIVIDADE_CANCELADA`. | contrato-api.md, códigos de retorno |
| F-13 | Cancelar inscrição de atividade já iniciada → `ATIVIDADE_JA_INICIADA`. | contrato-api.md, códigos de retorno |
| F-14 | Datas em ISO 8601 com fuso. Com `MODO_TESTE=1` o relógio é controlado e toda regra temporal usa esse relógio; `POST /_teste/reset` apaga tudo e põe o relógio em `2026-10-13T09:00:00-03:00`. | contrato-api.md, convenções e modo de teste |
| F-15 | Os dados iniciais não incluem nenhuma inscrição; apenas usuários e salas do contrato. | contrato-api.md, dados iniciais |
| F-16 | `ocupadas`/`vagasRestantes` contam apenas inscrições `confirmadas` e `convocadas`; `em_espera`, `canceladas` e `expiradas` não ocupam vaga. | specs/M1-grade-atividades.md, R29 e R30 |
| F-17 | `emEspera` de uma atividade é a quantidade de inscrições `em_espera`. | contrato-api.md, modelo Atividade |
| F-18 | Aumentar vagas é permitido e a convocação automática da lista de espera pertence ao M2. | specs/M1-grade-atividades.md, R31 |
| F-19 | Ao cancelar a atividade, as inscrições ativas são canceladas e novas inscrições ficam bloqueadas. | specs/M1-grade-atividades.md, seção 17 e entrevistas/M1-grade-atividades.md, R2-P24 |

## Rodada 1 — Perguntas pendentes (regras de negócio)

### Bloco A — Prazos e bordas de encerramento e de convocação

❓ **P-01 — Prazo de encerramento das inscrições**: até quando um participante pode
se inscrever antes de aparecer `INSCRICOES_ENCERRADAS`? (início do primeiro
encontro? fim do último encontro? N horas/minutos antes? prazo fixo calendário?)

➡️ Recomendação: encerrar exatamente no instante do início do primeiro encontro,
mantendo o mesmo critério de borda do M1 para início de atividade.

---

❓ **P-02 — Inscrição em atividade iniciada ou encerrada**: inscrever em atividade
já iniciada (mas não cancelada) retorna também `INSCRICOES_ENCERRADAS`, ou outro
código?

➡️ Recomendação: `INSCRICOES_ENCERRADAS` para iniciada e encerrada (não cancelada);
`ATIVIDADE_CANCELADA` fica reservado para cancelada, como no contrato.

---

❓ **P-03 — Borda do encerramento**: inscrever exatamente com `agora == início do
primeiro encontro` é aceito ou recusado?

➡️ Recomendação: recusar (borda inclusiva, coerente com `em_andamento` no M1).

---

❓ **P-04 — Janela de convocação (`convocadaAte`)**: qual é o prazo entre convocar
e confirmar? (quanto vale `convocadaAte`: minutos, horas, até o início da
atividade?)

➡️ Recomendação: definir um prazo fixo explícito (você decide o valor) e registrá-lo
como RN.

---

❓ **P-05 — Borda da convocação**: confirmar exatamente com `agora == convocadaAte`
é aceito (`CONVOCACAO_EXPIRADA` só depois) ou já expirou nesse instante?

➡️ Recomendação: aceitar na borda (expiração só depois do instante), por simetria
com as bordas inclusivas de início/fim do M1.

### Bloco B — FIFO e empate

❓ **P-06 — Ordem da fila**: a lista de espera é FIFO estrita pela ordem de criação
(`criadaEm`), com o primeiro da fila ganhando vaga/convocação primeiro?

➡️ Recomendação: FIFO estrito por `criadaEm`.

---

❓ **P-07 — Empate na fila**: duas inscrições com `criadaEm` idêntico (mesmo
instante de relógio) — qual desempata?

➡️ Recomendação: desempatar deterministicamente por `id` de inscrição (lexicográfico),
já que não há outra ordem observável.

---

❓ **P-08 — Renoção de posições**: quando alguém sai da espera (cancela, expira,
confirma), os que ficam sobem de posição mantendo a ordem original (remumeração
compacta) ou ficam com a posição antiga gravada?

➡️ Recomendação: encurtar a fila e re-enumerar de 1 em ordem FIFO.

---

❓ **P-09 — Abertura de vaga sem aumento de vagas**: quando uma vaga abre por
cancelamento ou expiração de uma inscrição `confirmada`/`convocada`, a lista de
espera é convocada automaticamente (como no aumento de vagas)? Ou só o aumento de
vagas convoca?

➡️ Recomendação: convocar automaticamente em qualquer abertura de vaga (aumento ou
liberação), mesma fila FIFO.

---

❓ **P-10 — Convocação e conflito**: na convocação automática, quem está em espera
mas em conflito de horário (ou excedeu o limite de minicursos) é pulado e o
próximo da fila é convocado? E essa pessoa pulada mantém a posição?

➡️ Recomendação: pular quem está em conflito/limite, mantendo a posição para uma
eventual convocação futura.

### Bloco C — Expiração sem acesso e salto do relógio

❓ **P-11 — Expiração sem acesso**: se o relógio passa de `convocadaAte` sem nenhuma
requisição, a inscrição expira sozinha? A expiração é calculada sob demanda pelo
relógio a qualquer leitura (estado rederivado), sem precisar de evento/job?

➡️ Recomendação: expiração é regra temporal rederivada do relógio a cada leitura,
sem job assíncrono.

---

❓ **P-12 — Efeito da expiração**: ao expirar, a vaga que a convocação reservava é
liberada e a lista de espera é convocada em seguida? O expirado mantém algo (fila
ou vaga)?

➡️ Recomendação: expirada libera a vaga e dispara a próxima convocação da fila.

---

❓ **P-13 — Salto do relógio para frente (modo de teste)**: no `PUT /_teste/relogio`
com salto grande para frente, o sistema deve reprocessar toda a cadeia de expirações
e convocações intermediárias de uma vez (cascata), ou apenas valer o estado final?

➡️ Recomendação: reprocessar a cadeia completa de expirações/convocações até o
instante final, de modo determinístico.

---

❓ **P-14 — Salto do relógio para trás**: o relógio do modo de teste pode voltar?
Se voltar, expirações e convocações já aplicadas são revertidas?

➡️ Recomendação: relógio é a fonte de verdade absoluta; estado é rederivado do
instante atual, então retrocesso reverte o que não é persistente (cancelamento
e cancelada permanecem).

### Bloco D — Estados que contam para conflito de horário e limite de minicursos

❓ **P-15 — `CONFLITO_DE_HORARIO` — quais status contam**: quais inscrições do
mesmo participante contam para conflito de horário ao inscrever/confirmar?
(`confirmada`, `convocada`, `em_espera`, `expirada`, `cancelada`?)

➡️ Recomendação: contar apenas `confirmada` e `convocada` (as que ocupam vaga),
coerente com F-16.

---

❓ **P-16 — Como medir o conflito**: o conflito de horário compara os encontros das
atividades (intervalos no horário de Brasília, mesmas bordas do M1), independente
de sala?

➡️ Recomendação: comparar os intervalos de encontros das atividades envolvidas.

---

❓ **P-17 — `LIMITE_DE_MINICURSOS`**: qual é o limite de minicursos por participante
(número)? Quais status contam para esse limite (`confirmada`, `convocada`,
`em_espera`, `expirada`, `cancelada`)? O limite vale por evento inteiro e é
verificado também na confirmação de convocação?

➡️ Recomendação: definir o número; contar `confirmada` + `convocada` (mesmo critério
de ocupar vaga); validar em inscrever e em confirmar convocação.

### Bloco E — Precedência de erros

❓ **P-18 — Precedência ao inscrever**: quando uma mesma inscrição viola várias
regras de recurso ao mesmo tempo (ex.: `ATIVIDADE_CANCELADA`, `INSCRICOES_ENCERRADAS`,
`INSCRICAO_BLOQUEADA`, `JA_INSCRITO`, `CONFLITO_DE_HORARIO`,
`LIMITE_DE_MINICURSOS`), qual erro o participante recebe primeiro?

➡️ Recomendação: seguir uma ordem fixa documentada, começando pelo estado da
atividade (cancelada → encerramentos), depois `INSCRICAO_BLOQUEADA`/`JA_INSCRITO`,
depois `CONFLITO_DE_HORARIO`/`LIMITE_DE_MINICURSOS`.

---

❓ **P-19 — Precedência ao cancelar inscrição**: ao cancelar inscrição, qual erro
vale primeiro entre `ATIVIDADE_CANCELADA`, `ATIVIDADE_JA_INICIADA` e
`INSCRICAO_INATIVA` (ex.: cancelar inscrição já cancelada/expirada numa atividade
já iniciada)?

➡️ Recomendação: primeiro o estado da atividade (`ATIVIDADE_CANCELADA`, depois
`ATIVIDADE_JA_INICIADA`), depois `INSCRICAO_INATIVA`.

---

❓ **P-20 — Precedência ao confirmar convocação**: ao confirmar, qual erro vale
primeiro entre `SEM_CONVOCACAO`, `CONVOCACAO_EXPIRADA`, `CONFLITO_DE_HORARIO` e
`LIMITE_DE_MINICURSOS`?

➡️ Recomendação: primeiro `SEM_CONVOCACAO`, depois `CONVOCACAO_EXPIRADA`, depois
conflito e limite.

### Bloco F — Reinscrição

❓ **P-21 — Reinscrição após cancelamento**: um participante que cancelou a
própria inscrição pode se inscrever de novo na mesma atividade depois? Se sim,
volta para o fim da fila (em caso de lotada) ou revive a posição?

➡️ Recomendação: permite nova inscrição (nova `Inscricao`, fim da fila), sem
reviver a posição antiga.

---

❓ **P-22 — Reinscrição após expirar**: quem teve convocação expirada pode se
reinscrever ou ser reconvocado se uma nova vaga abrir?

➡️ Recomendação: sim, nova inscrição/reconvocação como se fosse um participante novo,
sem privilégio nem punição.

---

❓ **P-23 — Quando `JA_INSCRITO` vale**: `JA_INSCRITO` dispara para quais status da
inscrição existente? (`confirmada`, `convocada`, `em_espera`; e `cancelada`/
`expirada` liberam a reinscrição?)

➡️ Recomendação: `JA_INSCRITO` apenas para `confirmada`, `convocada` e `em_espera`
(status ativos); `cancelada` e `expirada` permitem nova inscrição.

### Bloco G — Cancelamento da atividade

❓ **P-24 — Cancelamento da atividade e a fila**: no cancelamento da atividade,
quais status são considerados "inscrições ativas" que viram `cancelada`
(`confirmada`, `convocada`, `em_espera`)? E o que acontece com a fila/posições
destas inscrições?

➡️ Recomendação: `confirmada`, `convocada` e `em_espera` viram `cancelada`;
`expirada` já é inativa e não muda; fila é esvaziada.

### Bloco H — Isolamento de inscrições alheias

❓ **P-25 — `GET /inscricoes/:id` de inscrição de outro**: um participante acessando
o detalhe de uma inscrição que não é dele retorna `404 NAO_ENCONTRADO` (tratada
como inexistente) ou outro erro?

➡️ Recomendação: `404 NAO_ENCONTRADO`, mantendo o isolamento (participante só
enxerga as próprias).

---

❓ **P-26 — Contéudo de `GET /inscricoes`**: a lista do participante inclui também
`canceladas` e `expiradas`, ou somente status ativos? O filtro `?atividadeId=`
mantém o mesmo princípio? E a organização vê todas as inscrições de todos?

➡️ Recomendação: incluir todos os status (inclusive canceladas/expiradas) para
histórico, com o mesmo princípio de isolamento e filtro.

### Bloco I — Corpo da requisição e ordenação/persistência

❓ **P-27 — Corpo enviado onde não há entrada**: como o contrato diz "sem corpo na
entrada", um corpo ausente ou vazio é aceito. Um corpo JSON presente (mesmo sem
campos definidos) deve ser ignorado ou vira `422 DADOS_INVALIDOS`? Vale o mesmo
para cancelamento e confirmação?

➡️ Recomendação: corpo ausente/vazio aceito; corpo presente com JSON bem formado é
ignorado (sem campos a validar); corpo mal formado (não-JSON) vira `DADOS_INVALIDOS`.

---

❓ **P-28 — Ordenação de `GET /inscricoes`**: em que ordem a lista de inscrições
é retornada (por `criadaEm`? por status? por atividade?)?

➡️ Recomendação: ordenar por `criadaEm` ascendente; empate por `id`.

---

❓ **P-29 — Persistência de estados temporais**: uma vez que a expiração de uma
convocação é observada por uma leitura, esse resultado precisa ser "carimbado" e
não voltar se o relógio for colocado para trás no modo de teste?

➡️ Recomendação: tudo é rederivado do relógio; nada é carimbado, exceto o que é
persistente por decisão (cancelamentos).

## Rodada 2 — Respostas por delegação (P-01 a P-29)

> Fonte de todas as linhas desta tabela: **decidido de projeto — delegação expressa
> da usuária em 22/09/2026**, com base no `contrato-api.md` e na spec do M1 já
> disponíveis neste repositório. As perguntas na íntegra e as sugestões (➡️) originais
> estão preservadas na Rodada 1 acima.

| # | Pergunta (Rodada 1) | Resposta (decisão final) | Fonte |
|---|---|---|---|
| P-01 | Prazo de encerramento das inscrições | As inscrições encerram no instante de início do primeiro encontro; com `agora >= inicio` inscrever retorna `422 INSCRICOES_ENCERRADAS`. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-02 | Inscrição em atividade iniciada/encerrada | Atividade iniciada ou encerrada (não cancelada) também retorna `422 INSCRICOES_ENCERRADAS`; `ATIVIDADE_CANCELADA` fica reservado a atividade cancelada. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-03 | Borda do encerramento | Recusada: `agora == inicio do primeiro encontro` já é `INSCRICOES_ENCERRADAS` (borda inclusiva de encerramento). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-04 | Janela de convocação (`convocadaAte`) | `convocadaAte` = instante da convocação + 24 horas, limitado ao início do primeiro encontro da atividade. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-05 | Borda da convocação | Expirada: `agora >= convocadaAte` já retorna `422 CONVOCACAO_EXPIRADA` (borda inclusiva de expiração). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-06 | Ordem da fila | FIFO estrito pela sequência de entrada (ordem de inserção persistida). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-07 | Empate na fila | Desempate pela ordem de inserção persistida (sequência monotônica gravada na criação); nunca por `id` aleatório. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-08 | Remoção de posições | Posições são derivadas e compactas: quem sai da espera faz os demais subirem, re-enumerados de 1 em ordem FIFO. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-09 | Abertura de vaga sem aumento de vagas | Toda abertura de vaga convoca automaticamente: cancelamento, expiração ou aumento de vagas, sempre em FIFO. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-10 | Convocação e conflito/limite | Convocar em FIFO sem pular ninguém. Conflito de horário e limite de minicursos são revalidados na confirmação; se falhar, a convocação é preservada até `convocadaAte` e só então o próximo da fila é convocado. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-11 | Expiração sem acesso | Sim, temporal e processada a cada leitura, processando vencimentos cronologicamente inclusive cascatas ocorridas sem requisições; relógio de teste e leituras veem o resultado atualizado. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-12 | Efeito da expiração | Expiração libera a vaga e convoca o próximo da fila usando como instante de convocação o instante do vencimento anterior (processamento cronológico da cascata); expirada não mantém fila nem vaga. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-13 | Salto do relógio para frente | Reprocessar a cadeia completa de vencimentos e convocações cronologicamente até o instante final, de forma determinística; novas convocações param no início do primeiro encontro. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-14 | Salto do relógio para trás | O juiz de teste só avança o relógio; retrocesso não desfaz transições históricas já aplicadas (ver P-29). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-15 | `CONFLITO_DE_HORARIO` — status que contam | Somente inscrições `confirmadas` contam para conflito; na confirmação, excluir a própria inscrição da verificação. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-16 | Como medir o conflito | Conflito quando houver qualquer encontro sobreposto entre as atividades, por intervalos `[inicio, fim)` (início inclusivo, fim exclusivo), independente da sala; terminar 10h e começar 10h é permitido; o intervalo mínimo de 15 minutos do conflito de sala do M1 não se aplica ao conflito de horário do M2. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-17 | `LIMITE_DE_MINICURSOS` | Máximo de 2 minicursos confirmados por participante por evento; `em_espera` e `convocada` não contam; validar em inscrever e em confirmar, excluindo a própria inscrição. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-18 | Precedência ao inscrever | Ordem: `ATIVIDADE_CANCELADA` → `INSCRICOES_ENCERRADAS` → duplicidade ativa (`JA_INSCRITO`) → `CONFLITO_DE_HORARIO` → `LIMITE_DE_MINICURSOS`. `INSCRICAO_BLOQUEADA` (M5) está fora do escopo do M2. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-19 | Precedência ao cancelar inscrição | Estado da atividade primeiro: `ATIVIDADE_JA_INICIADA` antecede `INSCRICAO_INATIVA`. Nesta rota não existe `ATIVIDADE_CANCELADA`: o cancelamento da atividade já converteu as ativas em `cancelada`, então cancelar uma delas retorna `INSCRICAO_INATIVA`. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-20 | Precedência ao confirmar convocação | Ordem: `SEM_CONVOCACAO` → `CONVOCACAO_EXPIRADA` → `CONFLITO_DE_HORARIO` → `LIMITE_DE_MINICURSOS`. Convoca da vencida pelo relógio retorna `CONVOCACAO_EXPIRADA` inclusive depois de uma leitura já ter observado o vencimento. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-21 | Reinscrição após cancelamento | Sim, com nova `Inscricao`, novo `id`, no fim da fila; nunca reconvocar o registro antigo. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-22 | Reinscrição após expirar | Sim, como participante novo, no fim da fila, sem privilégio nem punição; nunca reconvocar o registro antigo. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-23 | Quando `JA_INSCRITO` vale | Vale para `confirmada`, `em_espera` e `convocada`; `cancelada` e `expirada` liberam nova inscrição. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-24 | Cancelamento da atividade e a fila | Ativas (`confirmada`, `convocada`, `em_espera`) viram `cancelada`, com `posicaoNaEspera` e `convocadaAte` limpos; `expirada` é preservada. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-25 | Inscrição alheia | Participante só consulta/cancela/confirma as próprias; inscrição alheia → `404 NAO_ENCONTRADO`. Organização consulta todas, mas não muta (`403 SOMENTE_PARTICIPANTE` nas rotas de cancelamento/confirmação). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-26 | Conteúdo de `GET /inscricoes` | Inclui todos os status, inclusive `cancelada` e `expirada`; o filtro `?atividadeId=` mantém o princípio de isolamento e um valor sem inscrições resulta em lista vazia; organização vê todas as inscrições. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-27 | Corpo onde não há entrada | Corpo ausente/vazio aceito nas três rotas; JSON objeto bem formado é ignorado; JSON malformado ou raiz que não é objeto → `422 DADOS_INVALIDOS`. Ordem: identificação → papel → existência → corpo → regras. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-28 | Ordenação de `GET /inscricoes` | Pela ordem de inserção persistida, ascendente (mesma sequência usada na fila). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-29 | Persistência de estados temporais | Transições observadas por leitura ficam materializadas (carimbo histórico); retrocesso do relógio não as desfaz (ver P-14). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |

### Notas de decisão final sobre as sugestões da Rodada 1

As sugestões (➡️) da Rodada 1 ficaram preservadas como histórico. Onde a decisão
final divergiu, ela é a regra a implementar:

| # | Sugestão da Rodada 1 | Decisão final | Situação |
|---|---|---|---|
| P-04 | Definir um prazo fixo explícito (o valor fica para o usuário). | Prazo definido: 24 horas da convocação, limitado ao início do primeiro encontro. | CORRIGIDO |
| P-05 | Aceitar na borda (`CONVOCACAO_EXPIRADA` só depois). | `agora >= convocadaAte` já expira; borda inclusiva de expiração. | CORRIGIDO |
| P-07 | Desempatar deterministicamente por `id` (lexicográfico). | Ordem de inserção persistida; nunca `id` aleatório. | CORRIGIDO |
| P-10 | Pular quem está em conflito/limite, mantendo a posição. | Convocar FIFO sem pular; conflito/limite revalidados ao confirmar; falha preserva a convocação até `convocadaAte`. | CORRIGIDO |
| P-14 | Retrocesso reverte o que não é persistente. | Retrocesso não desfaz transições históricas já aplicadas. | CORRIGIDO |
| P-15 | Contar `confirmada` e `convocada`. | Somente `confirmada`; excluir a própria na confirmação. | CORRIGIDO |
| P-16 | Comparar os intervalos de encontros. | Precisado: `[inicio, fim)`, independe da sala, fim 10h + início 10h permitido, sem o intervalo de 15 min do conflito de sala do M1. | CORRIGIDO |
| P-17 | Definir o número; contar `confirmada` + `convocada`. | Limite fixado em 2; somente `confirmada` conta. | CORRIGIDO |
| P-19 | Ordem: `ATIVIDADE_CANCELADA`, `ATIVIDADE_JA_INICIADA`, `INSCRICAO_INATIVA`. | Sem `ATIVIDADE_CANCELADA` na rota de cancelamento; `ATIVIDADE_JA_INICIADA` antes de `INSCRICAO_INATIVA`. | CORRIGIDO |
| P-28 | Ordenar por `criadaEm` ascendente; empate por `id`. | Ordem de inserção persistida. | CORRIGIDO |
| P-29 | Nada é carimbado, exceto cancelamentos. | Transições observadas ficam materializadas; retrocesso não desfaz. | CORRIGIDO |

As demais sugestões (P-01, P-02, P-03, P-06, P-08, P-09, P-11, P-12, P-13, P-18,
P-20, P-21, P-22, P-23, P-24, P-25, P-26 e P-27) foram **CONFIRMADAS** pela
decisão final e valem como regra sem alteração.

## Rodada 2 complementar — decisões de arquitetura e escopo (P-30 em diante)

Decisões adicionais já autorizadas na delegação de 22/09/2026, registradas para
rastreabilidade. Não dependem de nova pergunta.

| # | Pergunta | Resposta (decisão final) | Fonte |
|---|---|---|---|
| P-30 | Persistência fora do modo de teste | Sem `MODO_TESTE`, o estado M1/M2 (atividades, salas, inscrições) e a sequência de ordem de inserção da fila são persistidos em arquivo JSON local, sem serviços externos (contrato, seção 2: banco embutido/arquivo). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-31 | Modo de teste e reset | Com `MODO_TESTE=1`, o estado fica em memória isolada (não toca o arquivo de persistência); `POST /_teste/reset` apaga as inscrições e todo o estado e recarrega os dados iniciais; o relógio é controlado por `PUT/GET /_teste/relogio`. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-32 | Fila no início do primeiro encontro | No início do primeiro encontro, convocadas vencidas expiram e a fila `em_espera` encerra como `expirada`; `confirmada` é preservada; novas convocações cessam (reforço de P-13). | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-33 | Status inicial da inscrição | Inscrição válida com vaga disponível → `confirmada`; sem vaga → `em_espera`, posicionada no fim da fila FIFO. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-34 | Interface mínima (não implementar agora) | Interface mínima registrada: Minhas inscrições (participante), consulta da organização, inscrever/cancelar a partir do detalhe, confirmar convocação, exibir status/posição/prazo/contagem regressiva e estados de carregamento/vazio/erro/sucesso via `ApiClient`. **Sem implementação nesta rodada.** | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |
| P-35 | Higiene do repositório | Adicionar `.tools/` ao `.gitignore` para não versionar SDKs e instaladores. Não é regra de API. | Decisão de projeto — delegação expressa do usuário, 22/09/2026 |

## Pontos Confirmados

A Rodada 2 fechou a fronteira da entrevista. Todas as perguntas começaram em estado
**PENDENTE** e terminaram como decisão de projeto registrada, sem resposta em aberto:

1. **Encerramento (P-01 a P-03):** inscrições encerram no início do primeiro
   encontro, borda inclusiva → `INSCRICOES_ENCERRADAS`.
2. **Convocação (P-04, P-05):** prazo de 24h limitado ao início do primeiro encontro;
   `agora >= convocadaAte` → `CONVOCACAO_EXPIRADA`.
3. **Fila (P-06 a P-09):** FIFO por ordem de inserção persistida, posições derivadas
   e compactas, desempate pela sequência gravada (nunca `id` aleatório) e convocação
   automática em toda abertura de vaga.
4. **Cascatas temporais (P-11 a P-14, P-29):** processamento cronológico a cada
   leitura, cascatas sem acessos, parada de novas convocações no início; retrocesso
   do relógio não desfaz transições históricas.
5. **Conflito e limite (P-15 a P-17):** somente `confirmada` conta para conflito;
   intervalo `[inicio, fim)` independente de sala, sem o intervalo de 15 min do M1;
   limite de 2 minicursos confirmados.
6. **Precedência (P-18 a P-20):** ordens fixas de erro para inscrever, cancelar e
   confirmar, com `INSCRICAO_BLOQUEADA` (M5) fora do escopo.
7. **Reinscrição (P-21 a P-23):** `cancelada`/`expirada` liberam nova inscrição com
   novo `id` no fim da fila; `confirmada`/`em_espera`/`convocada` → `JA_INSCRITO`.
8. **Cancelamento da atividade (P-24):** ativas viram `cancelada` com limpeza de
   prazo/posição; `expirada` preservada.
9. **Isolamento e listagem (P-25, P-26, P-28):** participante só vê as próprias
   (alheia → 404), todos os status aparecem, filtro isolado com lista vazia,
   ordenação por ordem de inserção.
10. **Contrato de corpo e ordem (P-27):** corpo ausente aceito, JSON objeto ignorado,
    malformado/raiz não-objeto → `DADOS_INVALIDOS`.
11. **Arquitetura (P-30, P-31, P-35):** persistência JSON local fora do modo de
    teste, memória isolada no modo de teste e `.tools/` fora do versionamento.

## Pontos Pendentes

A fronteira de perguntas da entrevista está vazia; as pendências abaixo são de
**execução**, não de decisão:

1. Implementação do M2 (rotas, fila, convocação, expiração em cascata) ainda não
   iniciada — decisão da rodada é "não implementar ainda" (P-34). Próximo passo:
   skill `tdd` com a spec do M2 a derivar destas decisões.
2. Persistência JSON local (P-30) e modo de teste em memória isolada (P-31) pendentes
   de implementação.
3. Interface mínima (P-34) não implementada, conforme decisão.
4. `evidencias/sessoes/clara-l-peretti/` contém sessões ainda não versionadas;
   ficaram fora deste commit (somente entrevista e `.gitignore` foram commitados).
5. `.tools/` deixou de ser versionado via `.gitignore` (P-35), mas o diretório físico
   permanece na máquina para uso local.