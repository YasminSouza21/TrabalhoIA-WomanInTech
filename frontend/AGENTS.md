# Frontend Flutter Web

O frontend usa Flutter web e `package:http`. O acesso à API deve passar pelo `ApiClient`, que centraliza a URL base configurável, JSON, o cabeçalho `X-Usuario` e um transporte HTTP injetável.

## Estrutura

- `lib/api_client.dart`: cliente HTTP injetável e modelos M1 e M2.
- `lib/main.dart`: tela responsiva da grade (M1), "Minhas inscrições" e detalhe/confirmação (M2).
- `test/`: testes comportamentais com `flutter_test` e transporte HTTP fake (`MockClient` de `package:http/testing`) — nunca HTTP real.

## Escopo Autorizado

- **M1 — grade** (histórico preservado): consulta, filtros e ações da organização.
- **M2 — inscrições**: "Minhas inscrições" do participante com todos os status, posição na espera, prazo e contagem regressiva de convocação; consulta da organização; inscrever/cancelar no detalhe da atividade; confirmar convocação; estados de carregamento, vazio, erro e sucesso — tudo via `ApiClient`.
- **M3 — presença por QR**: obter código e listar presenças para organização; registrar QR online/offline para participante; registrar manual para organização; estados de carregamento, vazio, erro e sucesso — tudo via `ApiClient`.

O frontend exibe estados calculados pela API e não replica regras de domínio. Verificação por `flutter test` com testes de `ApiClient` e de widget contra HTTP fake.
