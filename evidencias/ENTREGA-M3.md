# Entrega M3 — Presenca por QR

## Decisoes aprovadas

- QR individual por encontro.
- Janela inclusiva de 15 minutos antes do inicio a 15 minutos depois do fim.
- Troca a cada 5 minutos, invalidacao imediata do codigo anterior.
- `lidoEm` vale para as regras; tolerancia offline de 10 minutos; leitura futura invalida.
- Presenca somente para inscricao `confirmada`; ausencia elegivel retorna `NAO_INSCRITO`.
- Duplicidade QR/manual retorna `200` com a primeira presenca preservada.
- Justificativa manual apos `trim`, entre 10 e 500 caracteres.
- Um registro manual por participante/encontro por organizacao, com limite compartilhado.
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
- Janela inclusiva, troca de bucket e codigo deterministico de 6 caracteres.
- QR online, QR offline dentro da tolerancia, leitura futura e fora da janela.
- Inscricao confirmada, `NAO_INSCRITO`, atividade cancelada e idempotencia.
- Presenca manual, justificativa, duplicidade compartilhada e listagem.
- Reset, relogio controlado, persistencia JSON e reinicio da API.
- ApiClient com `X-Usuario`, quatro rotas M3 e widget com loading/vazio/sucesso.
- Regressao M1/M2 preservada pelas suites completas.

## Comandos e resultados

| Comando | Resultado |
|---|---|
| `dart test test/presenca_test.dart -r compact` | OK, 9 testes |
| `dart test` | OK, 87 testes |
| `dart analyze` | OK, sem issues |
| `dart run tool/smoke_m3.dart` | OK: QR, offline/idempotencia, manual, listagem, cancelamento e reset |
| `flutter test` | OK, 42 testes |
| `flutter analyze` | OK, sem issues |
| `flutter build web --release` | BLOQUEADO pelo SDK local: ausente `dart2js_aot.dart.snapshot` e `dart2wasm_product.snapshot` |
| `flutter precache --web` | Executado, sem reparar os snapshots ausentes |
| `flutter build web --release --no-wasm-dry-run` | BLOQUEADO pelo mesmo `dart2js_aot.dart.snapshot` ausente |
| `node evidencias/exportar-evidencias.js` | Executado ao concluir a entrega |

## Limitações conhecidas

- O build web não pôde ser concluído neste ambiente porque a instalação local do
  Flutter 3.47.5 possui cache Dart incompleto; análise e testes Flutter passaram.
- O contrato contém `LIMITE_DE_MANUAIS`, mas as decisões aprovadas tornam a tentativa
  duplicada idempotente e retornam `200` antes do limite. Assim, uma segunda tentativa
  válida não produz esse erro; o smoke prova a proteção pelo resultado idempotente.
- A tela recebe o texto do QR; leitura por câmera não foi solicitada nem faz parte do
  contrato.

## Integridade do escopo

`contrato-api.md`, specs, entrevistas e auditorias históricas de M1/M2 não foram
alterados. Nenhum commit foi criado.
