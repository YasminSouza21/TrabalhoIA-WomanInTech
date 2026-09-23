## Matriz de rastreabilidade

| Regra | Origem | Teste que comprova | Suíte | Veredito |
|---|---|---|---|---|
| R01 | P-12 | `api/test/presenca_test.dart:382-395` «aplica autenticacao, papel e existencia antes das regras M3» cobre apenas GET de código | API | PROVA FRACA |
| R02 | P-12 | `api/test/presenca_test.dart:387-390` verifica participante recusado na rota de código, mas não cobre todas as combinações de rotas e papéis | API | PROVA FRACA |
| R03 | P-12 | `api/test/presenca_test.dart:391-395` verifica encontro inexistente na rota de código | API | PROVA FRACA |
| R04 | P-12 | `api/test/presenca_test.dart:280-301` cobre corpo malformado de QR e tipo inválido de `lidoEm`; `api/test/presenca_test.dart:259-278` cobre manual | API | PROVA FRACA |
| R05 | P-01, P-02 | `api/test/presenca_test.dart:61-79` verifica início inclusivo do código; `api/test/presenca_test.dart:81-105` verifica limites externos, mas não testa os limites inclusivos de presença QR e manual | API | PROVA FRACA |
| R06 | P-03, P-04 | `api/test/presenca_test.dart:81-90` verifica avanço de cinco minutos; não verifica que o código retornado mudou nem que o anterior foi rejeitado imediatamente | API | PROVA FRACA |
| R07 | P-03 | `api/test/presenca_test.dart:68-79` verifica formato de seis caracteres e repetição no mesmo bucket | API | COMPROVADA |
| R08 | P-11, P-12 | `api/test/presenca_test.dart:208-219` verifica atividade cancelada para obtenção do código; `api/test/presenca_test.dart:95-104` verifica código fora da janela, mas não registro de presença fora da janela | API | PROVA FRACA |
| R09 | P-06, P-08 | `api/test/presenca_test.dart:124-133` verifica QR online e `api/test/presenca_test.dart:151-160` verifica QR offline e origem `qr_offline` | API | COMPROVADA |
| R10 | P-07 | `api/test/presenca_test.dart:148-169` verifica tolerância de dez minutos e leitura futura, mas não verifica leitura passada além da tolerância | API | PROVA FRACA |
| R11 | P-08, P-11 | Não há teste que registre uma presença não duplicada com código inválido ou código antigo e espere `CODIGO_INVALIDO`; `api/test/presenca_test.dart:124-133` usa código inválido em uma duplicidade, e `api/test/presenca_test.dart:303-310` falha antes por sincronização | API | SEM PROVA |
| R12 | P-09, P-10 | `api/test/presenca_test.dart:114-133` verifica ausência de inscrição e inscrição criada, mas não cobre status não confirmado | API | PROVA FRACA |
| R13 | P-13, P-14 | `api/test/presenca_test.dart:124-133` verifica duplicidade QR preservando o primeiro JSON; `api/test/presenca_test.dart:187-205` verifica duplicidade manual preservando o primeiro registro | API | COMPROVADA |
| R14 | P-15 | `api/test/presenca_test.dart:187-193` usa participante confirmado em registro manual, mas não testa participante inexistente ou não confirmado | API | PROVA FRACA |
| R15 | P-16 | `api/test/presenca_test.dart:180-185` verifica justificativa curta; `api/test/presenca_test.dart:267-277` verifica ausência e tipo inválido, mas não verifica limite máximo nem texto somente com espaços | API | PROVA FRACA |
| R16 | P-02, P-05, P-11 | `api/test/presenca_test.dart:187-193` registra manual dentro da janela, mas não verifica `lidoEm`, `registradaEm` iguais ao relógio da API nem a janela manual fora dos limites | API | PROVA FRACA |
| R17 | P-17, P-18, P-19 | `api/test/presenca_test.dart:331-358` verifica duplicidade entre organizações e registro de outro participante | API | COMPROVADA |
| R18 | P-11, P-12 | `api/test/presenca_test.dart:215-219` verifica atividade cancelada ao obter código; `api/test/presenca_test.dart:245-257` verifica precedência de cancelamento em duplicidades, mas não registra nova presença cancelada | API | PROVA FRACA |
| R19 | P-12, P-13, P-16, P-19 | `api/test/presenca_test.dart:221-257` cobre cancelamento antes de duplicidade; `api/test/presenca_test.dart:180-205` cobre parte da precedência manual, mas não a sequência completa para todas as entradas | API | PROVA FRACA |
| R20 | P-22 | `api/test/presenca_test.dart:398-414` verifica listagem de uma presença; `api/test/presenca_test.dart:375-380` verifica que uma leitura após retrocesso ainda lista o registro, mas não testa ordenação com múltiplos registros nem ausência de mutação | API | PROVA FRACA |
| R21 | P-20 | `api/test/presenca_test.dart:398-422` verifica reset, remoção observável da atividade e restauração do relógio, mas não verifica separadamente presenças, sequências e estado de códigos nem isolamento do arquivo de produção | API | PROVA FRACA |
| R22 | P-20 | `api/test/presenca_test.dart:424-455` cria servidor com arquivo temporário, registra presença, reinicia e recupera o registro | API | COMPROVADA |
| R23 | P-21 | `api/test/presenca_test.dart:360-380` verifica que retroceder o relógio não remove presença materializada, mas não testa transições de código materializadas | API | PROVA FRACA |
| R24 | P-22 | `frontend/test/presencas_api_client_test.dart:20-66` verifica os quatro endpoints via `MockClient`; `frontend/test/presencas_widget_test.dart:13-56`, `58-102`, `104-167` e `169-188` cobrem código, QR offline, manual, vazio, loading, erro e sucesso | Frontend | COMPROVADA |

## Suíte

`dart test` na raiz do repositório → `No pubspec.yaml file found - run this command in your project folder.`

`flutter test` na raiz do repositório → `Test directory "test" not found.`

`dart test` em `api/` → `All tests passed!` — 92 testes observados.

`flutter test` em `frontend/` → `All tests passed!` — 45 testes observados.

## Achados

1. **[SEM PROVA] R11** — não existe teste que execute registro não duplicado com código inválido ou código antigo e verifique `422 CODIGO_INVALIDO`. O teste de `api/test/presenca_test.dart:127-133` envia código inválido somente depois que a primeira presença já existe, portanto exercita a precedência da duplicidade. O teste de `api/test/presenca_test.dart:303-310` usa `lidoEm` futuro e verifica `SINCRONIZACAO_TARDIA`, sem alcançar a validação do código.

2. **[PROVA FRACA] R01-R04** — o teste de precedência em `api/test/presenca_test.dart:382-395` cobre somente a rota GET de código. Não há comprovação equivalente para QR POST, manual POST e listagem GET em todas as combinações exigidas.

3. **[PROVA FRACA] R05** — os testes em `api/test/presenca_test.dart:61-105` exercitam obtenção de código, mas não registram presença QR ou manual exatamente nos limites inclusivos da janela.

4. **[PROVA FRACA] R06** — `api/test/presenca_test.dart:81-90` verifica apenas o horário de troca. Não compara o código anterior com o código do bucket seguinte nem tenta registrar usando o código anterior após a troca.

5. **[PROVA FRACA] R08 e R18** — os cenários de cancelamento em `api/test/presenca_test.dart:208-219` e `221-257` verificam principalmente obtenção de código e duplicidade. Não há teste de nova tentativa de registro QR ou manual em atividade cancelada.

6. **[PROVA FRACA] R10** — `api/test/presenca_test.dart:148-169` verifica tolerância no limite e leitura futura, mas não testa `lidoEm` passado com diferença superior a dez minutos.

7. **[PROVA FRACA] R12 e R14** — `api/test/presenca_test.dart:114-133` e `187-205` verificam ausência de inscrição e participante confirmado, mas não cobrem inscrições com status diferente de `confirmada` nem participante inexistente no registro manual.

8. **[PROVA FRACA] R15** — `api/test/presenca_test.dart:180-185` cobre justificativa curta e `267-277` cobre ausência e tipo inválido, mas não há cenário para justificativa com 500/501 caracteres ou somente espaços.

9. **[PROVA FRACA] R16** — o teste manual em `api/test/presenca_test.dart:187-205` verifica status, origem e justificativa, mas não verifica os valores de `lidoEm` e `registradaEm` nem a rejeição manual fora da janela.

10. **[PROVA FRACA] R19** — os testes de `api/test/presenca_test.dart:221-257` e `259-318` cobrem partes da precedência, porém não demonstram a ordem completa entre cancelamento, duplicidade, inscrição, sincronização, janela, código e justificativa em todos os endpoints.

11. **[PROVA FRACA] R20** — `api/test/presenca_test.dart:398-414` lista apenas uma presença. Não há cenário com múltiplas presenças em horários distintos para verificar ordenação, nem verificação explícita de que a listagem não altera o estado.

12. **[PROVA FRACA] R21** — `api/test/presenca_test.dart:415-422` verifica o reset por efeitos observáveis, mas não comprova individualmente a remoção de sequências e códigos nem que o arquivo de produção permaneça intocado em `MODO_TESTE=1`.

13. **[PROVA FRACA] R23** — `api/test/presenca_test.dart:360-380` cobre a permanência de uma presença após retrocesso, mas não cobre transições de bucket de código já materializadas.

14. **[PROVA FRACA] R24** — a cobertura de widget em `frontend/test/presencas_widget_test.dart:58-102` usa somente o fluxo QR offline; o fluxo QR online aparece apenas indiretamente no teste de transporte em `frontend/test/presencas_api_client_test.dart:42-52`. Não há teste de erro específico em cada uma das quatro ações, embora loading, vazio, erro e sucesso gerais estejam cobertos em `frontend/test/presencas_widget_test.dart:169-188`.

15. **[NÃO CONTRATADO]** — nenhum comportamento não contratado foi identificado nos testes ou nos trechos de implementação examinados.

## Veredito

Não pode ser aceito: R11 está sem prova, e R01-R06, R08, R10, R12, R14-R16, R18-R21 e R23-R24 ainda exigem testes que executem e verifiquem integralmente os cenários especificados.
