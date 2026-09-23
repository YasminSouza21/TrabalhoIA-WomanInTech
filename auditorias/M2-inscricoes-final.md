# Auditoria Final — M2 Inscrições e Lista de Espera

## Escopo, commit, fontes e método

Escopo: somente o Módulo 2, incluindo API, persistência/modo de teste e interface Flutter R44/R45. O commit auditado foi `8b67bdcf450e6a514a616f38726e57c01808265d` (`HEAD` no início e no fim da auditoria).

Fontes consultadas:

- `AGENTS.md`, `api/AGENTS.md`, `frontend/AGENTS.md` e `.opencode/agent/auditor.md`.
- `contrato-api.md`, `specs/M2-inscricoes.md`, `entrevistas/M2-inscricoes.md` e `projeto.json`.
- `api/lib/server.dart`, `api/test/inscricoes_test.dart`, `api/test/server_test.dart`, `api/test/fila_test.dart`, `api/test/confirmacao_test.dart`, `api/test/tempo_test.dart`, `api/test/persistencia_test.dart` e `api/tool/smoke_m2.dart`.
- `frontend/lib/inscricoes_page.dart`, `frontend/lib/api_client.dart`, `frontend/test/inscricoes_api_client_test.dart`, `frontend/test/inscricoes_widget_test.dart` e `frontend/test/regressao_m2_widget_test.dart`.
- `evidencias/ENTREGA-M2.md`; auditorias/evidências do M1 foram usadas somente para contexto.

Método: o agente `@auditor` foi executado em modo somente leitura, conferindo para cada regra a origem na entrevista e um teste que exercita o cenário e verifica o resultado. A implementação foi lida para validar que as provas são honestas. Também foram executados os comandos de validação do `projeto.json` e o smoke HTTP documentado.

## Matriz requisito → evidência → teste

Todas as regras abaixo têm origem rastreável em pergunta respondida da entrevista. `COMPROVADA` significa que foi localizada evidência de implementação e teste comportamental correspondente.

| Regra | Evidência da implementação | Teste / resultado | Veredito |
|---|---|---|---|
| R01 | `api/lib/server.dart:348-367,620-623,647-653,656-664,693-704` | `api/test/inscricoes_test.dart:37-54`; smoke `S02` | COMPROVADA |
| R02 | `api/lib/server.dart:659-661,694-696` | `api/test/inscricoes_test.dart:56-68`; smoke `S03` | COMPROVADA |
| R03 | `api/lib/server.dart:662-664,697-700,649-650` | `api/test/inscricoes_test.dart:71-89`; smoke `S04` | COMPROVADA |
| R04 | `api/lib/server.dart:665-666,702-703,901-909` | `api/test/inscricoes_test.dart:306-326`; `api/test/fila_test.dart:450-489`; smoke `S07` | COMPROVADA |
| R05 | `api/lib/server.dart:659-667,693-704` | `api/test/inscricoes_test.dart:71-121`; smoke `S02-S04` | COMPROVADA |
| R06 | `api/lib/server.dart:326-330,105-136` | `api/test/inscricoes_test.dart:124-143,385-407`; smoke `S01` | COMPROVADA |
| R07 | `api/lib/server.dart:679-690` | `api/test/inscricoes_test.dart:145-168`; `api/test/fila_test.dart:450-489`; smoke `S08` | COMPROVADA |
| R08 | `api/lib/server.dart:668-671` | `api/test/inscricoes_test.dart:264-304` | COMPROVADA |
| R09 | `api/lib/server.dart:668-671` | `api/test/inscricoes_test.dart:264-304` | COMPROVADA |
| R10 | `api/lib/server.dart:668-669` | `api/test/inscricoes_test.dart:292-304` | COMPROVADA |
| R11 | `api/lib/server.dart:670-671` | `api/test/inscricoes_test.dart:269-275` | COMPROVADA |
| R12 | `api/lib/server.dart:668-678` | `api/test/confirmacao_test.dart:502-555`; `api/test/inscricoes_test.dart:264-304` | COMPROVADA |
| R13 | `api/lib/server.dart:749-759` | `api/test/inscricoes_test.dart:235-262`; `api/test/confirmacao_test.dart:502-555` | COMPROVADA |
| R14 | `api/lib/server.dart:714-719,680-690` | `api/test/fila_test.dart:387-425`; `api/test/persistencia_test.dart:122-170` | COMPROVADA |
| R15 | `api/lib/server.dart:722-735,830-835,680-690` | `api/test/tempo_test.dart:332-370` | COMPROVADA |
| R16 | `api/lib/server.dart:842-851,862-873` | `api/test/inscricoes_test.dart:170-208`; `api/test/fila_test.dart:151-192` | COMPROVADA |
| R17 | `api/lib/server.dart:43-44,103,684-686,848-850` | `api/test/inscricoes_test.dart:170-208`; `api/test/persistencia_test.dart:245-295` | COMPROVADA |
| R18 | `api/lib/server.dart:862-873` | `api/test/fila_test.dart:249-281`; `api/test/inscricoes_test.dart:365-380` | COMPROVADA |
| R19 | `api/lib/server.dart:562-577,714-717,814-816,837-859` | `api/test/fila_test.dart:151-247`; `api/test/fila_test.dart:283-311` | COMPROVADA |
| R20 | `api/lib/server.dart:722-734,837-859` | `api/test/confirmacao_test.dart:238-284,405-452` | COMPROVADA |
| R21 | `api/lib/server.dart:853-856` | `api/test/fila_test.dart:194-208`; `api/test/confirmacao_test.dart:111-143` | COMPROVADA |
| R22 | `api/lib/server.dart:722-726` | `api/test/confirmacao_test.dart:145-175` | COMPROVADA |
| R23 | `api/lib/server.dart:262-266,788-827` | `api/test/tempo_test.dart:70-107`; `api/test/persistencia_test.dart:172-209` | COMPROVADA |
| R24 | `api/lib/server.dart:811-816,830-835` | `api/test/tempo_test.dart:70-107` | COMPROVADA |
| R25 | `api/lib/server.dart:794-827,837-859` | `api/test/tempo_test.dart:182-230` | COMPROVADA |
| R26 | `api/lib/server.dart:817-827` | `api/test/tempo_test.dart:138-180`; `api/test/fila_test.dart:427-448` | COMPROVADA |
| R27 | `api/lib/server.dart:830-835,901-909` | `api/test/tempo_test.dart:109-136` | COMPROVADA |
| R28 | `api/lib/server.dart:762-775,729-731` | `api/test/confirmacao_test.dart:212-236,238-284` | COMPROVADA |
| R29 | `api/lib/server.dart:770-772` | `api/test/confirmacao_test.dart:177-210` | COMPROVADA |
| R30 | `api/lib/server.dart:777-786,677-678,732-734` | `api/test/confirmacao_test.dart:286-323,405-452` | COMPROVADA |
| R31 | `api/lib/server.dart:722-728` | `api/test/tempo_test.dart:278-330`; `api/test/confirmacao_test.dart:145-175` | COMPROVADA |
| R32 | `api/lib/server.dart:727-728` | `api/test/confirmacao_test.dart:66-109`; `api/test/fila_test.dart:470-489` | COMPROVADA |
| R33 | `api/lib/server.dart:707-719` | `api/test/fila_test.dart:66-79,81-107` | COMPROVADA |
| R34 | `api/lib/server.dart:708-710` | `api/test/fila_test.dart:81-107` | COMPROVADA |
| R35 | `api/lib/server.dart:711-713` | `api/test/fila_test.dart:109-124`; `api/test/tempo_test.dart:372-397` | COMPROVADA |
| R36 | `api/lib/server.dart:562-577` | `api/test/fila_test.dart:338-385`; `api/test/tempo_test.dart:400-441` | COMPROVADA |
| R37 | `api/lib/server.dart:647-653,693-704` | `api/test/fila_test.dart:338-385`; `api/test/inscricoes_test.dart:328-383` | COMPROVADA |
| R38 | `api/lib/server.dart:620-633` | `api/test/inscricoes_test.dart:328-383` | COMPROVADA |
| R39 | `api/lib/server.dart:625-633` | `api/test/inscricoes_test.dart:328-383`; `api/test/persistencia_test.dart:85-120` | COMPROVADA |
| R40 | `api/lib/server.dart:86-92,138-178,247-300` | `api/test/persistencia_test.dart:85-120,245-295` | COMPROVADA |
| R41 | `api/lib/server.dart:88-90,248,326-345` | `api/test/persistencia_test.dart:225-243`; `api/test/inscricoes_test.dart:385-407` | COMPROVADA |
| R42 | `api/lib/server.dart:78-79,66-70,875-887` | `api/test/inscricoes_test.dart:145-168`; `frontend/test/inscricoes_api_client_test.dart:10-28`; smoke `S08` | COMPROVADA |
| R43 | `api/lib/server.dart:580-617` | `api/test/inscricoes_test.dart:409-435`; `api/test/tempo_test.dart:232-276` | COMPROVADA |
| R44 | `frontend/lib/inscricoes_page.dart:46-83,85-95,180-212,215-301` | `frontend/test/inscricoes_widget_test.dart:44-104,147-235,237-274`; `frontend/test/regressao_m2_widget_test.dart:1-200` | COMPROVADA |
| R45 | `frontend/lib/inscricoes_page.dart:5-6,55-61,264-285`; `frontend/lib/api_client.dart` | `frontend/test/inscricoes_api_client_test.dart:30-171`; `frontend/test/inscricoes_widget_test.dart:147-235`; MockClient | COMPROVADA |

R44 foi conferida separadamente na matriz: listagem de todos os status, detalhe, inscrever, cancelar, confirmar, posição, prazo, countdown e estados loading/vazio/erro/sucesso estão evidenciados em `frontend/lib/inscricoes_page.dart:180-301` e nos testes Flutter citados.

## Testes e validações executados

Resultados observados nesta auditoria:

| Comando exato | Resultado observado |
|---|---|
| `(cd api && dart test)` | `00:01 +78: All tests passed!` |
| `(cd api && dart analyze)` | `No issues found!` |
| `(cd frontend && flutter analyze)` | `No issues found! (ran in 7.2s)` |
| `(cd frontend && flutter test)` | `00:03 +40: All tests passed!` |
| `(cd api && dart run tool/smoke_m2.dart)` | `resumo: 16 cenarios ok - SMOKE M2 OK` |

O smoke iniciou servidor com `MODO_TESTE=1` e `PORT=3000`, executando S01 a S16, incluindo reset, autenticação, autorização, existência, relógio, inscrição, corpo inválido, isolamento/listagem, contadores, cancelamento, confirmação, aumento de vagas e expiração.

Não houve falha de SDK, build ou ambiente nos comandos executados. A evidência histórica também registra `flutter build web --release` como OK em `evidencias/ENTREGA-M2.md:67-79`, mas esse build não foi reexecutado nesta auditoria porque não consta em `projeto.json` como teste obrigatório.

## Defeitos, inconsistências e lacunas reais

Não foram encontrados defeitos funcionais ou divergências de contrato no escopo M2 após a leitura e os testes executados. As regras de autenticação/autorização, rotas, status, envelopes, códigos, fila FIFO, posições, reentrada, abertura de vagas, convocação, prazo de 24 horas, expiração cronológica, cascata, relógio, persistência, cancelamento de atividade, filtros, permissões, limites, conflitos, campos calculados e UI R44 possuem prova localizada.

Limitações que não configuram defeito funcional do M2:

- As decisões P-01 a P-29 foram delegadas e registradas na entrevista; não há validação contra requisitos externos do professor. Isso é uma limitação de origem/escopo, explicitamente registrada em `specs/M2-inscricoes.md:6` e `evidencias/ENTREGA-M2.md:115-119`, não uma falha da implementação contra o contrato local.
- A persistência JSON é de processo único, conforme `evidencias/ENTREGA-M2.md:118`; não foi contratado locking multi-processo.
- M1 foi usado como contexto/regressão. Os testes e regras de M3, M4 e M5 não são achados do M2; `INSCRICAO_BLOQUEADA` está fora do escopo em `specs/M2-inscricoes.md:8-13`.

## Separação de escopo

Itens de M1, como grade, salas, criação/edição/cancelamento de atividades e seus testes em `api/test/server_test.dart`, foram considerados apenas para verificar a integração necessária ao M2 e não geram achado M2. Não foram atribuídos ao M2 requisitos de presença, certificados, extrato ou painel da organização, que permanecem fora do escopo conforme `specs/M2-inscricoes.md:8-13`.

## Veredito

# PASSOU

As regras R01-R45, incluindo R44 e R45, têm origem rastreável, evidência de implementação e testes correspondentes; `dart test`, `dart analyze`, `flutter analyze`, `flutter test` e o smoke HTTP M2 passaram nesta auditoria. O aceite é relativo ao contrato local, spec e entrevista existentes; a ausência de conferência contra requisitos externos permanece explicitamente fora desta conclusão.
