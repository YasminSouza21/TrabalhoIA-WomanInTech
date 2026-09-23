## Escopo e fontes

Auditoria somente leitura do estado atual do M3 após remediação. Foram lidos:

- `specs/M3-presenca-qr.md`
- `entrevistas/M3-presenca-qr.md`
- `projeto.json`
- `contrato-api.md`
- `api/lib/server.dart`
- `api/test/presenca_test.dart`
- `api/test/presenca_regressao_test.dart`
- todos os arquivos em `frontend/lib/`
- testes Flutter relacionados a presença
- `auditorias/M3-resolucao.md`
- `api/tool/smoke_m3.dart`

Os pareceres originais não foram alterados.

## Matriz de rastreabilidade

| Regra | Origem | Teste que comprova | Veredito |
|---|---|---|---|
| R01 | P-12 | `api/test/presenca_regressao_test.dart:76-100` cobre autenticação e papéis nas quatro rotas; `api/test/presenca_test.dart:382-395` cobre existência | PROVA FRACA |
| R02 | P-12 | `api/test/presenca_regressao_test.dart:89-100` verifica os papéis das quatro rotas | COMPROVADA |
| R03 | P-12 | `api/test/presenca_test.dart:391-395` verifica encontro inexistente na rota de código | PROVA FRACA |
| R04 | P-12 | `api/test/presenca_test.dart:259-278` e `280-301` verificam corpo manual e QR inválidos | PROVA FRACA |
| R05 | P-01, P-02 | `api/test/presenca_regressao_test.dart:121-162` verifica limites inclusivos de registro QR; `194-220` verifica janela manual parcialmente | PROVA FRACA |
| R06 | P-03, P-04 | `api/test/presenca_regressao_test.dart:102-119` rejeita código antigo após troca; `266-281` verifica mudança de bucket e retrocesso | COMPROVADA |
| R07 | P-03 | `api/test/presenca_test.dart:61-79` verifica formato, determinismo no bucket e `trocaEm`/`validoAte` | COMPROVADA |
| R08 | P-11, P-12 | `api/test/presenca_test.dart:81-105` cobre código fora da janela; `208-219` e `api/tool/smoke_m3.dart:166-174` cobrem código em atividade cancelada | PROVA FRACA |
| R09 | P-06, P-08 | `api/test/presenca_test.dart:124-160` verifica QR online e offline, incluindo `qr_offline` | COMPROVADA |
| R10 | P-07 | `api/test/presenca_test.dart:136-170` verifica tolerância e leitura futura; `api/test/presenca_regressao_test.dart:152-162` verifica leitura passada tardia | COMPROVADA |
| R11 | P-08, P-11 | `api/test/presenca_regressao_test.dart:102-119` verifica código antigo não duplicado; `api/tool/smoke_m3.dart:103-107` verifica código inválido | COMPROVADA |
| R12 | P-09, P-10 | `api/test/presenca_regressao_test.dart:164-192` verifica inscrição em espera, participante inexistente e `NAO_INSCRITO`; `api/test/presenca_test.dart:114-133` verifica confirmado | COMPROVADA |
| R13 | P-13, P-14 | `api/test/presenca_test.dart:124-133` cobre duplicidade QR; `187-205` cobre duplicidade manual preservando o primeiro JSON | COMPROVADA |
| R14 | P-15 | `api/test/presenca_regressao_test.dart:181-192` cobre participante manual inexistente, mas não manual com inscrição não confirmada | PROVA FRACA |
| R15 | P-16 | `api/test/presenca_regressao_test.dart:194-220` verifica vazio, 500 e 501 caracteres; `api/test/presenca_test.dart:259-278` cobre ausência e tipo inválido | COMPROVADA |
| R16 | P-02, P-05, P-11 | `api/test/presenca_regressao_test.dart:201-220` verifica timestamps do relógio controlado e saída fora da janela | PROVA FRACA |
| R17 | P-17, P-18, P-19 | `api/test/presenca_test.dart:321-358` verifica duplicidade compartilhada entre organizações e participante distinto; decisão detalhada em `auditorias/M3-resolucao.md:7-28` | COMPROVADA |
| R18 | P-11, P-12 | `api/test/presenca_test.dart:221-257` e `api/tool/smoke_m3.dart:117-125` verificam cancelamento antes de duplicidade; não há novo registro QR/manual após cancelamento | PROVA FRACA |
| R19 | P-12, P-13, P-16, P-19 | `api/test/presenca_test.dart:221-257` cobre cancelamento antes de duplicidade; `259-318` e `api/test/presenca_regressao_test.dart:194-220` cobrem partes das demais precedências | PROVA FRACA |
| R20 | P-22 | `api/test/presenca_regressao_test.dart:223-264` verifica múltiplos registros, ordenação, repetição da listagem e reset | COMPROVADA |
| R21 | P-20 | `api/test/presenca_test.dart:398-422` verifica reset, limpeza observável e relógio; `api/test/presenca_regressao_test.dart:283-295` verifica isolamento do arquivo de produção | COMPROVADA |
| R22 | P-20 | `api/test/presenca_test.dart:424-455` reinicia `ApiServer` com arquivo temporário e recupera a presença | COMPROVADA |
| R23 | P-21 | `api/test/presenca_test.dart:360-380` verifica presença após retrocesso; `api/test/presenca_regressao_test.dart:266-281` verifica transição de bucket materializada | COMPROVADA |
| R24 | P-22 | `frontend/test/presencas_api_client_test.dart:20-66` cobre os quatro endpoints; `frontend/test/presencas_widget_test.dart:13-188` e `frontend/test/presencas_erros_widget_test.dart:25-110` cobrem QR, manual, loading, vazio, erro e sucesso | COMPROVADA |

Todas as origens referenciadas existem na entrevista e estão respondidas como `Aceita`; não há perguntas `PENDENTE` (`entrevistas/M3-presenca-qr.md:8-32,36-38`).

## Lacunas e divergências

1. **[PROVA FRACA] R01** — os testes cobrem ausência do cabeçalho nas quatro rotas, mas não executam usuário desconhecido nas quatro rotas. Os casos de existência e papel estão parcialmente concentrados na rota de código (`api/test/presenca_regressao_test.dart:76-100`, `api/test/presenca_test.dart:382-395`).

2. **[PROVA FRACA] R03-R04** — existência e corpo inválido não são verificados em todas as combinações de rotas exigidas. Os testes de existência usam apenas `/codigo`, e os testes de corpo inválido concentram-se nos POSTs de QR/manual (`api/test/presenca_test.dart:259-301`).

3. **[PROVA FRACA] R05, R16** — há comprovação da borda inicial e de rejeição fora da janela, mas não há cenário manual exatamente no limite final inclusivo. Os casos manuais estão em `api/test/presenca_regressao_test.dart:201-220`.

4. **[PROVA FRACA] R08 e R18** — o cancelamento é testado para obtenção de código e para duplicidades, não para uma nova presença QR e uma nova presença manual após o cancelamento (`api/test/presenca_test.dart:208-219,221-257`; `api/tool/smoke_m3.dart:117-125`).

5. **[PROVA FRACA] R14** — há participante inexistente e participante não confirmado no fluxo QR, mas não há tentativa manual com participante existente cuja inscrição não esteja confirmada (`api/test/presenca_regressao_test.dart:164-192`).

6. **[PROVA FRACA] R19** — os testes cobrem trechos da precedência, mas não demonstram a sequência completa para QR e manual em cenários que combinem cancelamento, duplicidade, inscrição, sincronização, janela, código e justificativa (`api/test/presenca_test.dart:221-318`).

### Decisão documentada: `LIMITE_DE_MANUAIS`

O contrato ainda documenta `LIMITE_DE_MANUAIS` (`contrato-api.md:283-288`), mas `auditorias/M3-resolucao.md:7-28` registra decisão aprovada de que não existe cota adicional neste escopo.

A decisão é:

- a chave de idempotência é `(encontroId, participanteId)`;
- duplicidades são resolvidas antes de qualquer limite;
- organizações compartilham a mesma chave;
- participantes distintos podem registrar presença manual se confirmados e dentro das demais regras;
- o ramo `LIMITE_DE_MANUAIS` é inatingível no escopo aprovado.

Isso é uma **divergência documentada de produto**, não um achado novo. A implementação segue essa decisão ao resolver a duplicidade antes da criação (`api/lib/server.dart:644-689`).

## Suíte

```text
dart test em api/ → All tests passed! — 101 testes observados.
```

```text
flutter test em frontend/ → All tests passed! — 50 testes observados.
```

```text
dart analyze em api/ → No issues found!
```

```text
flutter analyze em frontend/ → No issues found! (ran in 5.5s)
```

```text
dart run tool/smoke_m3.dart em api/ → não executado; a ferramenta recusou a chamada por restrição do ambiente.
```

## Veredito

Não pode ser aceito ainda: R01, R03-R05, R08, R14, R16, R18 e R19 permanecem com prova fraca e exigem cenários adicionais que executem integralmente as condições especificadas.
