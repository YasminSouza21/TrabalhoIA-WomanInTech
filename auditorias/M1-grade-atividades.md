# Parecer de auditoria — M1 Grade de Atividades

## Veredito

**NÃO PASSOU**

Há cobertura ampla e a suíte passa, mas existem provas insuficientes para regras importantes, ausência de testes de borda exigidos e uma divergência na validação de corpos JSON malformados com conteúdo após o primeiro valor.

## Resumo executivo

- A implementação cobre as rotas M1 e os principais fluxos de criação, edição, cancelamento, listagem, filtros e relógio controlado.
- A suíte executada passou: `go test ./...` → `ok semana-academica (cached)`.
- Não foram encontrados testes de interface Flutter.
- As regras de conflito de sala, cancelamento, ocupação, edição e estados temporais possuem cobertura relevante.
- Faltam provas suficientes para:
  - ordenação dos encontros quando a entrada vem fora de ordem;
  - aumento de vagas;
  - bordas completas do período do evento, especialmente 23/10;
  - conversão efetiva do filtro por dia para Brasília;
  - detalhe de atividade cancelada;
  - algumas validações de corpo e tipos.
- A implementação aceita corpos JSON com conteúdo extra após o primeiro valor, contrariando a exigência de corpo malformado gerar `422 DADOS_INVALIDOS` (`api/atividades_handlers.go:123-128`, `api/atividades_handlers.go:417-421`).

## Método e fontes

Foram lidos:

- `specs/M1-grade-atividades.md`
- `entrevistas/M1-grade-atividades.md`
- `contrato-api.md`
- `AGENTS.md`
- `api/AGENTS.md`
- `projeto.json`
- toda a implementação em `api/`
- todos os testes existentes em `api/`

O arquivo `.opencode/agent/auditor.md` não foi encontrado. A ausência não altera o contrato usado nesta auditoria.

O comando definido em `projeto.json` foi executado dentro de `api/`:

```text
go test ./...
```

Não foram encontrados arquivos de teste de interface fora de `api/`.

## Matriz de rastreabilidade

| Regra | Origem | Teste que comprova | Implementação | Status |
|---|---|---|---|---|
| R01 | P-01, P-02 | `api/atividades_test.go:76-159`, `api/atividades_test.go:162-348` | Rotas M1 em `api/main.go:21-23` | COMPROVADA |
| R02 | P-04 | `api/atividades_test.go:299-303`, `api/atividades_test.go:331-347`, `api/main_test.go:77-120` | Inicialização/reset em `api/store.go:57-90` | COMPROVADA |
| R03 | contrato-api.md | `api/atividades_test.go:166-204`, `api/atividades_test.go:299-303` | Autorização de leitura em `api/atividades_handlers.go:95-116`, `353-403` | COMPROVADA |
| R04 | contrato-api.md | `api/atividades_test.go:110-115`, `206-225`, `251-275` | Rotas de organização em `api/atividades_handlers.go:119-120`, `405-407`, `476-477` | COMPROVADA |
| R05 | P-02, R2-P24 | Não há teste de integração com M2/M3/M4 | M1 não registra rotas desses módulos em `api/main.go:10-23` | SEM PROVA — dependência legítima de outros módulos |
| R06 | contrato-api.md | `api/atividades_test.go:110-115`, `166-170`, `186-203`, `206-212`, `251-257` | `api/atividades_handlers.go:305-318` | COMPROVADA |
| R07 | contrato-api.md | `api/atividades_test.go:110-115`, `206-212`, `251-257` | `api/atividades_handlers.go:314-316` | COMPROVADA |
| R08 | contrato-api.md | `api/atividades_test.go:186-204`, `206-212`, `251-257` | `api/atividades_handlers.go:392-397`, `409-415`, `480-485` | COMPROVADA |
| R09 | contrato-api.md | JSON inválido testado em `api/atividades_test.go:117-122`; tipos específicos têm cobertura parcial em `api/atividades_test.go:220-225` | Decodificação em `api/atividades_handlers.go:123-128`, `417-421`, `439-451` | PROVA FRACA |
| R10 | P-03, R2-P01 | Criação de palestra e minicurso em `api/atividades_test.go:80-108`; rejeição de quantidades em `124-134` | `api/atividades_handlers.go:153-161` | COMPROVADA |
| R11 | R2-P01 | Há uma palestra e um minicurso válidos em `api/atividades_test.go:80-108`, mas não há teste comparando explicitamente regras comuns | Validação compartilhada em `api/atividades_handlers.go:163-180` | PROVA FRACA |
| R12 | contrato-api.md | Não há entrada fora de ordem verificando a resposta | Ordenação em `api/atividades_handlers.go:202`, `260-263` | SEM PROVA |
| R13 | contrato-api.md | `api/atividades_test.go:80-108` | Criação e `201` em `api/atividades_handlers.go:119-151` | COMPROVADA |
| R14 | P-05, R2-P02, R2-P38 | `api/atividades_test.go:124-129` | `api/atividades_handlers.go:157-159` | COMPROVADA |
| R15 | P-05, R2-P02, R2-P38 | `api/atividades_test.go:130-134` e criação válida em `101-108` | `api/atividades_handlers.go:160-162` | COMPROVADA |
| R16 | P-07, R2-P05, R2-P37 | Fora do período em `api/atividades_test.go:136-147` | `api/atividades_handlers.go:207-219` | COMPROVADA |
| R17 | P-31, R2-P35 | Critério de aceitação textual em `specs/M1-grade-atividades.md:223`; os testes não exigem precedência conjunta | Ordem existente em `api/atividades_handlers.go:153-185` | COMPROVADA como regra de não exigência |
| R18 | P-06, R2-P03, R2-P37 | Duração menor/maior em `api/atividades_test.go:136-147` | `api/atividades_handlers.go:220-223` | COMPROVADA |
| R19 | R2-P37, R2-P40 | Travessia de meia-noite em `api/atividades_test.go:141-147` | `api/atividades_handlers.go:209-212` | COMPROVADA |
| R20 | R2-P37 | Sobreposição interna em `api/atividades_test.go:142-147` | `api/atividades_handlers.go:224-226` | COMPROVADA |
| R21 | P-10, R2-P09 | Sobreposição entre atividades em `api/atividades_test.go:155-157` | `api/atividades_handlers.go:231-244`, `247-249` | COMPROVADA |
| R22 | P-11, R2-P09, R2-P10 | Intervalo de 14 minutos em `api/atividades_test.go:157` | `api/atividades_handlers.go:251-255` | COMPROVADA |
| R23 | R2-P12, R2-P40 | 14 minutos recusa e 15 minutos aceita em `api/atividades_test.go:157-158` | `api/atividades_handlers.go:251-255` | COMPROVADA |
| R24 | R2-P12 | Não há teste específico com `fim == inicio` | A condição conflita em `api/atividades_handlers.go:247-255` | SEM PROVA |
| R25 | P-12, R2-P11 | Cancelamento seguido de criação no mesmo horário em `api/atividades_test.go:258-268` | Atividades canceladas ignoradas em `api/atividades_handlers.go:231-234` | COMPROVADA |
| R26 | P-13, P-14, R2-P08, R2-P13 | Capacidade e zero em `api/atividades_test.go:150-154`; edição em `220-225` | `api/atividades_handlers.go:166-178`, `453-458` | COMPROVADA |
| R27 | R2-P08, contrato-api.md | Criação e edição acima da capacidade em `api/atividades_test.go:153`, `223` | `api/atividades_handlers.go:176-178`, `457-459` | COMPROVADA |
| R28 | P-15, R2-P14 | Redução abaixo de ocupadas em `api/atividades_test.go:227-248` | `api/atividades_handlers.go:454-463` | COMPROVADA |
| R29 | R2-P16 | `confirmada` e `convocada` injetadas em `api/atividades_test.go:231-240` | `api/atividades_handlers.go:288-300` | COMPROVADA |
| R30 | R2-P16 | `em_espera`, `cancelada` e `expirada` injetadas em `api/atividades_test.go:235-240` | `api/atividades_handlers.go:295-300` | COMPROVADA |
| R31 | R2-P15 | Não há teste de aumento de vagas após criação | PATCH permite atribuição em `api/atividades_handlers.go:447-466` | SEM PROVA |
| R32 | P-06, R2-P04 | Soma de carga em `api/atividades_test.go:80-108` | Cálculo em `api/atividades_handlers.go:264-268` | COMPROVADA |
| R33 | R2-P04 | Campo incorreto ignorado na criação em `api/atividades_test.go:54-56`, `80-108`; edição em `212-218` | Campo não existe no modelo de entrada e carga é recalculada em `api/atividades_handlers.go:264-269` | COMPROVADA |
| R34 | contrato-api.md | PATCH válido em `api/atividades_test.go:212-218` | `api/atividades_handlers.go:468-473` | COMPROVADA |
| R35 | P-16, R2-P17 | Alteração de título e vagas em `api/atividades_test.go:212-218` | `api/atividades_handlers.go:439-466` | COMPROVADA |
| R36 | P-17, R2-P18 | Tentativas para `salaId`, `tipo` e `encontros` em `api/atividades_test.go:220-222` | `api/atividades_handlers.go:422-432` | PROVA FRACA |
| R37 | R2-P20 | Edição de cancelada em `api/atividades_test.go:265-266` | `api/atividades_handlers.go:434-436` | COMPROVADA |
| R38 | P-31, R2-P36 | Não há exigência de precedência conjunta, conforme `specs/M1-grade-atividades.md:223` | Validações em `api/atividades_handlers.go:422-463` | COMPROVADA como regra de não exigência |
| R39 | P-18, R2-P21, contrato-api.md | Cancelamento antes do início em `api/atividades_test.go:251-268` | `api/atividades_handlers.go:492-502` | COMPROVADA |
| R40 | P-18, R2-P21 | Instante exato e após início em `api/atividades_test.go:269-275` | `api/atividades_handlers.go:492-496` | COMPROVADA |
| R41 | P-19, R2-P22, R2-P28 | Segundo cancelamento e edição após cancelamento em `api/atividades_test.go:265-268` | Flag definitiva em `api/atividades_handlers.go:33`, `487-500` | COMPROVADA |
| R42 | P-20, R2-P23 | Segundo cancelamento em `api/atividades_test.go:265` | `api/atividades_handlers.go:487-490` | COMPROVADA |
| R43 | P-31, R2-P36 | Não há exigência de precedência conjunta, conforme `specs/M1-grade-atividades.md:223` | Ordem em `api/atividades_handlers.go:487-496` | COMPROVADA como regra de não exigência |
| R44 | P-22, R2-P25 | Estados verificados em `api/atividades_test.go:277-297` | `api/atividades_handlers.go:272-285` | COMPROVADA |
| R45 | P-23, R2-P26 | Antes do início em `api/atividades_test.go:282-288` | `api/atividades_handlers.go:278-280` | COMPROVADA |
| R46 | P-23, R2-P26 | Instante de início em `api/atividades_test.go:282-288` | `api/atividades_handlers.go:278-285` | COMPROVADA |
| R47 | P-23, R2-P26 | Instante do fim em `api/atividades_test.go:282-288` | `api/atividades_handlers.go:281-285` | COMPROVADA |
| R48 | P-19, P-22, P-23, R2-P28 | Cancelada permanece cancelada após avanço do relógio em `api/atividades_test.go:291-297` | Prioridade de `Cancelada` em `api/atividades_handlers.go:272-275` | COMPROVADA |
| R49 | P-25, R2-P29 | Ordenação em `api/atividades_test.go:305-313` | `api/atividades_handlers.go:371-378` | COMPROVADA |
| R50 | P-25, R2-P29 | Empate por título em `api/atividades_test.go:305-313` | `api/atividades_handlers.go:374-376` | COMPROVADA |
| R51 | P-26, R2-P30 | Cancelada aparece na listagem em `api/atividades_test.go:308-315` | Listagem não exclui canceladas em `api/atividades_handlers.go:359-369` | COMPROVADA |
| R52 | P-26, R2-P31, contrato-api.md | Detalhe existente em `api/atividades_test.go:186-203`; não testa detalhe cancelado | `api/atividades_handlers.go:388-403` | PROVA FRACA |
| R53 | P-27, R2-P32 | Filtro por dia em `api/atividades_test.go:320-327`, mas sem borda UTC/Brasília efetiva | Conversão para Brasília em `api/atividades_handlers.go:518-525` | PROVA FRACA |
| R54 | P-28, contrato-api.md | Filtro por tipo em `api/atividades_test.go:317-319` | `api/atividades_handlers.go:357-365` | COMPROVADA |
| R55 | P-29, R2-P32 | Filtro combinado em `api/atividades_test.go:323-325` | Aplicação simultânea em `api/atividades_handlers.go:357-369` | COMPROVADA |
| R56 | P-30, contrato-api.md | Alterações do relógio em `api/atividades_test.go:277-297`; reset em `api/main_test.go:77-120` | `api/store.go:44`, `92-101`; uso em `api/atividades_handlers.go:146-150`, `359-360` | COMPROVADA |
| R57 | P-24, R2-P27, R2-P40 | Instante inicial em `api/atividades_test.go:282-288` | `api/atividades_handlers.go:278-285` | COMPROVADA |
| R58 | P-24, R2-P27, R2-P40 | Instante final em `api/atividades_test.go:282-288` | `api/atividades_handlers.go:281-285` | COMPROVADA |
| R59 | P-07, R2-P05 | Há teste de 19/10 e rejeição de 24/10 em `api/atividades_test.go:136-147`; não há teste de 23/10 | Limites inclusivos implementados em `api/atividades_handlers.go:214-218` | PROVA FRACA |
| R60 | R2-P15, R2-P24, contrato-api.md | Campos calculados verificados em `api/atividades_test.go:86-94`, `216-218`, `245-248` | Modelo de resposta e cálculos em `api/atividades_handlers.go:37-49`, `260-269`, `288-302` | COMPROVADA |

## Regras aprovadas

Foram consideradas comprovadas pela combinação de teste e implementação:

- R01–R04
- R06–R10
- R13–R16
- R18–R23
- R25–R30
- R32–R35
- R37
- R39–R51
- R54–R58
- R60

As regras R17, R38 e R43 foram consideradas atendidas como regras de não exigência de precedência, conforme o critério de aceitação da spec.

## Regras sem teste suficiente

1. **R05** — não há teste demonstrando explicitamente a separação de responsabilidades com M2/M3/M4. A ausência é uma dependência legítima de outros módulos, não uma exigência para implementar esses fluxos no M1.
2. **R12** — nenhum teste cria encontros fora de ordem e verifica que a resposta os ordena por início.
3. **R24** — não há cenário específico para `fim == inicio`.
4. **R31** — não há teste que aumente vagas e verifique que a operação é aceita.
5. **R52** — o teste consulta uma atividade existente, mas não uma atividade cancelada.
6. **R53** — o teste de dia não usa um horário próximo à virada UTC/Brasília; portanto, não comprova efetivamente que a data considerada é a de Brasília.
7. **R59** — não há teste do limite superior inclusivo, 23/10/2026.
8. **R09** — a prova cobre JSON inválido simples, mas não corpos com conteúdo extra, campos inválidos ou todas as combinações de tipo incorreto.

## Divergências de implementação

### 1. Corpo JSON com conteúdo extra é aceito

A criação executa apenas um `Decode` e não verifica se existe conteúdo após o primeiro JSON (`api/atividades_handlers.go:123-128`). A edição tem o mesmo comportamento (`api/atividades_handlers.go:417-421`).

Assim, um corpo como:

```text
{"titulo":"x", ...} lixo
```

pode ser aceito, embora o contrato exija `422 DADOS_INVALIDOS` para corpo que não seja JSON válido (`contrato-api.md:15-17`).

Esse problema também não é coberto pela suíte.

### 2. Testes de campos imutáveis usam valores com tipos inválidos

O teste tenta alterar `salaId`, `tipo` e `encontros` usando `"x"` para todos os campos (`api/atividades_test.go:220-222`). A implementação retorna `CAMPO_NAO_EDITAVEL` antes de validar o tipo (`api/atividades_handlers.go:422-432`).

Isso prova a precedência implementada para aquele payload, mas não comprova adequadamente a regra com valores estruturalmente válidos.

## Dependências legítimas de outros módulos

A spec explicitamente deixa fora do M1:

- fluxo de inscrições e lista de espera;
- convocação automática;
- atualização de inscrições ao cancelar;
- código de presença;
- certificados;
- painel da organização.

A implementação usa uma estrutura mínima de inscrições somente para calcular ocupação (`api/store.go:36-49`, `api/atividades_handlers.go:288-302`). Não foi considerado defeito o fato de as rotas completas de M2, M3, M4 e M5 não existirem.

## Problemas críticos

1. **[DIVERGÊNCIA] Validação incompleta de JSON** — corpos com JSON válido seguido de lixo podem ser aceitos em criação e edição (`api/atividades_handlers.go:123-128`, `417-421`).
2. **[SEM PROVA] Regra R12** — a ordenação de encontros, embora implementada em `api/atividades_handlers.go:202` e `260-263`, não é exercitada com entrada fora de ordem.
3. **[SEM PROVA] Regra R31** — não há teste do aumento de vagas, embora seja comportamento explicitamente contratado.
4. **[PROVA FRACA] Regra R53** — a exigência específica de dia de Brasília não é demonstrada por uma borda de conversão de fuso.

## Problemas não críticos

1. **R24** não possui teste dedicado para `fim == inicio`; a implementação aparenta tratar o caso como conflito em `api/atividades_handlers.go:251-255`.
2. **R52** não testa detalhe de atividade cancelada.
3. **R59** não testa o último dia inclusivo, 23/10/2026.
4. **R36** usa payloads de tipos incorretos para provar campos imutáveis.
5. Não há testes de interface, embora `projeto.json` declare Flutter web na stack.

## Comportamentos não especificados inventados

Os seguintes comportamentos são implementados sem contratação específica na spec:

1. `GET /atividades?tipo=<valor inválido>` retorna `200 []` ou uma lista filtrada vazia, pois o valor é apenas comparado textualmente em `api/atividades_handlers.go:357-365`.
2. `GET /atividades?dia=<formato inválido>` retorna lista vazia, pois a implementação compara a string diretamente com datas formatadas em `api/atividades_handlers.go:518-525`.
3. `vagas < 1` retorna `422 DADOS_INVALIDOS` em criação e edição (`api/atividades_handlers.go:172-175`, `447-451`), embora a spec preserve esse código como não especificado.
4. Campos desconhecidos no JSON são ignorados; isso decorre da decodificação em structs/mapas sem rejeição de campos extras (`api/atividades_handlers.go:123-128`, `417-421`).

Esses comportamentos não devem ser tratados como falhas contratuais quando a spec explicitamente os classifica como não especificados, mas devem ser registrados como decisões não contratadas.

## Suíte

```text
go test ./...
```

```text
ok  semana-academica (cached)
```

A saída observada não informa quantidade de testes executados.

## Conclusão

**NÃO PASSOU.** Para aceite, é necessário corrigir a validação de corpos JSON com conteúdo extra e acrescentar provas suficientes para R12, R24, R31, R52, R53 e R59, especialmente aumento de vagas, ordenação de encontros fora de ordem, `fim == início`, conversão de dia em Brasília e o limite inclusivo de 23/10/2026.
