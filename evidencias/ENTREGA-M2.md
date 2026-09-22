# Entrega M2 — Inscrições e Lista de Espera

Responsável: Clara L Peretti — base `5237d5a` → `HEAD` (`b2c11ef`).

## Arquivos alterados (agrupados)

Comando: `git diff --name-only 5237d5a` (28 arquivos).

**Spec e levantamento**
- `specs/M2-inscricoes.md`
- `entrevistas/M2-inscricoes.md`

**API — backend**
- `api/bin/server.dart`
- `api/lib/server.dart`
- `api/AGENTS.md`
- `api/tool/smoke_m2.dart`

**API — testes**
- `api/test/confirmacao_test.dart`
- `api/test/fila_test.dart`
- `api/test/inscricoes_test.dart`
- `api/test/persistencia_test.dart`
- `api/test/tempo_test.dart`

**Frontend — código**
- `frontend/lib/api_client.dart`
- `frontend/lib/inscricoes_page.dart`
- `frontend/lib/main.dart`
- `frontend/AGENTS.md`

**Frontend — testes**
- `frontend/test/inscricoes_api_client_test.dart`
- `frontend/test/inscricoes_widget_test.dart`
- `frontend/test/regressao_m2_widget_test.dart`

**Evidências / exportador**
- `evidencias/agentes.txt`
- `evidencias/exportar-evidencias.js`
- `evidencias/exportar-evidencias.test.js`

**OpenCode — agentes e skills**
- `.opencode/agent/auditor.md`
- `.opencode/agent/revisor-de-contrato.md`
- `.opencode/skills/tdd/SKILL.md`
- `.opencode/skills/telas-flutter/SKILL.md`

**Raiz / equipe**
- `EQUIPE.md`
- `README.md`
- `.gitignore`

## Regras implementadas (resumo)

Spec `specs/M2-inscricoes.md`, regras R01–R45 (todas com origem rastreada na entrevista):

- **Fundações (R01–R06, R37–R39):** `X-Usuario` obrigatório, perfil, existência, corpo, ordem das verificações, `/_teste/reset`, isolamento participante/organização, filtro e ordem de inserção.
- **Inscrição (R07–R15):** `confirmada`/`em_espera` FIFO, `JA_INSCRITO`, reinscrição após `cancelada`/`expirada` como nova, encerramento (`INSCRICOES_ENCERRADAS`), atividade cancelada e precedência.
- **Fila (R16–R19):** FIFO estrita por sequência monotônica, posições compactas, convocação automática em toda abertura de vaga.
- **Convocação e confirmação (R20–R22, R28–R32):** janela de 24 h limitada ao início do encontro, `CONVOCACAO_EXPIRADA`, `SEM_CONVOCACAO`, `CONFLITO_DE_HORARIO`, `LIMITE_DE_MINICURSOS`.
- **Cascatas temporais (R23–R27):** expiração sob demanda e cronológica, reprocessamento com salto de relógio, fim de fila no início do primeiro encontro, retrocesso sem desfazer.
- **Cancelamentos (R33–R36):** cancelar inscrição, cancelar atividade convertendo ativas em `cancelada` e esvaziando a fila.
- **Persistência e testes (R40–R41):** arquivo JSON local sem `MODO_TESTE`; memória isolada + relógio controlado com `MODO_TESTE=1`.
- **Contrato (R42–R43):** modelo da `Inscricao` e campos calculados da `Atividade`.
- **Interface mínima Flutter (R44–R45):** `ApiClient` injetável, "Minhas inscrições", detalhe com inscrever/cancelar, confirmação de convocação, estados de carregamento/vazio/erro/sucesso.

## Validações observadas (22/09/2026)

| Validação | Comando | Resultado |
|---|---|---|
| Testes da API | `dart test` (api) | 78 passaram |
| Testes do frontend | `flutter test` (frontend) | 40 passaram |
| Análise estática da API | `dart analyze` (api) | sem problemas |
| Análise estática do frontend | `flutter analyze` (frontend) | sem problemas |
| Exportador de evidências | `node --test` (evidencias) | 17 passaram |
| Smoke HTTP M2 | `dart run tool/smoke_m2.dart` | 16 cenários OK |
| Build web release | `flutter build web --release` | OK (validado na sessão de 22/09 19:56) |

SDK: Flutter **3.47.5** (stable) · Dart **3.13.4** (stable).

## Links

- Spec M2: `specs/M2-inscricoes.md`
- Entrevista M2: `entrevistas/M2-inscricoes.md`
- Equipe: `EQUIPE.md` (M2 — Clara L Peretti / claraperetti)
- Índice de sessões de Clara: `evidencias/sessoes/clara-l-peretti/INDICE.md`
- Auditorias M2: **em andamento** — auditoria final registrada como **pendente**; será completada em sessão separada. Sem parecer nesta entrega.

## Commits (5237d5a..HEAD)

| Data/Hora | Autor | Hash completo | Mensagem |
|---|---|---|---|
| 2026-09-22 20:16 | Clara L Peretti | `b2c11effdac8a94402e337a56fe6fe9026ec509f` | fix(api M2): persistencia sincrona sem corrida no arquivo e relogio refeito apos leitura do corpo em mutacoes |
| 2026-09-22 20:13 | Clara L Peretti | `3c45605af0de21ef933311d160147e24a9965af8` | docs(README): secao M2 com instalacao, runtime, smoke, persistencia e rastreabilidade |
| 2026-09-22 20:10 | Clara L Peretti | `054b5bec3ecf8231b1f1012e48d8370d72d20ab7` | feat: M2 R40-R41 persistencia JSON local e relogio real avancando por request |
| 2026-09-22 20:07 | Clara L Peretti | `50df647774935690dd5b35a5f1388f0742b68857` | fix(frontend M2): detalhe usa inscricao ativa em vez da primeira historica e convocada permite cancelar |
| 2026-09-22 20:00 | Clara L Peretti | `a2e684b99a79e7c7ad7b376179a4d1e634655ac1` | feat: M2 expiracao em cascata cronologica, reconciliacao de relogio e fim de fila - R15 R23-R27 R31 R35 R36 R43 |
| 2026-09-22 19:55 | Clara L Peretti | `921f8a4562ab1e44f4fa59fda1ee6c23ccdc2547` | fix(frontend M2): corre regressoes de corrida, sincronizacao e countdown |
| 2026-09-22 19:52 | Clara L Peretti | `2120ac777fd187609d83790238dbaf21604d5044` | test M2 smoke HTTP |
| 2026-09-22 19:44 | Clara L Peretti | `f1b8069d1ff274051b7a6127d763cfac0feda0a8` | fix(evidencias): não lê título de teste TAP/Dart como falha e corrige acesso ao placar nos testes |
| 2026-09-22 19:42 | Clara L Peretti | `9f43de959a878d5a9e42fee185d620456715f84e` | feat: M2 fatia 4 - R20-R22 R28-R32 confirmacao de convocacao, CONFLITO_DE_HORARIO e LIMITE_DE_MINICURSOS |
| 2026-09-22 19:36 | Clara L Peretti | `13e8c8b294172033da77468321c5d4b0f4fdbc68` | fix(evidencias): reconhece dart.exe/flutter.bat por caminho no Windows e marca compilação Dart quebrada como vermelha |
| 2026-09-22 19:34 | Clara L Peretti | `69621160da6aa7b960e4e60ad4bd0419d68f8479` | feat: M2 R44-R45 - navegacao grade->inscricoes e detalhe do participante com inscrever/cancelar/confirmar preservando M1 |
| 2026-09-22 19:34 | Clara L Peretti | `a72cc096fc9f7aadac5663872cd860e072edef88` | feat: M2 interface R44 - tela Minhas inscricoes/participante e consulta organizacao com estados e contagem |
| 2026-09-22 19:32 | Clara L Peretti | `eb54aff6e6a9b56e707f5bb974245c8ad2f24d7e` | feat: M2 fatia cancelamento e promocao da fila - R14 R16-R21 R33-R37 R43 cancelar inscricao, convocar FIFO e cancelar atividade |
| 2026-09-22 19:27 | Clara L Peretti | `b424ac08a9cc41c36868f5d6ffafe35681bd71f1` | docs: registra Clara Peretti como responsavel pelo M2 |
| 2026-09-22 19:20 | Clara L Peretti | `62407e85e9cdc6182812b38ab16bf6bee01f574a` | feat: M2 fatia 2 - R07-R18, R37-R39, R42-R43 inscricoes confirmada/em_espera FIFO |
| 2026-09-22 19:18 | Clara L Peretti | `e6cfca30f09fbc42e0bebd0769fa8dd5126037a6` | chore: skill telas-flutter e agentes de review apenas-leitura (auditor + revisor-de-contrato) com permission bash restrita |
| 2026-09-22 19:14 | Clara L Peretti | `58b3bc64d3189d1dff9c8d6c21c84a4dc4cce43e` | feat: M2 frontend ApiClient R42-R45 - Inscricao, listar/detalhe, inscrever/cancelar/confirmar com X-Usuario |
| 2026-09-22 19:08 | Clara L Peretti | `138e379a8281ef3e1ae49aec0ab862aa9446e453` | feat: M2 fatia 1 - R01-R06, R37-R39 inscricoes (base backend) |
| 2026-09-22 19:01 | Clara L Peretti | `b5f9f58cce3bc158bc1a3e62b424e5eb190ebd03` | M2: completa spec e adapta TDD e instrucoes para Dart Flutter |
| 2026-09-22 18:55 | Clara L Peretti | `39749242a969f3f37002205389f96f78fd37470d` | spec: regras do M2 inscricoes e lista de espera |
| 2026-09-22 18:43 | Clara L Peretti | `ba2bb6e91461e978a6d784588286e848f0021ef3` | M2: rodada 2 com decisoes delegadas e rastreabilidade |

## Limitações reais (não ocultadas)

1. **Regras delegadas sem conferência externa:** as decisões da Rodada 2 (P-01 a P-29) foram escolhidas por delegação expressa da usuária em 22/09/2026, com base no `contrato-api.md` e na spec do M1; **não foram conferidas contra requisitos externos do professor** (nota de rastreabilidade na própria spec). Não alegar conformidade externa.
2. **Persistência de 1 processo:** o arquivo JSON (R40) assume um único processo escrevendo o estado local; não há locking entre processos nem serviço externo.
3. **TDD não é perfeito:** o histórico inclui testes que nasceram verdes (33 "nasceu verde", conforme `INDICE.md`), correções de fixtures e **dois testes provisórios do M2 ajustados à spec**. Não alegar ciclos Red-Green rigorosos em todos os fatias.
4. **M1 intacto:** testes e históricos do M1 não foram alterados nesta entrega.
5. **Nenhum push:** todos os commits são locais; não houve push para o origin.
6. **Auditoria M2 pendente:** será completada em sessão separada; esta entrega não traz parecer de auditoria.