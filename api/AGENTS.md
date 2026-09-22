# Backend Dart - Semana Acadêmica

O backend é implementado em Dart com `dart:io`, mantendo estado em memória e sem banco ou serviço externo.

## Estrutura do Código

- `bin/server.dart`: ponto de entrada executável, porta `PORT` e `MODO_TESTE`.
- `lib/server.dart`: domínio M1, roteamento HTTP, validações e serialização.
- `test/server_test.dart`: testes HTTP de comportamento com `package:test`.

## Modo de Teste

O sistema suporta um modo de teste ativado pela variável de ambiente `MODO_TESTE=1`. Neste modo, o relógio é manual e o estado pode ser resetado via API. A API inclui CORS mínimo para o Flutter web. M2, M3, M4 e M5 não são implementados neste backend M1.
