# Correção TDD para rejeitar JSON extra em atividades

| | |
|---|---|
| Sessão | `ses_f38e4e25fffeSovqi8CuDkig5k` |
| Pasta | yasmindesouza/TrabalhoIA-WomanInTech |
| Período | 22/09 00:13 → 22/09 00:16 |
| Modelo | openai/gpt-5.6-luna |
| Requisições ao modelo | 19 |
| Tokens de entrada / saída | 58.252 / 4.189 |
| Skills | — |
| Subagentes | — |
| Execuções de teste | 2 vermelhas, 3 verdes |
| TDD | 0 ciclo(s) vermelho → verde · 0 teste(s) que já nasceram verdes · 0 vez(es) teste e código juntos |
| Arquivos editados | 0 de teste, 0 de código, 0 de entrevista, 0 de spec, 0 de contexto, 0 de auditoria |
| Alertas | — |

## Linha do tempo

- `22/09 00:13` **prompt** — Corrija a falha apontada em auditorias/M1-grade-atividades.md neste repositório, seguindo TDD em Go. Use apenas contrato-api.md, spec, código e testes existentes; não acesse nenhum documento externo de requisitos. Primeiro crie um teste HTTP com testing/httptest para POST /atividades rejeitar um corpo JSON válido seguido de conteúdo extra com 422 DADOS_INVALIDOS; rode apenas esse teste e confirme…
- `22/09 00:14` roda `go test -count=1 -run '^TestPOSTAtividadesRejeitaConteudoExtraAposJSON$'` → **vermelho**
- `22/09 00:15` roda `go test -count=1 -run '^TestPOSTAtividadesRejeitaConteudoExtraAposJSON$'` → verde
- `22/09 00:15` roda `go test -count=1 -run '^TestPATCHAtividadesRejeitaConteudoExtraAposJSON$'` → **vermelho**
- `22/09 00:15` roda `go test -count=1 -run '^TestPATCHAtividadesRejeitaConteudoExtraAposJSON$'` → verde
- `22/09 00:15` roda `go test -count=1 ./...` → verde
