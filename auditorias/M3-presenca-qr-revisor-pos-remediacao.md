# Parecer de revisão pós-remediação — M3 Presença por QR

## Fontes

- `contrato-api.md:152-185`, `contrato-api.md:258-290`
- `specs/M3-presenca-qr.md:38-77`
- `auditorias/M3-resolucao.md:1-28`
- `api/lib/server.dart:482-708`
- `api/test/presenca_test.dart:61-455`
- `api/test/presenca_regressao_test.dart:64-295`
- `frontend/lib/api_client.dart:47-221`
- `frontend/lib/presencas_page.dart:5-341`
- `frontend/test/presencas_api_client_test.dart:20-66`
- `frontend/test/presencas_widget_test.dart:13-188`

## Metas conferidas

| Método e rota | Contrato | Implementação |
|---|---|---|
| `GET /encontros/:id/codigo` | Organização; `200 CodigoDoEncontro` — `contrato-api.md:154-167` | Rota, autenticação, papel e resposta implementados em `api/lib/server.dart:488-564` |
| `POST /encontros/:id/presencas` | Participante; `201` nova e `200` duplicada — `contrato-api.md:154-157` | Implementado em `api/lib/server.dart:500-504` e `api/lib/server.dart:584-633` |
| `POST /encontros/:id/presencas/manual` | Organização; `201` nova e `200` duplicada — `contrato-api.md:154-158` | Implementado em `api/lib/server.dart:505-509` e `api/lib/server.dart:644-689` |
| `GET /encontros/:id/presencas` | Organização; `200 [Presenca]` — `contrato-api.md:154-160` | Implementado em `api/lib/server.dart:493-499` e `api/lib/server.dart:692-708` |
| Identificação por `X-Usuario` | `401 USUARIO_DESCONHECIDO` — `contrato-api.md:12` | Aplicada nas quatro rotas por `_authorized`, em `api/lib/server.dart:434-445` |
| Verificação de papel | `403 SOMENTE_ORGANIZACAO` ou `SOMENTE_PARTICIPANTE` — `contrato-api.md:262-264` | Implementada em `api/lib/server.dart:488-509` e `api/lib/server.dart:584-647` |
| Encontro inexistente | `404 NAO_ENCONTRADO` antes do corpo — `contrato-api.md:17`, `specs/M3-presenca-qr.md:54-57` | Implementado em `api/lib/server.dart:490-498`, `api/lib/server.dart:590` e `api/lib/server.dart:647` |
| Envelope de erro | `{"erro","mensagem"}` — `contrato-api.md:15` | Implementado por `ApiError.toJson` em `api/lib/server.dart:87-92` e `_error` em `api/lib/server.dart:1201-1207` |
| Campos de `CodigoDoEncontro` | `encontroId`, `codigo`, `trocaEm`, `validoAte` — `contrato-api.md:161-168` | Serializados em `api/lib/server.dart:559-564`; consumidos em `frontend/lib/api_client.dart:47-54` |
| Campos de `Presenca` | Sete campos definidos em `contrato-api.md:176-185` | Serializados em `api/lib/server.dart:700-708`; consumidos em `frontend/lib/api_client.dart:56-66` |
| Janela inclusiva de presença | 15 minutos antes até 15 minutos depois — `specs/M3-presenca-qr.md:58-65` | Implementada em `api/lib/server.dart:523-530` e aplicada em `api/lib/server.dart:613-614` e `api/lib/server.dart:672-673` |
| Código determinístico e rotação de cinco minutos | `contrato-api.md:165-167`, `specs/M3-presenca-qr.md:59-60` | Implementado em `api/lib/server.dart:532-564` |
| QR online/offline | Origem `qr` ou `qr_offline`; `lidoEm` opcional — `contrato-api.md:170-172`, `specs/M3-presenca-qr.md:62-64` | Implementado em `api/lib/server.dart:605-625` |
| Sincronização tardia | `422 SINCRONIZACAO_TARDIA` — `contrato-api.md:286` | Implementado em `api/lib/server.dart:608-611` |
| Código inválido | `422 CODIGO_INVALIDO` — `contrato-api.md:284` | Implementado em `api/lib/server.dart:616-618` |
| Inscrição confirmada | `403 NAO_INSCRITO` — `contrato-api.md:285` | Implementado em `api/lib/server.dart:599-603` e `api/lib/server.dart:656-660` |
| Idempotência | Duplicata retorna o primeiro registro com `200` — `specs/M3-presenca-qr.md:65-67` | Implementada em `api/lib/server.dart:599-601` e `api/lib/server.dart:656-658` |
| Justificativa manual | 10–500 caracteres após `trim`; `422 JUSTIFICATIVA_OBRIGATORIA` — `contrato-api.md:287`, `specs/M3-presenca-qr.md:68` | Implementado em `api/lib/server.dart:662-670` |
| Presença manual fora da janela | `422 FORA_DA_JANELA` — `contrato-api.md:283` | Implementado em `api/lib/server.dart:672-673` |
| Atividade cancelada | `422 ATIVIDADE_CANCELADA` — `contrato-api.md:274`, `specs/M3-presenca-qr.md:71` | Implementado em `api/lib/server.dart:550-552`, `api/lib/server.dart:596-597` e `api/lib/server.dart:653-654` |
| Listagem | Todas as presenças, ordenadas por `registradaEm` — `specs/M3-presenca-qr.md:73` | Implementado em `api/lib/server.dart:692-697` |
| Persistência e reset | `specs/M3-presenca-qr.md:74-76` | Persistência em `api/lib/server.dart:310-377`; reset em `api/lib/server.dart:128-161` |
| Frontend M3 | Quatro fluxos via `ApiClient`, sem regras duplicadas — `specs/M3-presenca-qr.md:77` | Cliente em `frontend/lib/api_client.dart:185-221`; tela em `frontend/lib/presencas_page.dart:56-198` e `frontend/lib/presencas_page.dart:281-341` |
| Estados da tela | Loading, vazio, erro e sucesso — `specs/M3-presenca-qr.md:77` | Implementados em `frontend/lib/presencas_page.dart:56-102`, `frontend/lib/presencas_page.dart:105-198` e `frontend/lib/presencas_page.dart:235-249` |

## Matriz de endpoints

| Endpoint | Rota/método | Papel e identificação | Sucesso | Erros verificados | Resultado |
|---|---|---|---|---|---|
| Código | `GET /encontros/:id/codigo` | Organização; `X-Usuario` obrigatório | `200` com quatro campos | `401`, `403`, `404`, `422 ATIVIDADE_CANCELADA`, `422 FORA_DA_JANELA` | Conforme |
| QR | `POST /encontros/:id/presencas` | Participante; `X-Usuario` obrigatório | `201` nova; `200` duplicada | `401`, `403`, `404`, `422 DADOS_INVALIDOS`, `ATIVIDADE_CANCELADA`, `SINCRONIZACAO_TARDIA`, `FORA_DA_JANELA`, `CODIGO_INVALIDO` | Conforme, exceto `lidoEm: null` |
| Manual | `POST /encontros/:id/presencas/manual` | Organização; `X-Usuario` obrigatório | `201` nova; `200` duplicada | `401`, `403`, `404`, `422 DADOS_INVALIDOS`, `ATIVIDADE_CANCELADA`, `NAO_INSCRITO`, `JUSTIFICATIVA_OBRIGATORIA`, `FORA_DA_JANELA` | Conforme |
| Listagem | `GET /encontros/:id/presencas` | Organização; `X-Usuario` obrigatório | `200` lista ordenada | `401`, `403`, `404` | Conforme |

## Divergências

1. **[MÉDIA — CAMPO/VALIDAÇÃO] `lidoEm: null` é aceito como se o campo estivesse ausente.**  
   O contrato define `lidoEm` como campo opcional de entrada e determina `422 DADOS_INVALIDOS` para tipo incorreto em `contrato-api.md:16` e `contrato-api.md:170-172`. Na implementação, `body['lidoEm'] == null` faz `null` ser tratado como QR online em `api/lib/server.dart:605-606`; portanto, um campo explicitamente presente com valor `null` não é rejeitado como tipo inválido.

2. **[BAIXA — ENVELOPE DE ERRO] Métodos não previstos nas rotas M3 retornam resposta sem envelope JSON.**  
   A regra geral exige envelope para erros em `contrato-api.md:15`. Quando o caminho é reconhecido, mas o método não corresponde a uma das quatro operações, `_meetingRoute` termina com `_finish(request, 404)` em `api/lib/server.dart:500-511`, produzindo `404` sem `{"erro","mensagem"}`. A divergência se aplica a métodos fora dos endpoints contratados, não aos quatro métodos válidos.

## Decisão documentada sobre `LIMITE_DE_MANUAIS`

Não foi registrada divergência para `LIMITE_DE_MANUAIS`. O contrato documenta o código em `contrato-api.md:288`, mas `auditorias/M3-resolucao.md:7-28` determina que, no escopo aprovado, a duplicidade por `(encontroId, participanteId)` seja resolvida antes de qualquer limite e que não seja inventada uma cota. A implementação retorna `200` para duplicidade em `api/lib/server.dart:656-658`, coerente com essa decisão de produto.

## Resultados atuais de verificação

- `dart test` em `api`: **passou — 101 testes**.
- `flutter test` em `frontend`: **passou — 50 testes**.
- `dart analyze` em `api`: **No issues found!**
- `flutter analyze` em `frontend`: **No issues found!**
- Smoke M3: **não executado**; a execução de `dart run tool/smoke_m3.dart` foi bloqueada pela política do ambiente de ferramentas.

## Conformidade

Foram conferidas as quatro rotas M3, seus métodos, papéis, envelopes, 11 campos de resposta, códigos HTTP/erro e fluxos Flutter; há uma divergência impeditiva de validação para `lidoEm: null` e uma divergência secundária de envelope em métodos não contratados.
