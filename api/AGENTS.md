# Backend - Semana Acadêmica

O backend é implementado em Go utilizando apenas a biblioteca padrão `net/http` para manter a arquitetura simples e sem dependências externas, conforme exigido.

## Estrutura do Código

- `main.go`: Ponto de entrada, configuração do servidor e rotas.
- `store.go`: Estado em memoria com usuarios, salas e relogio.
- `teste_handlers.go`: Manipuladores das rotas `/_teste/*`.
- `main_test.go`: Testes HTTP com `testing` e `httptest`.

## Modo de Teste

O sistema suporta um modo de teste ativado pela variável de ambiente `MODO_TESTE=1`. Neste modo, o relógio é manual e o estado pode ser resetado via API.
