# Parecer de auditoria pos-correcao - M1 Grade de Atividades

## Veredito

**NAO PASSOU**

A correcao do defeito de aceitar JSON valido seguido de conteudo extra foi
confirmada em POST e PATCH, com testes dedicados para os dois caminhos. A
suíte passa. O M1 ainda nao tem prova suficiente para todas as regras
contratadas: permanecem sem teste dedicado R12, R24 e R31, alem de provas
fracas para R09, R11, R36 e R59. Essas lacunas sao do M1; a ausencia dos
fluxos completos de M2, M3 e M4 nao foi considerada falha deste modulo.

## Escopo e fontes

Foram considerados somente os artefatos solicitados:

- `specs/M1-grade-atividades.md`
- `entrevistas/M1-grade-atividades.md`
- `contrato-api.md`
- todos os arquivos de implementacao e testes em `api/`
- `auditorias/M1-grade-atividades.md`, apenas para comparar a situacao anterior

Nenhum documento externo de requisitos foi usado. A auditoria anterior foi
preservada intacta.

## Correcao auditada: JSON com conteudo extra

### POST

- `api/atividades_handlers.go:124-134` decodifica o primeiro valor JSON e faz
  um segundo `Decode`; somente `io.EOF` e aceito. Qualquer segundo valor,
  texto ou outro conteudo gera `422 DADOS_INVALIDOS`.
- `api/atividades_test.go:76-83`,
  `TestPOSTAtividadesRejeitaConteudoExtraAposJSON`, envia um objeto valido
  seguido de `{}` e verifica `422 DADOS_INVALIDOS`.

### PATCH

- `api/atividades_handlers.go:423-432` aplica a mesma verificacao ao corpo de
  PATCH, antes das regras de edicao.
- `api/atividades_test.go:85-93`,
  `TestPATCHAtividadesRejeitaConteudoExtraAposJSON`, cria uma atividade,
  envia `{"titulo":"Novo titulo"} {}` e verifica `422 DADOS_INVALIDOS`.

Conclusao especifica: o defeito apontado em
`auditorias/M1-grade-atividades.md:142-154` foi corrigido nos dois endpoints e
passou a ter cobertura automatizada nos dois endpoints.

## Matriz de rastreabilidade

| Regra | Origem | Implementacao | Evidencia de teste | Status |
|---|---|---|---|---|
| R01 | P-01/P-02 | `api/main.go:21-23` | `api/atividades_test.go:95-178,318-348` | COMPROVADA |
| R02 | P-04 | `api/store.go:57-90` | `api/main_test.go:77-120`, `api/atividades_test.go:350-367` | COMPROVADA |
| R03 | contrato, rotas M1 | `api/atividades_handlers.go:96-117,359-408` | `api/atividades_test.go:185-223,318-347` | COMPROVADA |
| R04 | contrato, rotas M1 | `api/atividades_handlers.go:120-122,411-414,488-490` | `api/atividades_test.go:129-134,225-244,270-294` | COMPROVADA |
| R05 | P-02/R2-P24 | Escopo M1 em `api/main.go:21-23` | Sem integracao M2/M3/M4 | DEPENDENCIA FUTURA, NAO FALHA M1 |
| R06 | contrato | `api/atividades_handlers.go:311-318` | `api/atividades_test.go:129-134,185-188,205-223,270-276` | COMPROVADA |
| R07 | contrato | `api/atividades_handlers.go:320-323` | `api/atividades_test.go:129-134,225-230,270-276` | COMPROVADA |
| R08 | contrato | `api/atividades_handlers.go:394-403,415-420,492-497` | `api/atividades_test.go:205-223,225-230,270-276` | COMPROVADA |
| R09 | contrato | `api/atividades_handlers.go:124-134,423-432` | JSON invalido `136-141`; extra `76-93` | PROVA PARCIAL |
| R10 | P-03/R2-P01 | `api/atividades_handlers.go:159-162` | `api/atividades_test.go:99-127,143-152` | COMPROVADA |
| R11 | R2-P01 | Validacao comum `169-189` | Casos validos `99-127` | PROVA FRACA |
| R12 | contrato | Ordenacao em `208,266-269` | Nenhum teste com entrada fora de ordem | SEM PROVA |
| R13 | contrato | `api/atividades_handlers.go:141-156` | `api/atividades_test.go:67-74,99-127` | COMPROVADA |
| R14 | P-05/R2-P02/R2-P38 | `api/atividades_handlers.go:163-165` | `api/atividades_test.go:143-148` | COMPROVADA |
| R15 | P-05/R2-P02/R2-P38 | `api/atividades_handlers.go:166-168` | `api/atividades_test.go:149-152` | COMPROVADA |
| R16 | P-07/R2-P05/R2-P37 | `api/atividades_handlers.go:220-224` | `api/atividades_test.go:155-166` | COMPROVADA |
| R17 | P-31/R2-P35 | Nao ha precedencia exigida; spec: `specs/M1-grade-atividades.md:79,223` | Criterio de aceitacao | COMPROVADA COMO NAO-EXIGENCIA |
| R18 | P-06/R2-P03/R2-P37 | `api/atividades_handlers.go:226-228` | `api/atividades_test.go:155-166` | COMPROVADA |
| R19 | R2-P37/R2-P40 | `api/atividades_handlers.go:214-219` | `api/atividades_test.go:155-166` | COMPROVADA |
| R20 | R2-P37 | `api/atividades_handlers.go:230-232` | `api/atividades_test.go:161-166` | COMPROVADA |
| R21 | P-10/R2-P09 | `api/atividades_handlers.go:237-249` | `api/atividades_test.go:174-175` | COMPROVADA |
| R22 | P-11/R2-P09/R2-P10 | `api/atividades_handlers.go:253-262` | `api/atividades_test.go:174-177` | COMPROVADA |
| R23 | R2-P12/R2-P40 | `api/atividades_handlers.go:253-262` | `api/atividades_test.go:176-177` | COMPROVADA |
| R24 | R2-P12 | `api/atividades_handlers.go:253-262` | Nenhum caso `fim == inicio` | SEM PROVA |
| R25 | P-12/R2-P11 | `api/atividades_handlers.go:237-240` | `api/atividades_test.go:270-287` | COMPROVADA |
| R26 | P-13/P-14/R2-P08/R2-P13 | `api/atividades_handlers.go:172-185,459-470` | `api/atividades_test.go:169-177,231-243` | COMPROVADA |
| R27 | R2-P08/contrato | `api/atividades_handlers.go:182-185,469-471` | `api/atividades_test.go:172,242` | COMPROVADA |
| R28 | P-15/R2-P14 | `api/atividades_handlers.go:473-475` | `api/atividades_test.go:246-266` | COMPROVADA |
| R29 | R2-P16 | `api/atividades_handlers.go:301-305` | `api/atividades_test.go:250-266` | COMPROVADA |
| R30 | R2-P16 | `api/atividades_handlers.go:301-306` | `api/atividades_test.go:250-266` | COMPROVADA |
| R31 | R2-P15 | `api/atividades_handlers.go:459-478` | Nenhum teste de aumento de vagas | SEM PROVA |
| R32 | P-06/R2-P04 | `api/atividades_handlers.go:270-275` | `api/atividades_test.go:99-127` | COMPROVADA |
| R33 | R2-P04 | `api/atividades_handlers.go:24-30,266-275` | `api/atividades_test.go:99-108,231-237` | COMPROVADA |
| R34 | contrato | `api/atividades_handlers.go:480-485` | `api/atividades_test.go:231-237` | COMPROVADA |
| R35 | P-16/R2-P17 | `api/atividades_handlers.go:451-478` | `api/atividades_test.go:225-244` | COMPROVADA |
| R36 | P-17/R2-P18 | `api/atividades_handlers.go:434-444` | `api/atividades_test.go:239-241` | PROVA FRACA |
| R37 | R2-P20 | `api/atividades_handlers.go:446-448` | `api/atividades_test.go:284-285` | COMPROVADA |
| R38 | P-31/R2-P36 | Precedencia nao exigida; spec: `specs/M1-grade-atividades.md:125,223` | Criterio de aceitacao | COMPROVADA COMO NAO-EXIGENCIA |
| R39 | P-18/R2-P21/contrato | `api/atividades_handlers.go:504-514` | `api/atividades_test.go:270-287` | COMPROVADA |
| R40 | P-18/R2-P21 | `api/atividades_handlers.go:504-508` | `api/atividades_test.go:288-294` | COMPROVADA |
| R41 | P-19/R2-P22 | `api/atividades_handlers.go:499-511` | `api/atividades_test.go:284-287,310-315` | COMPROVADA |
| R42 | P-20/R2-P23 | `api/atividades_handlers.go:499-502` | `api/atividades_test.go:284` | COMPROVADA |
| R43 | P-31/R2-P36 | Precedencia nao exigida; spec: `specs/M1-grade-atividades.md:135,223` | Criterio de aceitacao | COMPROVADA COMO NAO-EXIGENCIA |
| R44 | P-22/R2-P25 | `api/atividades_handlers.go:278-291` | `api/atividades_test.go:296-315` | COMPROVADA |
| R45 | P-23/R2-P26 | `api/atividades_handlers.go:284-285` | `api/atividades_test.go:301-307` | COMPROVADA |
| R46 | P-23/R2-P26 | `api/atividades_handlers.go:284-291` | `api/atividades_test.go:301-307` | COMPROVADA |
| R47 | P-23/R2-P26 | `api/atividades_handlers.go:287-289` | `api/atividades_test.go:301-307` | COMPROVADA |
| R48 | P-19/P-22/P-23/R2-P28 | `api/atividades_handlers.go:278-281` | `api/atividades_test.go:310-315` | COMPROVADA |
| R49 | P-25/R2-P29 | `api/atividades_handlers.go:377-384` | `api/atividades_test.go:324-331` | COMPROVADA |
| R50 | P-25/R2-P29 | `api/atividades_handlers.go:380-382` | `api/atividades_test.go:324-331` | COMPROVADA |
| R51 | P-26/R2-P30 | `api/atividades_handlers.go:365-376` | `api/atividades_test.go:327-334` | COMPROVADA |
| R52 | P-26/R2-P31/contrato | `api/atividades_handlers.go:394-408` | `api/atividades_test.go:205-223` | COMPROVADA para detalhe existente |
| R53 | P-27/R2-P32 | `api/atividades_handlers.go:530-537` | `api/atividades_test.go:324-347` | COMPROVADA |
| R54 | P-28/contrato | `api/atividades_handlers.go:363-371` | `api/atividades_test.go:336-337` | COMPROVADA |
| R55 | P-29/R2-P32 | `api/atividades_handlers.go:369-374` | `api/atividades_test.go:342-343` | COMPROVADA |
| R56 | P-30/contrato | `api/store.go:44,66,92-101`; handlers `366,405` | `api/atividades_test.go:296-315`, `api/main_test.go:16-57` | COMPROVADA |
| R57 | P-24/R2-P27/R2-P40 | `api/atividades_handlers.go:284-291` | `api/atividades_test.go:301-307` | COMPROVADA |
| R58 | P-24/R2-P27/R2-P40 | `api/atividades_handlers.go:287-289` | `api/atividades_test.go:301-307` | COMPROVADA |
| R59 | P-07/R2-P05 | `api/atividades_handlers.go:220-224` | Testa 19/10 e rejeita 24/10 em `155-166`; nao testa 23/10 | PROVA FRACA |
| R60 | R2-P15/R2-P24/contrato | `api/atividades_handlers.go:266-275,294-308` | `api/atividades_test.go:99-108,231-266` | COMPROVADA para exposicao M1 |

## Achados e lacunas remanescentes

1. **R12 - sem prova:** a implementacao ordena os encontros em
   `api/atividades_handlers.go:208` e `266-269`, mas nenhum teste envia
   encontros fora de ordem e verifica a ordem retornada.
2. **R24 - sem prova:** `encontrosConflitam` trata `fim == inicio` como
   conflito em `api/atividades_handlers.go:253-262`, mas nao existe cenario
   dedicado em `api/atividades_test.go`.
3. **R31 - sem prova:** o PATCH permite aumento de vagas em
   `api/atividades_handlers.go:459-478`, mas nao ha teste que aumente vagas e
   confira o resultado.
4. **R09 - prova parcial:** a nova cobertura confirma conteudo extra no POST e
   PATCH, mas nao cobre de forma explicita campo obrigatorio ausente e todas as
   combinacoes de tipos errados.
5. **R11 - prova fraca:** ha casos validos de palestra e minicurso, mas nao ha
   teste demonstrando que duracao, capacidade e sala seguem as mesmas regras
   para os dois tipos.
6. **R36 - prova fraca:** o teste tenta alterar `salaId`, `tipo` e `encontros`
   sempre com o valor string `"x"` (`api/atividades_test.go:239-241`). Isso
   prova a recusa pelo nome do campo, mas nao com valores estruturalmente
   validos para cada campo do contrato.
7. **R59 - prova fraca:** a implementacao aceita dias 19 a 23 em
   `api/atividades_handlers.go:220-224`, mas os testes nao exercitam
   explicitamente o limite superior inclusivo de 23/10/2026.
8. **R52 - risco de cobertura:** a spec nao define comportamento especial para
   detalhe de atividade cancelada (N05). O teste comprova detalhe existente,
   mas nao consulta uma atividade cancelada; isso nao e uma falha contratual
   comprovada.
9. **Filtros invalidos e `vagas < 1`:** a implementacao escolhe
   comportamentos para pontos que a spec marca como nao especificados em
   `specs/M1-grade-atividades.md:184-197`. Sao riscos de comportamento nao
   contratado, nao falhas classificadas do M1.

## Dependencias futuras, separadas de falhas M1

Nao foram classificadas como falha do M1:

- inscricoes, lista de espera e convocacao automatica, que pertencem ao M2;
- atualizacao de inscricoes ativas ao cancelar, que pertence ao M2;
- codigo de presenca, que pertence ao M3;
- certificados, que pertencem ao M4.

A spec explicita essas fronteiras em `specs/M1-grade-atividades.md:28-38` e
`173-182`. O M1 apenas expoe os campos calculados necessarios ao consumo
futuro, usando o modelo minimo de inscricoes em `api/store.go:36-49` e
`api/atividades_handlers.go:294-308`.

As falhas de aceite deste parecer sao exclusivamente as lacunas de prova do
M1 listadas em R12, R24, R31, R09, R11, R36 e R59.

## Testes executados

Comando executado em `api/`, conforme a configuracao do repositorio:

```text
go test ./...
```

Resultado:

```text
ok    semana-academica    (cached)
```

Os testes novos de conteudo extra estao em
`api/atividades_test.go:76-93` e foram incluidos na execucao da suíte.
Nao foram encontrados testes de interface Flutter no repositorio auditado.

## Status do Git

Status observado durante a auditoria, antes da criacao deste relatorio:

```text
 M api/atividades_handlers.go
 M api/atividades_test.go
 M evidencias/sessoes/yasminsouza21/INDICE.md
?? evidencias/sessoes/yasminsouza21/ses_f38e23ff3ffe2wolkCb2kbRKaw.json
?? evidencias/sessoes/yasminsouza21/ses_f38e23ff3ffe2wolkCb2kbRKaw.md
?? evidencias/sessoes/yasminsouza21/ses_f38e4e25fffeSovqi8CuDkig5k.json
?? evidencias/sessoes/yasminsouza21/ses_f38e4e25fffeSovqi8CuDkig5k.md
?? evidencias/sessoes/yasminsouza21/ses_f38f4949effeMH4U268gEv13a2.json
?? evidencias/sessoes/yasminsouza21/ses_f38f4949effeMH4U268gEv13a2.md
```

Essas alteracoes ja estavam presentes e nao foram modificadas pela auditoria.
O novo arquivo `auditorias/M1-grade-atividades-pos-correcao.md` foi o unico
arquivo criado nesta auditoria. Nenhum commit foi feito.

## Conclusao

**NAO PASSOU.** A correcao solicitada esta correta e comprovada em POST e
PATCH, e a suíte passa. O aceite integral do M1 continua impedido pelas
lacunas de cobertura listadas acima, especialmente R12, R24 e R31.
