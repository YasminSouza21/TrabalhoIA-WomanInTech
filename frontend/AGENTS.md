# Frontend Flutter Web

O frontend usa Flutter web e `package:http`. O acesso à API deve passar pelo `ApiClient`, que centraliza a URL base configurável, JSON e o cabeçalho `X-Usuario`.

## Estrutura

- `lib/api_client.dart`: cliente HTTP injetável e modelos M1.
- `lib/main.dart`: tela responsiva da grade, filtros e ações da organização.
- `test/`: testes comportamentais com `flutter_test` e transporte HTTP injetável.

O frontend exibe estados calculados pela API e não replica regras de domínio. Participantes apenas consultam; criação, edição e cancelamento aparecem somente para organização.
