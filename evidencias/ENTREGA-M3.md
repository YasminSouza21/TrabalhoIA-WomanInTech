# Entrega M3 — Presenca por QR

## Decisoes aprovadas

- QR individual por encontro.
- Janela inclusiva de 15 minutos antes do inicio a 15 minutos depois do fim.
- Troca a cada 5 minutos, invalidacao imediata do codigo anterior.
- `lidoEm` vale para as regras; tolerancia offline de 10 minutos; leitura futura invalida.
- Presenca somente para inscricao `confirmada`; ausencia elegivel retorna `NAO_INSCRITO`.
- Duplicidade QR/manual retorna `200` com a primeira presenca preservada.
- Justificativa manual apos `trim`, entre 10 e 500 caracteres.
- Um registro manual por participante/encontro por organizacao, com limite compartilhado e duplicidade resolvida antes do limite.
- Presencas persistem fora de teste; reset limpa presencas/sequencias e restaura relogio.
- Flutter cobre obter QR, registrar QR, registrar manual e listar presencas.

## Implementacao

| Area | Arquivos e referencias |
|---|---|
| Entrevista/spec | `entrevistas/M3-presenca-qr.md`; `specs/M3-presenca-qr.md` |
| Modelo/persistencia | `api/lib/server.dart:28-64`, `api/lib/server.dart:170-313`, `api/lib/server.dart:325-379` |
| Rotas M3 | `api/lib/server.dart:483-510` |
| QR/janela/troca | `api/lib/server.dart:512-596` |
| Registro QR/manual | `api/lib/server.dart:620-781` |
| Listagem/serializacao | `api/lib/server.dart:783-817` |
| ApiClient | `frontend/lib/api_client.dart:54-206` |
| Tela Flutter | `frontend/lib/presencas_page.dart`; atalho integrado em `frontend/lib/main.dart` |
| Testes HTTP M3 | `api/test/presenca_test.dart` |
| Testes Flutter M3 | `frontend/test/presencas_api_client_test.dart`; `frontend/test/presencas_widget_test.dart` |
| Smoke | `api/tool/smoke_m3.dart` |

## Criterios cobertos

- Autenticacao, papel, encontro inexistente e envelope de erro.
- Corpos JSON malformados, tipos invalidos, timestamps invalidos, janela e codigo fora da regra.
- Janela inclusiva, troca de bucket e codigo deterministico de 6 caracteres.
- QR online, QR offline dentro da tolerancia, leitura futura e fora da janela.
- Inscricao confirmada, `NAO_INSCRITO`, atividade cancelada e idempotencia.
- Presenca manual, justificativa, duplicidade compartilhada e listagem.
- Reset, relogio controlado, persistencia JSON e reinicio da API.
- Retrocesso do relogio sem desfazer presenca materializada.
- ApiClient com `X-Usuario`, quatro rotas M3, QR offline com `lidoEm` e widget com loading/vazio/erro/sucesso.
- Rastreabilidade completa R01-R24 para P-01 a P-23 em `specs/M3-presenca-qr.md`.
- Regressao M1/M2 preservada pelas suites completas.

## Comandos e resultados

| Comando | Resultado |
|---|---|
| `dart test test/presenca_test.dart -r compact` | OK, 15 testes |
| `dart test` | OK, 92 testes |
| `dart analyze` | OK, sem issues |
| `dart run tool/smoke_m3.dart` | OK: QR, offline/idempotencia, corpos invalidos, precedencia de cancelamento, manual/justificativa, listagem e reset |
| `flutter test` | OK, 45 testes |
| `flutter analyze` | OK, sem issues |
| `flutter build web --release` | BLOQUEADO pelo SDK local: ausentes `dart2js_aot.dart.snapshot` e `dart2wasm_product.snapshot` |
| `node evidencias/exportar-evidencias.js` | Executado ao concluir a entrega |

## Limitações conhecidas

- O build web não pôde ser concluído neste ambiente porque a instalação local do
  Flutter 3.47.5 possui cache Dart incompleto (`dart2js_aot.dart.snapshot` e
  `dart2wasm_product.snapshot`); análise e testes Flutter passaram.
- O contrato contém `LIMITE_DE_MANUAIS`, mas as decisões aprovadas definem a chave
  participante/encontro e tornam tentativa duplicada idempotente, retornando `200`
  antes do limite. O teste HTTP prova que participantes diferentes ainda podem ter
  uma presença manual e que a duplicidade entre organizações preserva a primeira.
- A tela recebe o texto do QR; leitura por câmera não foi solicitada nem faz parte do
  contrato.

## Integridade do escopo

`contrato-api.md`, entrevistas e auditorias históricas de M1/M2 não foram
alterados. A spec do M3 recebeu apenas a matriz explícita de rastreabilidade
solicitada. Nenhum novo commit foi criado nesta etapa; o commit-base `83e625d`
já existia.
