# Spec — M3 Presenca por QR

## 1. Objetivo

O M3 permite que a organizacao publique um QR por encontro, que participantes
confirmados registrem presenca online ou offline, e que a organizacao complemente a
presenca manualmente e consulte as presencas registradas.

## 2. Fora de escopo

- Certificados, extrato e bloqueios do M4/M5.
- Scanner de camera nativo; o frontend envia o codigo lido pelo dispositivo.
- Regras de frequencia ou aprovacao para certificado.
- Mais de uma presenca do mesmo participante no mesmo encontro.

## 3. Modelo

`CodigoDoEncontro`:

- `encontroId`: id do encontro existente.
- `codigo`: codigo deterministico de 6 caracteres para a janela de 5 minutos.
- `trocaEm`: proximo instante de troca do codigo.
- `validoAte`: primeiro instante em que o codigo deixa de ser aceito.

`Presenca`:

- `id`: gerado com prefixo `pre_` e 8 hexadecimais minusculos.
- `encontroId`: referencia ao encontro.
- `participanteId`: participante confirmado.
- `origem`: `qr`, `qr_offline` ou `manual`.
- `lidoEm`: instante usado nas regras; no manual, o relogio da API.
- `registradaEm`: instante em que a API registrou a operacao.
- `justificativa`: nula para QR; texto manual validado.

Presencas e a sequencia de ids sao persistidas fora de `MODO_TESTE`. A chave de
idempotencia e `(encontroId, participanteId)`.

## 4. Endpoints

| Metodo | Rota | Papel | Sucesso |
|---|---|---|---|
| GET | `/encontros/:id/codigo` | organizacao | 200 `CodigoDoEncontro` |
| POST | `/encontros/:id/presencas` | participante | 201 `Presenca` nova; 200 repetida |
| POST | `/encontros/:id/presencas/manual` | organizacao | 201 `Presenca` nova; 200 repetida |
| GET | `/encontros/:id/presencas` | organizacao | 200 `[Presenca]` |

Entradas:

- QR: `{ "codigo": "K7M2QX", "lidoEm": "..." }`, com `lidoEm` opcional.
- Manual: `{ "participanteId": "p-carla", "justificativa": "..." }`.

## 5. Regras

- R01. Toda rota identificada exige `X-Usuario`; ausencia ou usuario desconhecido retorna `401 USUARIO_DESCONHECIDO`.
- R02. Rotas de QR do participante retornam `403 SOMENTE_PARTICIPANTE` para organizacao; rotas de codigo, manual e listagem retornam `403 SOMENTE_ORGANIZACAO` para participante.
- R03. Encontro inexistente retorna `404 NAO_ENCONTRADO` antes de corpo ou regra de negocio.
- R04. Corpo malformado, raiz nao objeto ou tipos invalidos retorna `422 DADOS_INVALIDOS` depois de identificacao, papel e existencia.
- R05. Cada encontro possui sua propria janela: de 15 minutos antes do inicio a 15 minutos depois do fim, com limites inclusivos.
- R06. O codigo troca a cada 5 minutos; a troca invalida imediatamente o codigo anterior. `trocaEm` e o proximo limite de bucket e `validoAte` e o fim do bucket atual.
- R07. O codigo retornado tem 6 caracteres e e deterministico para encontro e bucket; a regra de derivacao nao e exposta no frontend.
- R08. Obter codigo fora da janela retorna `422 FORA_DA_JANELA`; atividade cancelada retorna `422 ATIVIDADE_CANCELADA` antes da janela.
- R09. `lidoEm` e o instante usado para validar QR. Sem `lidoEm`, vale o relogio da API e a origem e `qr`; com `lidoEm`, a origem e `qr_offline`.
- R10. `lidoEm` nao pode estar no futuro em relacao ao relogio da API. A diferenca absoluta entre `lidoEm` e o relogio da API nao pode exceder 10 minutos; violacao retorna `422 SINCRONIZACAO_TARDIA`.
- R11. Registro QR fora da janela de seu encontro retorna `422 FORA_DA_JANELA`; codigo diferente do codigo valido no instante de leitura retorna `422 CODIGO_INVALIDO`.
- R12. Registro de presenca exige inscricao `confirmada` do participante no M2; qualquer outro status ou ausencia retorna `403 NAO_INSCRITO`.
- R13. Presenca duplicada pelo mesmo encontro e participante retorna `200` com a primeira presenca, sem validar ou substituir origem, instante ou justificativa.
- R14. Presenca manual exige `participanteId` existente e confirmado no encontro; caso contrario retorna `403 NAO_INSCRITO`.
- R15. Justificativa manual, apos `trim`, deve ter de 10 a 500 caracteres; ausencia, vazio, curta ou longa retorna `422 JUSTIFICATIVA_OBRIGATORIA`.
- R16. A presenca manual usa o relogio da API em `lidoEm` e `registradaEm`, e exige a janela inclusiva do encontro; fora dela retorna `422 FORA_DA_JANELA`.
- R17. Ha no maximo um registro manual por participante/encontro por organizacao; o limite e compartilhado entre organizacoes. Uma duplicidade idempotente e resolvida antes do limite e retorna `200`.
- R18. Atividade cancelada impede obter codigo e registrar presenca, retornando `ATIVIDADE_CANCELADA`.
- R19. A precedencia apos autenticacao, papel, existencia e corpo e: atividade cancelada; duplicidade; inscricao elegivel; sincronizacao; janela; codigo. Para manual, justificativa e validada antes da janela somente quando nao houver duplicidade.
- R20. GET de presencas retorna todas em ordem de `registradaEm` e nao cria ou altera registros.
- R21. `POST /_teste/reset` apaga presencas, sequencias e estado de codigos e restaura o relogio inicial; em `MODO_TESTE=1`, nada toca o arquivo de producao.
- R22. Fora de `MODO_TESTE`, presencas sobrevivem a reinicio via arquivo JSON local.
- R23. Relogio controlado pode ser usado nos testes; transicoes ja materializadas nao sao desfeitas por retrocesso.
- R24. O frontend implementa os quatro fluxos via `ApiClient`: obter QR, registrar QR, registrar manual e listar presencas, com loading, vazio, erro e sucesso, sem replicar regras.

### Rastreabilidade das regras

Os identificadores `P-01` a `P-23` abaixo correspondem, respectivamente, a `P1` a
`P23` da entrevista `entrevistas/M3-presenca-qr.md`. As regras de formato e ordem
do contrato foram fechadas pela pergunta de precedencia (P-12), enquanto as
decisoes de fluxo foram fechadas pelas perguntas especificas indicadas.

| Regra | Pergunta(s) de origem |
|---|---|
| R01-R04 | P-12 |
| R05 | P-01, P-02 |
| R06 | P-03, P-04 |
| R07 | P-03 |
| R08 | P-11, P-12 |
| R09 | P-06, P-08 |
| R10 | P-07 |
| R11 | P-08, P-11 |
| R12 | P-09, P-10 |
| R13 | P-13, P-14 |
| R14 | P-15 |
| R15 | P-16 |
| R16 | P-02, P-05, P-11 |
| R17 | P-17, P-18, P-19 |
| R18 | P-11, P-12 |
| R19 | P-12, P-13, P-16, P-19 |
| R20 | P-22 |
| R21-R22 | P-20 |
| R23 | P-21 |
| R24 | P-22 |

## 6. Criterios de aceite

1. (R01-R04) Cada rota responde autenticacao, papel, existencia e corpo na ordem do contrato.
2. (R05-R08) Codigo e presenca sao aceitos nos limites de 15 minutos e recusados fora da janela; atividade cancelada retorna `ATIVIDADE_CANCELADA`.
3. (R06-R07) Dois GETs no mesmo bucket retornam o mesmo codigo, e o bucket seguinte retorna outro codigo com `trocaEm` e `validoAte` coerentes.
4. (R09-R11) QR online, offline dentro da tolerancia, leitura futura, sincronizacao tardia, codigo antigo e codigo invalido retornam os resultados definidos.
5. (R12) Participante confirmado registra presenca; participante sem inscricao elegivel recebe `403 NAO_INSCRITO`.
6. (R13) Repetir QR e manual retorna `200` com o primeiro registro e preserva todos os seus campos.
7. (R14-R17) Manual exige justificativa de 10 a 500 caracteres, respeita janela, limite compartilhado e idempotencia.
8. (R18-R20) Organizacao lista presencas, em ordem, e nao participante nao pode usar rotas de participante.
9. (R21-R23) Reset remove presencas e restaura relogio; persistencia de producao sobrevive a reinicio; retrocesso nao desfaz transicao materializada.
10. (R24) Widget e `ApiClient` exercitam os quatro fluxos com transporte HTTP fake e estados loading, vazio, erro e sucesso.

## 7. Como isto sera verificado

O backend sera verificado exclusivamente pela interface HTTP de `ApiServer` em
`MODO_TESTE=1`, com `HttpClient`, reset e relogio controlado. Persistencia sera
verificada reiniciando `ApiServer` com arquivo temporario. O frontend sera verificado
com `MockClient` e `flutter_test`; nenhuma regra de dominio sera recalculada na tela.

## 8. Fatias de entrega

1. Modelo, persistencia/reset e roteamento HTTP de encontros.
2. Codigo deterministico, janela, troca e precedencia de atividade.
3. Registro QR online/offline, inscricao confirmada, codigo invalido e idempotencia.
4. Presenca manual, justificativa, limite compartilhado e listagem.
5. Persistencia/reinicio, reset e bordas temporais completas.
6. `ApiClient`, telas Flutter e testes de widget.
7. Smoke, documentacao, evidencias e verificacao final.
