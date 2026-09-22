# Auditoria final M1 — Dart e Flutter

## 1. Escopo e fontes

Auditoria somente leitura do Módulo 1, com checagem independente obrigatória pelo agente `@auditor`. O relatório cobre as regras R01-R59 aplicáveis ao M1, a implementação Dart em `api/`, a interface Flutter em `frontend/` e as evidências em `api/test/server_test.dart` e `frontend/test/`.

Fontes consultadas:

- `contrato-api.md`.
- `specs/M1-grade-atividades.md`.
- `entrevistas/M1-grade-atividades.md`.
- `api/lib/server.dart` e `api/test/server_test.dart`.
- `frontend/lib/api_client.dart`, `frontend/lib/main.dart` e `frontend/test/`.
- Auditoria independente do agente `@auditor`.

Não foram alterados contrato, especificação, entrevista, auditorias históricas, backend ou frontend. As referências de teste abaixo são evidências existentes, não testes criados por esta auditoria.

Legenda: `COMPROVADA` = regra exercitada diretamente; `PARCIAL` = há evidência, mas não cobre o requisito inteiro; `SEM PROVA` = implementação ou contrato pode existir, mas não há teste suficiente; `DEPENDÊNCIA M2+` = explicitamente fora da implementação do M1.

## 2. Matriz requisito -> evidência -> resultado

| Requisito | Evidência (arquivo:linha) | Resultado |
|---|---|---|
| R01 | `specs/M1-grade-atividades.md:9`; `api/test/server_test.dart:37-44` | COMPROVADA |
| R02 | `specs/M1-grade-atividades.md:10`; `api/test/server_test.dart:37-44` | COMPROVADA |
| R03 | `api/lib/server.dart:148-178`; `api/test/server_test.dart:38-43` | SEM PROVA completa; origem apenas contratual |
| R04 | `api/lib/server.dart:148-178`; `api/test/server_test.dart:46-53` | SEM PROVA completa; origem apenas contratual |
| R05 | `specs/M1-grade-atividades.md:30-38` | DEPENDÊNCIA M2+ / M3 / M4; não exigida no M1 |
| R06 | `api/lib/server.dart:148-178`; `api/test/server_test.dart:37-44` | SEM PROVA completa; origem apenas contratual |
| R07 | `api/lib/server.dart:148-178`; `api/test/server_test.dart:46-53` | SEM PROVA completa; origem apenas contratual |
| R08 | `api/lib/server.dart:180-189`; sem teste de ID inexistente | SEM PROVA |
| R09 | `api/lib/server.dart:193-216`; `api/test/server_test.dart:80-107` | SEM PROVA completa; tipos/corpos não cobrem todos os casos |
| R10 | `api/lib/server.dart:228-240`; `api/test/server_test.dart:55-78` | COMPROVADA |
| R11 | `specs/M1-grade-atividades.md:67-69`; `api/test/server_test.dart:55-78` | COMPROVADA |
| R12 | `api/lib/server.dart:289-302`; `api/test/server_test.dart:55-78` | SEM PROVA de todos os casos; origem contratual |
| R13 | `api/lib/server.dart:217-228`; `api/test/server_test.dart:46-78` | SEM PROVA completa; origem contratual |
| R14 | `api/lib/server.dart:228-240`; criação válida em `api/test/server_test.dart:55-78`, sem casos 0/2 | SEM PROVA completa |
| R15 | `api/lib/server.dart:228-240`; criação válida em `api/test/server_test.dart:55-78`, sem casos 1/6 | SEM PROVA completa |
| R16 | `api/lib/server.dart:289-302`; `api/test/server_test.dart:329-353` | PARCIAL; bordas de data testadas, não todos os limites |
| R17 | `specs/M1-grade-atividades.md:79`; não exige precedência | COMPROVADA por ausência de exigência |
| R18 | `api/lib/server.dart:257-277`; `api/test/server_test.dart:266-304` | PARCIAL; cobre duração curta, não duração acima de 4h |
| R19 | `api/lib/server.dart:257-277`; `api/test/server_test.dart:329-339` | COMPROVADA |
| R20 | `api/lib/server.dart:257-277`; nenhum teste de sobreposição interna | SEM PROVA |
| R21 | `api/lib/server.dart:304-320`; `api/test/server_test.dart:109-143` | PARCIAL; teste cobre apenas borda `fim == início` |
| R22 | `api/lib/server.dart:304-320`; `api/test/server_test.dart:355-372` | COMPROVADA |
| R23 | `api/lib/server.dart:304-320`; `api/test/server_test.dart:375-389` | COMPROVADA |
| R24 | `api/lib/server.dart:304-320`; `api/test/server_test.dart:109-143` | COMPROVADA |
| R25 | `api/lib/server.dart:304-320`; `api/test/server_test.dart:375-389` | COMPROVADA |
| R26 | `api/lib/server.dart:241-254`; `api/test/server_test.dart:266-304` | PARCIAL; não testa `vagas < 1` |
| R27 | `api/lib/server.dart:241-254`; `api/test/server_test.dart:284-303` | SEM PROVA de edição; criação/capacidade exercitadas |
| R28 | `api/lib/server.dart:322-349`; sem inscrições no M1/teste | DEPENDÊNCIA M2+; sem prova comportamental |
| R29 | `specs/M1-grade-atividades.md:105-107`; sem inscrições no M1/teste | DEPENDÊNCIA M2+; sem prova comportamental |
| R30 | `specs/M1-grade-atividades.md:105-107`; sem inscrições no M1/teste | DEPENDÊNCIA M2+; sem prova comportamental |
| R31 | `api/lib/server.dart:322-349`; `api/test/server_test.dart:145-171` | COMPROVADA para aumento sem convocação M2 |
| R32 | `api/lib/server.dart:228-240`; `api/test/server_test.dart:55-78` | COMPROVADA |
| R33 | `api/lib/server.dart:228-240`; `api/test/server_test.dart:55-78` | COMPROVADA |
| R34 | `api/lib/server.dart:322-349`; `api/test/server_test.dart:161-165` | SEM PROVA completa; origem contratual |
| R35 | `api/lib/server.dart:322-349`; `api/test/server_test.dart:145-171` | COMPROVADA |
| R36 | `api/lib/server.dart:322-349`; `api/test/server_test.dart:306-327` | COMPROVADA |
| R37 | `api/lib/server.dart:331`; sem PATCH de atividade cancelada | SEM PROVA |
| R38 | `specs/M1-grade-atividades.md:125`; não exige precedência | COMPROVADA por ausência de exigência |
| R39 | `api/lib/server.dart:352-359`; `api/test/server_test.dart:202-209` | COMPROVADA |
| R40 | `api/lib/server.dart:352-359`; `api/test/server_test.dart:188-201` | COMPROVADA |
| R41 | `api/lib/server.dart:352-359`; sem teste de reativação | SEM PROVA |
| R42 | `api/lib/server.dart:352-359`; sem segundo cancelamento | SEM PROVA |
| R43 | `specs/M1-grade-atividades.md:135`; não exige precedência | COMPROVADA por ausência de exigência |
| R44 | `api/lib/server.dart:370-379`; `api/test/server_test.dart:194-196` | PARCIAL; só `em_andamento` foi exercitado |
| R45 | `api/lib/server.dart:370-379`; sem teste antes do início | SEM PROVA |
| R46 | `api/lib/server.dart:370-379`; `api/test/server_test.dart:188-196` | COMPROVADA |
| R47 | `api/lib/server.dart:370-379`; sem teste no fim do último encontro | SEM PROVA |
| R48 | `api/lib/server.dart:370-379`; cancelamento não testado após avanço do relógio | SEM PROVA |
| R49 | `api/lib/server.dart:382-398`; `api/test/server_test.dart:216-227` | COMPROVADA |
| R50 | `api/lib/server.dart:382-398`; `api/test/server_test.dart:216-227` | COMPROVADA |
| R51 | `api/lib/server.dart:382-398`; sem listagem não filtrada após cancelamento | SEM PROVA |
| R52 | `api/lib/server.dart:180-189`; sem teste de detalhe existente/cancelado | SEM PROVA; origem contratual |
| R53 | `api/lib/server.dart:400-421`; `api/test/server_test.dart:228-248` | COMPROVADA |
| R54 | `api/lib/server.dart:400-421`; sem teste de filtro por tipo | SEM PROVA; P-28/R2-P33 permanece não especificado para valor inválido |
| R55 | `api/lib/server.dart:400-421`; cliente em `frontend/test/api_client_test.dart:10-35`, sem resultado HTTP combinado | SEM PROVA |
| R56 | `api/lib/server.dart:102-146`; `api/test/server_test.dart:188-196` | COMPROVADA |
| R57 | `api/lib/server.dart:370-379`; `api/test/server_test.dart:188-196` | COMPROVADA |
| R58 | `api/lib/server.dart:370-379`; sem teste exatamente no fim | SEM PROVA |
| R59 | `api/lib/server.dart:400-421`; `api/test/server_test.dart:329-353` | COMPROVADA |

### Interface Flutter

| Item | Evidência | Resultado |
|---|---|---|
| ApiClient centralizado e `X-Usuario` | `frontend/lib/api_client.dart:32-81` | COMPROVADO; transporte centralizado e cabeçalho enviado |
| Usuários e papéis do contrato | `frontend/lib/api_client.dart:33-44`; `frontend/lib/main.dart:68-83` | COMPROVADO; dropdown usa a lista contratual |
| Participante somente leitura | `frontend/lib/main.dart:58-60`, `138-143`, `181-185`, `205-212`; `frontend/test/widget_test.dart:57-72` | PARCIAL; criação é testada, edição/cancelamento não são testados como proibidos |
| Ações da organização | `frontend/lib/main.dart:138-143`, `181-185`, `205-212` | Implementadas, sem cobertura completa das ações e erros |
| Salas por `GET /salas` | `frontend/lib/api_client.dart:98-99`; `frontend/lib/main.dart:243-250` | PARCIAL; chamada existe, sem teste e não há exibição adequada no detalhe |
| Filtros | `frontend/lib/api_client.dart:85-95`; `frontend/lib/main.dart:107-137`; `frontend/test/api_client_test.dart:10-35` | PARCIAL; envio testado, combinação/resultados visuais não |
| Detalhe | `frontend/lib/main.dart:193-215` | INCOMPLETO; mostra `salaId`, não nome/capacidade da sala nem encontros |
| Loading, erro, vazio e resultados | `frontend/lib/main.dart:147-162`; `frontend/test/widget_test.dart:11-55` | COMPROVADO |
| Testes e análise Flutter | `frontend/test/api_client_test.dart`, `frontend/test/widget_test.dart`; comandos abaixo | PARCIAL; análise passa, cobertura funcional permanece limitada |

## 3. Testes e análise executados

Resultados observados neste ambiente:

- `dart test` em `api`: passou, `00:00 +14: All tests passed!`.
- `flutter test` em `frontend`: passou, `00:01 +7: All tests passed!`.
- `dart analyze` em `api`: passou, `No issues found!`.
- `flutter analyze` em `frontend`: passou, `No issues found!`.
- `flutter build web` em `frontend`: não passou. O SDK instalado não contém `dart2wasm_product.snapshot` nem `dart2js_aot.dart.snapshot` em `/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/snapshots/`; a compilação web falhou antes de gerar o aplicativo.
- `dart test` na raiz: não aplicável, falhou por não haver `pubspec.yaml` na raiz.
- `flutter test` na raiz: não aplicável, falhou por não haver diretório `test` na raiz.

## 4. Limitações reais e dependências

- A suíte atual é verde, mas não cobre todos os cenários de aceitação. Permanecem sem prova direta IDs inexistentes, quantidades inválidas de encontros, sobreposição interna, duração máxima, redução de vagas com cada status de inscrição, PATCH/cancelamento repetido ou de cancelada, várias bordas do relógio, detalhe por ID, listagem não filtrada de canceladas e filtros por tipo/combinados.
- A rastreabilidade não é completa: R03, R04, R06, R07, R08, R09, R12, R13, R34 e R52 têm origem indicada apenas no contrato; R54 remete a P-28, cuja resposta de comportamento inválido permanece `PENDENTE`/não especificada na entrevista. Isso não inventa uma regra, mas impede considerar a rastreabilidade comprovada.
- `ocupadas`, `vagasRestantes`, `emEspera`, restrição de redução por inscrições e convocação automática após aumento de vagas pertencem às regras/estados de inscrições do M2, conforme `specs/M1-grade-atividades.md:173-182`. Não foram exigidos como implementação completa do M1.
- Cancelamento de inscrições ativas pertence ao M2; bloqueio de presença e certificados pertence, respectivamente, aos módulos de presença e M4. O M1 deve apenas persistir/expor `cancelada` e impedir nova edição/cancelamento conforme seu escopo.
- O build web está bloqueado pelo SDK ausente/incompleto, apesar de `flutter test` e `flutter analyze` passarem.

## 5. Veredito

**NÃO PASSOU.**

A implementação tem evidências suficientes para vários fluxos principais e todas as suítes executadas passam, mas a auditoria final não pode aceitar o M1: há requisitos R14-R16, R18, R20, R27-R30, R37, R41-R48, R51-R55 e R58 sem prova completa, lacunas de rastreabilidade entre entrevista e regras, cobertura Flutter insuficiente para salas/detalhe/filtros/ações e build web bloqueado pelo SDK. As dependências M2+ foram registradas e não foram tratadas como pendências de implementação do M1.
