# Backend Dart - Semana Acadêmica

O backend é implementado em Dart com `dart:io`, mantendo estado em memória (modo de teste) ou em arquivo JSON local, sem banco ou serviço externo.

## Estrutura do Código

- `bin/server.dart`: ponto de entrada executável, porta `PORT` e `MODO_TESTE`.
- `lib/server.dart`: domínio M1+M2, roteamento HTTP, validações e serialização.
- `test/server_test.dart`: testes HTTP de comportamento com `package:test`.

## Escopo Autorizado

- **M1 — grade de atividades** (histórico preservado: specs e entrevistas do M1 não são alteradas pelo M2, apenas consumidas).
- **M2 — inscrições e lista de espera**: inscrever, cancelar, confirmar convocação, FIFO, expiração em cascata, contagens `ocupadas`/`vagasRestantes`/`emEspera`, persistência JSON (P-30) e modo de teste isolado (P-31).
- M3, M4 e M5 não são implementados.

## Modo de Teste

O sistema suporta um modo de teste ativado pela variável de ambiente `MODO_TESTE=1`. Neste modo, o relógio é manual e o estado pode ser resetado via API. A API inclui CORS mínimo para o Flutter web. Verificação por `dart test` pela interface HTTP (`ApiServer`), nunca importando serviço/repositório no teste.
