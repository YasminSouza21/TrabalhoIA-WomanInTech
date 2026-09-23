## Metas conferidas

- Entrada e saída das quatro rotas M3 em JSON UTF-8, conforme `contrato-api.md:11`.
- `X-Usuario` obrigatório nas quatro rotas M3, conforme `contrato-api.md:12`.
- Usuário ausente ou inexistente deve retornar `401 USUARIO_DESCONHECIDO`, conforme `contrato-api.md:12,262`.
- Erros devem usar o envelope `{"erro":"CODIGO","mensagem":"texto livre"}`, conforme `contrato-api.md:15`.
- Corpo inválido, ausente quando obrigatório ou com tipo incorreto deve retornar `422 DADOS_INVALIDOS`, conforme `contrato-api.md:16,266`.
- Datas devem ser ISO 8601 com fuso, conforme `contrato-api.md:13`.
- Identificadores de presença devem usar prefixo `pre_` e oito hexadecimais minúsculos, conforme `contrato-api.md:14`.
- `GET /encontros/:id/codigo` para organização deve retornar `200`, conforme `contrato-api.md:154-156`.
- `CodigoDoEncontro` deve conter `encontroId`, `codigo`, `trocaEm` e `validoAte`, conforme `contrato-api.md:161-168`.
- `CodigoDoEncontro.codigo` deve ser uma string de seis caracteres, conforme `contrato-api.md:164-167`.
- `POST /encontros/:id/presencas` para participante deve retornar `201` na primeira presença e `200` nas repetições, conforme `contrato-api.md:154-157`.
- A entrada da presença QR deve conter `codigo` string e aceitar `lidoEm` opcional, conforme `contrato-api.md:170-172`.
- A presença QR deve retornar os campos `id`, `encontroId`, `participanteId`, `origem`, `lidoEm`, `registradaEm` e `justificativa`, conforme `contrato-api.md:176-185`.
- A origem da presença QR deve ser `qr` ou `qr_offline`, conforme `contrato-api.md:181`.
- `POST /encontros/:id/presencas/manual` para organização deve retornar `201` na primeira presença e `200` nas repetições, conforme `contrato-api.md:154-158`.
- A entrada da presença manual deve conter `participanteId` string e `justificativa`, conforme `contrato-api.md:173-174`.
- A justificativa manual ausente deve retornar `422 JUSTIFICATIVA_OBRIGATORIA`, conforme `contrato-api.md:174,287`.
- A origem da presença manual deve ser `manual`, conforme `contrato-api.md:181`.
- A justificativa deve ser texto somente na presença manual e nula nas demais, conforme `contrato-api.md:184`.
- `GET /encontros/:id/presencas` para organização deve retornar `200 [Presenca]`, conforme `contrato-api.md:154,159`.
- A listagem deve retornar uma lista de objetos `Presenca`, conforme `contrato-api.md:159,176-185`.
- As rotas de organização devem retornar `403 SOMENTE_ORGANIZACAO` para participante, conforme `contrato-api.md:154,263`.
- A rota de presença QR deve retornar `403 SOMENTE_PARTICIPANTE` para organização, conforme `contrato-api.md:157,264`.
- Encontro inexistente deve retornar `404 NAO_ENCONTRADO`, conforme `contrato-api.md:265`.
- Obter código fora da janela deve retornar `422 FORA_DA_JANELA`, conforme `contrato-api.md:283`.
- Registrar presença fora da janela deve retornar `422 FORA_DA_JANELA`, conforme `contrato-api.md:283`.
- Código QR inválido deve retornar `422 CODIGO_INVALIDO`, conforme `contrato-api.md:284`.
- Participante não inscrito deve retornar `403 NAO_INSCRITO`, conforme `contrato-api.md:285`.
- Leitura offline fora da tolerância ou futura deve retornar `422 SINCRONIZACAO_TARDIA`, conforme `contrato-api.md:286`.
- Presença manual fora da janela deve retornar `422 FORA_DA_JANELA`, conforme `contrato-api.md:283`.
- Presença manual sem justificativa deve retornar `422 JUSTIFICATIVA_OBRIGATORIA`, conforme `contrato-api.md:287`.
- O limite de presenças manuais deve retornar `422 LIMITE_DE_MANUAIS`, conforme `contrato-api.md:288`.
- Atividade cancelada deve retornar `422 ATIVIDADE_CANCELADA` ao obter código ou registrar presença, conforme `contrato-api.md:274`.
- As verificações devem seguir identificação, perfil, existência, corpo e regras do recurso, conforme `contrato-api.md:17`.

## Divergências

1. **[CÓDIGO DE ERRO]** O contrato exige `422 LIMITE_DE_MANUAIS` para a rota de presença manual (`contrato-api.md:283,288`), mas não há qualquer verificação ou retorno desse código na implementação de `POST /encontros/:id/presencas/manual`. O fluxo percorre autenticação, existência, corpo, inscrição, justificativa e janela, criando a presença sem limite manual em `api/lib/server.dart:642-687`.

2. **[ROTA]** A implementação aceita caminhos adicionais que não constam do contrato. Em `api/lib/server.dart:482-509`, a validação permite até quatro segmentos e as condições de `GET` para `codigo` e `presencas` não exigem respectivamente `parts.length == 3`. Assim, caminhos como `/encontros/:id/codigo/:extra` e `/encontros/:id/presencas/:extra` são processados como as rotas contratadas, embora o contrato defina somente `/encontros/:id/codigo` e `/encontros/:id/presencas` em `contrato-api.md:156,159`.

## Conformidade

Foram conferidas 32 metas de rota, método, identificação, status, campos, tipos, códigos de erro, envelope e convenções aplicáveis às quatro rotas M3. Os testes definidos em `projeto.json:14` foram executados: `dart test` em `api/` terminou com `All tests passed!`; `flutter test` na raiz falhou com `Test directory "test" not found`; executado em `frontend/`, terminou com `All tests passed!`. Há divergência impeditiva pela ausência de `LIMITE_DE_MANUAIS` e divergência de roteamento por aceitação de caminhos extras.
