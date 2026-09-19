# Entrevista — M1 Grade de Atividades

## Rodada 1

| # | Pergunta | Resposta | Fonte |
|---|---|---|---|
| P-01 | Qual é o objetivo principal do M1 para a organização e para os participantes? | Para a organização, permitir organizar e manter a grade de atividades da Semana Acadêmica. Para os participantes, permitir consultar as atividades e seus horários. | Usuária |
| P-02 | O M1 deve cobrir apenas cadastro e consulta da grade, deixando inscrições, presença e certificados fora deste módulo? | Sim. O M1 deve ficar focado na grade de atividades, salas, encontros, vagas exibidas e cancelamento da atividade. Inscrições, presença e certificados ficam para outros módulos. | Usuária |
| P-03 | O contrato lista `palestra` e `minicurso`. Existe alguma regra diferente entre esses tipos no M1, além do nome do tipo? | PENDENTE. Existem os tipos `palestra` e `minicurso`, mas ainda não se sabe quais regras específicas mudam entre eles. | Usuária |
| P-04 | O M1 deve iniciar sem nenhuma atividade cadastrada, usando apenas usuários e salas iniciais do contrato? | Sim. Pelo contrato, o sistema começa sem atividades cadastradas e mantém apenas os usuários e salas iniciais. | Usuária |
| P-05 | Para criar uma atividade, qual é a quantidade mínima e máxima de encontros permitida para `palestra` e para `minicurso`? | PENDENTE. Ainda não se sabe a quantidade mínima e máxima de encontros para palestra e minicurso. | Usuária |
| P-06 | Existe duração mínima ou máxima por encontro? A duração total da atividade é simplesmente a soma dos encontros? | PENDENTE para duração mínima e máxima de cada encontro. A carga horária total possivelmente é calculada pela soma da duração dos encontros, mas essa regra precisa ser confirmada. | Usuária |
| P-07 | As atividades só podem acontecer entre 19/10/2026 e 23/10/2026, dentro de algum intervalo de horário diário específico? | PENDENTE. Sabe-se que o evento acontece entre 19/10/2026 e 23/10/2026, mas ainda não se sabe se existe faixa específica de horário permitida em cada dia. | Usuária |
| P-08 | Quais salas podem receber atividades no M1? Todas as salas do contrato podem ser usadas ou alguma deve ficar fora? | PENDENTE. As salas disponíveis são as cadastradas no contrato, mas ainda não se sabe se alguma delas deve ficar fora do uso do M1. | Usuária |
| P-09 | Existe alguma restrição de sala por tipo de atividade? Por exemplo, alguma sala só pode receber palestra ou só pode receber minicurso? | PENDENTE. Ainda não se sabe se existe restrição de sala específica para palestra ou minicurso. | Usuária |
| P-10 | Quando dois encontros na mesma sala devem ser considerados conflitantes? | Existe conflito quando dois encontros usam a mesma sala em horários que se sobrepõem. Ainda não se sabe se existe regra adicional além da sobreposição. | Usuária |
| P-11 | Deve existir algum intervalo mínimo entre o fim de um encontro e o início de outro na mesma sala? | PENDENTE. Ainda não se sabe se existe intervalo mínimo obrigatório entre um encontro e outro na mesma sala. | Usuária |
| P-12 | Atividades canceladas continuam bloqueando sala e causando conflito de horário? | PENDENTE. Ainda não se sabe se uma atividade cancelada continua bloqueando a sala para conflito de horário. | Usuária |
| P-13 | Existe uma quantidade mínima ou máxima de vagas que uma atividade pode ter? | PENDENTE. Ainda não se sabe a quantidade mínima ou máxima de vagas permitida para uma atividade. | Usuária |
| P-14 | A quantidade de vagas da atividade deve respeitar a capacidade da sala? | PENDENTE. A usuária imagina que a quantidade de vagas deva respeitar a capacidade da sala, mas essa regra ainda precisa ser confirmada. | Usuária |
| P-15 | Depois que já existirem inscrições em uma atividade, o que deveria acontecer ao tentar editar o número de vagas? | PENDENTE. Ainda não se sabe o que deve acontecer ao reduzir ou aumentar as vagas depois que já existem inscrições. | Usuária |
| P-16 | Quais campos de uma atividade deveriam poder ser alterados depois da criação? | PENDENTE. Ainda não se sabe exatamente quais campos podem ser alterados depois que a atividade já foi criada. | Usuária |
| P-17 | Quais campos deveriam permanecer imutáveis depois da criação? | PENDENTE. Ainda não se sabe quais campos obrigatoriamente devem permanecer imutáveis depois da criação. | Usuária |
| P-18 | Até quando uma atividade pode ser cancelada? | PENDENTE. Ainda não se sabe até qual momento uma atividade pode ser cancelada. | Usuária |
| P-19 | Uma atividade cancelada pode ser reativada? | PENDENTE. A usuária imagina que uma atividade cancelada não deveria ser reativada, mas essa regra precisa ser confirmada. | Usuária |
| P-20 | O que deve acontecer se tentarem cancelar uma atividade que já está cancelada? | PENDENTE. Ainda não se sabe o comportamento exato se tentarem cancelar uma atividade já cancelada. | Usuária |
| P-21 | O cancelamento de uma atividade deveria afetar outras partes do sistema, como inscrições futuras, presença ou certificados? | PENDENTE. A usuária imagina que o cancelamento possa afetar inscrições, presença e certificados, mas isso envolve outros módulos e precisa de confirmação. | Usuária |
| P-22 | Quais estados uma atividade pode ter no M1? | PENDENTE. A usuária entende que os estados podem ser algo como `prevista`, `em_andamento`, `encerrada` e `cancelada`, mas isso precisa ser confirmado oficialmente. | Usuária |
| P-23 | Em que momento uma atividade muda de um estado para outro? | PENDENTE. A usuária imagina que a atividade fique prevista antes de começar, em andamento quando chegar ao início e encerrada depois que terminar, mas ainda precisa confirmar as regras exatas. | Usuária |
| P-24 | Exatamente no instante de início ou de fim de um encontro, qual estado a atividade deve assumir? | PENDENTE. Ainda não se sabe qual estado vale exatamente no instante de início e no instante de fim. | Usuária |
| P-25 | Como as atividades deveriam ser ordenadas em `GET /atividades`? | PENDENTE. A usuária imagina ordenação pela data e horário de início, mas ainda não sabe o critério de desempate. | Usuária |
| P-26 | Atividades canceladas devem aparecer em `GET /atividades` e `GET /atividades/:id`? | PENDENTE. A usuária imagina que atividades canceladas ainda possam aparecer na listagem e no detalhe, mas precisa confirmar. | Usuária |
| P-27 | O filtro `?dia=AAAA-MM-DD` deve incluir uma atividade quando qualquer encontro dela ocorre no dia filtrado? | PENDENTE. A usuária acha que sim, o filtro por dia deveria incluir a atividade quando pelo menos um dos encontros acontecer naquele dia, mas precisa confirmar oficialmente. | Usuária |
| P-28 | O filtro `?tipo=palestra|minicurso` deve aceitar apenas esses dois valores? O que deve acontecer com outro valor? | PENDENTE. Sabe-se que os tipos são `palestra` e `minicurso`, mas ainda não se sabe o comportamento exato para outro valor. | Usuária |
| P-29 | Quando `dia` e `tipo` forem usados juntos, os dois filtros devem ser aplicados ao mesmo tempo? | Sim. Quando `dia` e `tipo` forem enviados juntos, os dois filtros devem ser aplicados ao mesmo tempo. | Usuária |
| P-30 | Todas as regras de tempo do M1 devem usar o relógio do modo de teste quando `MODO_TESTE=1`? | Sim. As regras de tempo do M1 devem usar o relógio controlado quando o modo de teste estiver ativo. | Usuária |
| P-31 | Quando uma mesma operação viola mais de uma regra específica do M1, qual erro deve ter prioridade? | PENDENTE. Ainda não se sabe qual erro deve ter prioridade quando uma operação viola mais de uma regra do M1 ao mesmo tempo. | Usuária |
| P-32 | Quais cenários você considera obrigatórios para validar o M1 antes de aceitar a entrega? | Validar pelo menos criação de atividade válida, palestra e minicurso, encontros inválidos, conflito de sala, vagas inválidas, edição, cancelamento, mudança de estado pelo relógio, listagem, filtros e consulta por ID. Os comportamentos exatos ainda precisam ser confirmados. | Usuária |

## Pontos Confirmados

1. O objetivo para a organização é organizar e manter a grade de atividades da Semana Acadêmica.
2. O objetivo para os participantes é consultar atividades e horários.
3. O M1 fica restrito a grade de atividades, salas, encontros, vagas exibidas e cancelamento de atividade.
4. Inscrições, presença e certificados ficam fora do M1.
5. O sistema inicia sem atividades cadastradas.
6. Os dados iniciais do M1 são apenas os usuários e salas definidos no contrato.
7. O evento ocorre entre 19/10/2026 e 23/10/2026.
8. Existe conflito de sala quando dois encontros usam a mesma sala em horários sobrepostos.
9. Quando `dia` e `tipo` forem enviados juntos em `GET /atividades`, os dois filtros devem ser aplicados ao mesmo tempo.
10. Regras de tempo do M1 devem usar o relógio controlado quando `MODO_TESTE=1`.
11. Cenários considerados importantes para validação: criação válida, palestra e minicurso, encontros inválidos, conflito de sala, vagas inválidas, edição, cancelamento, mudança de estado pelo relógio, listagem, filtros e consulta por ID.

## Pontos Pendentes

1. Regras específicas que diferenciam `palestra` e `minicurso` no M1.
2. Quantidade mínima e máxima de encontros para palestra.
3. Quantidade mínima e máxima de encontros para minicurso.
4. Duração mínima e máxima de cada encontro.
5. Confirmação de que `cargaHorariaMinutos` é a soma das durações dos encontros.
6. Faixa de horário permitida para atividades em cada dia do evento.
7. Se alguma sala cadastrada no contrato deve ficar fora do M1.
8. Restrições de sala por tipo de atividade.
9. Regras adicionais de conflito além de sobreposição de horários.
10. Intervalo mínimo obrigatório entre encontros na mesma sala.
11. Se atividades canceladas continuam causando conflito de sala.
12. Quantidade mínima e máxima de vagas por atividade.
13. Confirmação de que vagas devem respeitar a capacidade da sala.
14. Efeito de inscrições existentes sobre aumento ou redução de vagas.
15. Campos editáveis depois da criação.
16. Campos imutáveis depois da criação.
17. Prazo ou condição para cancelar atividade.
18. Se uma atividade cancelada pode ser reativada.
19. Comportamento ao cancelar uma atividade já cancelada.
20. Efeitos do cancelamento sobre inscrições, presença e certificados.
21. Confirmação oficial dos estados de atividade.
22. Regras exatas de transição entre estados.
23. Estado válido exatamente nas bordas de início e fim.
24. Ordenação exata de `GET /atividades`, incluindo critério de desempate.
25. Se atividades canceladas aparecem na listagem e no detalhe.
26. Confirmação oficial do comportamento do filtro por dia.
27. Comportamento quando `?tipo=` recebe valor diferente de `palestra` ou `minicurso`.
28. Precedência entre erros específicos do M1 quando mais de uma regra é violada.
29. Comportamentos exatos dos cenários de validação obrigatórios.

## Rodada 2

### Bloco 1 — Tipo, encontros, duração e carga horária

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P01 | P-03 | Diferenças entre `palestra` e `minicurso` no M1. | Se `palestra` e `minicurso` têm regras diferentes de quantidade de encontros, duração, vagas, sala, inscrição, carga horária ou qualquer outra regra do M1. | Diferem na quantidade de encontros. Palestra tem exatamente 1 encontro e minicurso tem de 2 a 5 encontros. As demais regras de duração, vagas e sala do M1 são comuns aos dois tipos. | A Rodada 1 sabia que existiam os tipos, mas não sabia quais regras mudavam. A Rodada 2 especificou que a diferença é apenas na quantidade de encontros, mantendo duração, vagas e sala comuns. | CORRIGIDO | RN-102 e RN-103 |
| R2-P02 | P-05 | Quantidade mínima e máxima de encontros para `palestra` e `minicurso`. | Mínimo e máximo de encontros para `palestra` e para `minicurso`. | Palestra: mínimo 1, máximo 1. Minicurso: mínimo 2, máximo 5. | A Rodada 1 registrou essa quantidade como desconhecida. A Rodada 2 definiu os limites exatos. | CORRIGIDO | RN-102 e RN-103 |
| R2-P03 | P-06 | Duração mínima e máxima por encontro. | Duração mínima e máxima de cada encontro, e se varia por tipo. | Cada encontro deve ter no mínimo 1 hora e no máximo 4 horas, igual para palestra e minicurso. | A Rodada 1 registrou a duração mínima e máxima como desconhecidas. A Rodada 2 definiu os limites e confirmou que são comuns aos dois tipos. | CORRIGIDO | RN-104 |
| R2-P04 | P-06 | Cálculo da carga horária total da atividade. | Como calcular `cargaHorariaMinutos`. | `cargaHorariaMinutos` é a soma das durações de todos os encontros, em minutos. A organização não informa esse valor; se `cargaHorariaMinutos` for enviado, ele é ignorado. | A Rodada 1 levantou a hipótese de soma das durações, mas sem confirmação. A Rodada 2 confirmou a soma e acrescentou a regra de ignorar valor enviado pela organização. | CONFIRMADO | RN-109 |

### Bloco 2 — Horários, salas e capacidade

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P05 | P-07 | Faixa de horário diária permitida para atividades. | Horário mínimo e máximo permitido em cada dia do evento, e se encontros podem começar ou terminar exatamente nas bordas. | NÃO ESPECIFICADO. O documento define apenas que os encontros devem ocorrer entre 19/10/2026 e 23/10/2026 e começar e terminar no mesmo dia, mas não define uma faixa diária de horário específica. | A Rodada 1 conhecia o período do evento, mas não sabia se havia faixa diária. A Rodada 2 confirmou que a faixa diária não está especificada. | NÃO ESPECIFICADO | RN-105 |
| R2-P06 | P-08 | Salas disponíveis para atividades no M1. | Quais salas cadastradas podem receber atividades no M1. | NÃO ESPECIFICADO. O documento não define que alguma das salas cadastradas fique fora do M1 nem lista um subconjunto específico de salas permitidas. | A Rodada 1 sabia que as salas cadastradas existem, mas não sabia se todas poderiam ser usadas. A Rodada 2 confirmou que não há subconjunto especificado. | NÃO ESPECIFICADO | Documento oficial |
| R2-P07 | P-09 | Restrição de sala por tipo de atividade. | Se `palestra` ou `minicurso` exigem ou proíbem alguma sala específica. | NÃO ESPECIFICADO. O documento não define restrição de sala específica para palestra ou minicurso. | A Rodada 1 registrou a restrição por tipo como desconhecida. A Rodada 2 confirmou que ela não está especificada. | NÃO ESPECIFICADO | Documento oficial |
| R2-P08 | P-14 | Relação entre vagas e capacidade da sala. | Se `vagas` pode ser maior que a capacidade da sala e qual erro ocorre. | Vagas devem ser no mínimo 1 e no máximo iguais à capacidade da sala. Se ultrapassarem a capacidade, o erro é `VAGAS_ACIMA_DA_CAPACIDADE`. | A Rodada 1 levantou a hipótese de que vagas deveriam respeitar a capacidade. A Rodada 2 confirmou essa hipótese e acrescentou o mínimo de 1 vaga. | CONFIRMADO | RN-107 |

### Bloco 3 — Conflito de sala

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P09 | P-10 | Regras adicionais de conflito de sala além de sobreposição. | Se conflito é apenas sobreposição na mesma sala ou se há outras regras adicionais. | Existe uma regra adicional. Na mesma sala, além de não poder haver sobreposição, deve existir pelo menos 15 minutos entre o fim de um encontro e o início do próximo. | A Rodada 1 confirmou conflito por sobreposição, mas deixava regras adicionais pendentes. A Rodada 2 corrigiu a regra para incluir também intervalo mínimo de 15 minutos. | CORRIGIDO | RN-108 |
| R2-P10 | P-11 | Intervalo mínimo obrigatório entre encontros na mesma sala. | Se há intervalo mínimo obrigatório entre encontros na mesma sala. | Intervalo mínimo de 15 minutos entre encontros na mesma sala. | A Rodada 1 registrou o intervalo mínimo como desconhecido. A Rodada 2 definiu o valor exato. | CORRIGIDO | RN-108 |
| R2-P11 | P-12 | Efeito de atividades canceladas sobre conflito de sala. | Se encontros de atividade cancelada continuam participando da regra de conflito de sala. | Encontros de atividades canceladas não contam para conflito de sala. | A Rodada 1 registrou o comportamento como desconhecido. A Rodada 2 definiu que atividade cancelada não bloqueia sala. | CORRIGIDO | RN-108 |
| R2-P12 | P-10 e P-11 | Bordas de conflito entre encontros na mesma sala. | Se um encontro terminando exatamente no instante em que outro começa na mesma sala é conflito ou permitido. | `fim == início` é conflito, porque não existe o intervalo mínimo de 15 minutos. Exemplo oficial: se um encontro termina às 10:00, outro às 10:14 ainda gera `CONFLITO_DE_SALA`; às 10:15 é permitido. | A Rodada 1 não especificava as bordas de conflito. A Rodada 2 definiu que o limite permitido exige pelo menos 15 minutos completos. | NOVO | RN-108 |

### Bloco 4 — Vagas e inscrições

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P13 | P-13 | Quantidade mínima e máxima de vagas por atividade. | Limite mínimo e máximo de `vagas`, independente da capacidade da sala. | Mínimo 1; máximo igual à capacidade da sala. | A Rodada 1 registrou mínimo e máximo como desconhecidos. A Rodada 2 definiu o mínimo e vinculou o máximo à capacidade da sala. | CORRIGIDO | RN-107 |
| R2-P14 | P-15 | Redução de vagas quando já existem inscrições. | Se é permitido reduzir `vagas` abaixo de inscritos ou ocupadas, e qual erro ocorre. | Não pode reduzir as vagas para um número menor do que a quantidade de inscrições que ocupam vaga. O erro é `VAGAS_ABAIXO_DOS_INSCRITOS`. | A Rodada 1 registrou o efeito de inscrições existentes como desconhecido. A Rodada 2 definiu a restrição e o erro. | CORRIGIDO | RN-111 |
| R2-P15 | P-15 | Aumento de vagas quando já existem inscrições. | Se aumentar `vagas` após inscrições é permitido e se convoca lista de espera automaticamente. | É permitido aumentar vagas. Ao aumentar vagas, as novas vagas podem convocar automaticamente pessoas da lista de espera, seguindo a regra de convocação. | A Rodada 1 registrou o efeito de inscrições existentes como desconhecido. A Rodada 2 definiu que aumento é permitido e pode acionar convocação automática. | CORRIGIDO | RN-111 e RN-211 |
| R2-P16 | P-15 | Contagem usada para impedir redução de vagas. | Quais inscrições contam para impedir redução de vagas: confirmadas, convocadas, em espera, canceladas, expiradas. | Contam como ocupando vaga as inscrições `confirmadas` e `convocadas`. Não contam `em_espera`, `canceladas` nem `expiradas`. | A Rodada 1 não separava quais status ocupam vaga. A Rodada 2 introduziu essa regra de contagem. | NOVO | Documento oficial |

### Bloco 5 — Edição de atividade

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P17 | P-16 | Campos editáveis depois da criação. | Quais campos de `PATCH /atividades/:id` podem ser alterados. | Apenas `titulo` e `vagas` podem ser alterados depois da criação. | A Rodada 1 registrou os campos editáveis como desconhecidos. A Rodada 2 definiu exatamente quais são editáveis. | CORRIGIDO | RN-110 |
| R2-P18 | P-17 | Campos imutáveis depois da criação. | Quais campos não podem ser alterados e qual erro ocorre. | `sala`, `tipo` e `encontros` são imutáveis depois da criação. Se houver tentativa de alteração, o erro é `CAMPO_NAO_EDITAVEL`. | A Rodada 1 registrou os campos imutáveis como desconhecidos. A Rodada 2 definiu os campos e o erro. | CORRIGIDO | RN-110 |
| R2-P19 | P-16, P-17 e P-23 | Edição de atividade iniciada, em andamento ou encerrada. | Se uma atividade já iniciada, em andamento ou encerrada pode ser editada. | NÃO ESPECIFICADO. O documento não cria uma proibição geral de editar atividade apenas por ela já ter iniciado ou encerrado. A restrição explícita é sobre atividade cancelada e sobre quais campos são editáveis. | A Rodada 1 não havia levantado uma regra específica de edição por início ou encerramento. A Rodada 2 confirmou que essa proibição geral não está especificada. | NÃO ESPECIFICADO | Documento oficial |
| R2-P20 | P-19, P-20 e contrato | Edição de atividade cancelada. | O que ocorre ao tentar alterar atividade cancelada. | Não pode editar atividade cancelada. O erro é `ATIVIDADE_CANCELADA`. | A Rodada 1 imaginava que atividade cancelada não deveria ser reativada, mas não especificava edição de cancelada. A Rodada 2 definiu explicitamente a proibição de edição. | NOVO | RN-113 |

### Bloco 6 — Cancelamento

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P21 | P-18 | Prazo ou condição para cancelar atividade. | Condição temporal para cancelar atividade e erro quando não puder. | O cancelamento só pode acontecer antes de a atividade começar. Se ela já começou, o erro é `ATIVIDADE_JA_INICIADA`. | A Rodada 1 registrou o prazo ou condição como desconhecido. A Rodada 2 definiu a condição temporal e o erro. | CORRIGIDO | RN-112 |
| R2-P22 | P-19 | Reativação de atividade cancelada. | Se há transição de `cancelada` para outro estado. | Não pode ser reativada. O cancelamento é definitivo. | A Rodada 1 levantou a hipótese de que atividade cancelada não deveria ser reativada. A Rodada 2 confirmou essa hipótese. | CONFIRMADO | RN-113 |
| R2-P23 | P-20 | Cancelar atividade já cancelada. | Status e erro ao chamar cancelamento em atividade já cancelada. | Não pode cancelar novamente uma atividade já cancelada. O erro é `ATIVIDADE_CANCELADA`. | A Rodada 1 registrou o comportamento como desconhecido. A Rodada 2 definiu a proibição e o erro. | CORRIGIDO | RN-113 |
| R2-P24 | P-21 | Efeitos do cancelamento sobre inscrições, presença, certificados e operações futuras. | Efeitos do cancelamento sobre inscrições existentes, lista de espera, presença, certificados e operações futuras. | Ao cancelar a atividade, todas as inscrições ativas são canceladas. Não é possível fazer novas inscrições em atividade cancelada. A atividade cancelada também não pode emitir certificado e não permite obter código de presença. Além disso, ela não pode mais ser alterada nem cancelada novamente. | A Rodada 1 imaginava que o cancelamento poderia afetar inscrições, presença e certificados, mas sem confirmação. A Rodada 2 confirmou e detalhou os efeitos. | CONFIRMADO | RN-203, RN-217, RN-302, RN-402 e RN-113 |

### Bloco 7 — Estados e transições

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P25 | P-22 | Estados possíveis de uma atividade no M1. | Lista oficial de valores de `situacao`. | Os estados são `prevista`, `em_andamento`, `encerrada` e `cancelada`. | A Rodada 1 levantou exatamente esses estados como hipótese. A Rodada 2 confirmou a lista oficial. | CONFIRMADO | RN-114 |
| R2-P26 | P-23 | Transições por tempo entre `prevista`, `em_andamento` e `encerrada`. | Como calcular `prevista`, `em_andamento` e `encerrada` a partir dos encontros e do relógio. | `prevista` vale antes do início do primeiro encontro; `em_andamento` vale a partir do início do primeiro encontro; `encerrada` vale a partir do fim do último encontro. | A Rodada 1 levantou essa lógica como hipótese geral, mas sem regras exatas. A Rodada 2 confirmou e precisou os marcos. | CONFIRMADO | RN-114 |
| R2-P27 | P-24 | Bordas de início e fim para estado da atividade. | Estado quando `agora == primeiro início`, `agora == fim de um encontro`, e `agora == último fim`. | Quando `agora == início do primeiro encontro`, a atividade já está `em_andamento`. Quando `agora == fim do último encontro`, a atividade já está `encerrada`, porque o documento considera que “começou” e “acabou” incluem o próprio instante de início e fim. | A Rodada 1 registrou as bordas como desconhecidas. A Rodada 2 definiu as bordas inclusivas de início e fim. | CORRIGIDO | RN-114 e regra geral de tempo |
| R2-P28 | P-22, P-23 e P-19 | Precedência de `cancelada` sobre estados calculados por tempo. | Se `cancelada` prevalece sobre estados calculados por tempo. | `cancelada` prevalece sobre todos os estados calculados pelo relógio. | A Rodada 1 não explicitou a precedência entre cancelamento e tempo. A Rodada 2 definiu essa precedência. | NOVO | RN-114 |

### Bloco 8 — Consulta e filtros

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P29 | P-25 | Ordenação de `GET /atividades`. | Critérios de ordenação da lista, incluindo desempates. | Ordenar pelo início do primeiro encontro; em caso de empate, pelo título. | A Rodada 1 levantou a hipótese de ordenação por data e horário de início, mas não sabia o desempate. A Rodada 2 confirmou o início do primeiro encontro e definiu desempate por título. | CONFIRMADO | RN-115 |
| R2-P30 | P-26 | Atividades canceladas em `GET /atividades`. | Se canceladas aparecem na listagem e se há algum filtro ou ordenação especial. | Atividades canceladas aparecem normalmente em `GET /atividades`. O documento não define uma ordenação especial só para canceladas. | A Rodada 1 levantou a hipótese de que canceladas poderiam aparecer na listagem. A Rodada 2 confirmou para listagem. | CONFIRMADO | RN-115 |
| R2-P31 | P-26 | Atividade cancelada em `GET /atividades/:id`. | Se o detalhe de uma atividade cancelada retorna `200 Atividade` ou erro. | NÃO ESPECIFICADO. O documento não define uma regra especial dizendo que `GET /atividades/:id` de uma atividade cancelada deve retornar erro. Apenas define explicitamente que canceladas aparecem na listagem. | A Rodada 1 levantou a hipótese de que canceladas poderiam aparecer no detalhe, mas sem confirmação. A Rodada 2 não encontrou especificação oficial para o detalhe. | NÃO ESPECIFICADO | Documento oficial |
| R2-P32 | P-27 | Filtro `?dia=AAAA-MM-DD` em `GET /atividades`. | Regra exata do filtro por dia. | O filtro `?dia=AAAA-MM-DD` inclui a atividade quando ela tiver pelo menos um encontro naquele dia de Brasília. Esse filtro pode ser combinado com `tipo`. | A Rodada 1 levantou essa regra como hipótese. A Rodada 2 confirmou oficialmente e especificou o uso do dia de Brasília. | CONFIRMADO | RN-116 |

### Bloco 9 — Filtros inválidos e precedência de erros

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P33 | P-28 | Valor inválido em `GET /atividades?tipo=`. | Comportamento de `GET /atividades?tipo=<valor inválido>`. | NÃO ESPECIFICADO. O documento oficial confirma apenas os filtros `dia` e `tipo`, mas não define o comportamento para um valor inválido em `?tipo=`. | A Rodada 1 registrou os valores válidos como conhecidos, mas o comportamento inválido como desconhecido. A Rodada 2 confirmou que segue não especificado. | NÃO ESPECIFICADO | Documento oficial |
| R2-P34 | P-27 e contrato | Valor inválido em `GET /atividades?dia=`. | Comportamento de `GET /atividades?dia=<formato inválido>` ou dia fora do evento. | NÃO ESPECIFICADO. O documento oficial define que o filtro `dia` considera o dia de Brasília e pode combinar com `tipo`, mas não informa o comportamento para formato inválido ou dia fora do período do evento. | A Rodada 1 não havia levantado formato inválido ou dia fora do evento. A Rodada 2 confirmou que esse comportamento não está especificado. | NÃO ESPECIFICADO | Documento oficial |
| R2-P35 | P-31 | Precedência de erros específicos na criação de atividade. | Ordem de prioridade entre `QUANTIDADE_DE_ENCONTROS`, `ENCONTRO_INVALIDO`, `VAGAS_ACIMA_DA_CAPACIDADE` e `CONFLITO_DE_SALA` em `POST /atividades`. | NÃO ESPECIFICADO. O documento oficial não estabelece uma ordem de precedência entre `QUANTIDADE_DE_ENCONTROS`, `ENCONTRO_INVALIDO`, `VAGAS_ACIMA_DA_CAPACIDADE` e `CONFLITO_DE_SALA` na criação. | A Rodada 1 registrou precedência de erros do M1 como desconhecida. A Rodada 2 confirmou que a ordem interna da criação não está especificada. | NÃO ESPECIFICADO | Documento oficial |
| R2-P36 | P-31 | Precedência de erros específicos na edição e no cancelamento de atividade. | Ordem de prioridade entre erros específicos do M1 em `PATCH /atividades/:id` e `POST /atividades/:id/cancelamento`, por exemplo `ATIVIDADE_CANCELADA`, `CAMPO_NAO_EDITAVEL`, `VAGAS_ACIMA_DA_CAPACIDADE`, `VAGAS_ABAIXO_DOS_INSCRITOS`, `ATIVIDADE_JA_INICIADA`. | NÃO ESPECIFICADO. O documento oficial não estabelece uma ordem interna de precedência entre os erros específicos de edição e cancelamento do M1. | A Rodada 1 registrou precedência de erros do M1 como desconhecida. A Rodada 2 confirmou que a ordem interna de edição e cancelamento não está especificada. | NÃO ESPECIFICADO | Documento oficial |

### Bloco 10 — Cenários de validação

| # | Origem Rodada 1 | Dúvida | Informação consultada no documento oficial | Resposta Rodada 2 | Comparação com hipótese da Rodada 1 | Classificação | Fonte |
|---|---|---|---|---|---|---|---|
| R2-P37 | P-32 | Casos que geram `ENCONTRO_INVALIDO`. | Quais casos geram `ENCONTRO_INVALIDO`. | `ENCONTRO_INVALIDO` ocorre quando um encontro dura menos de 1 hora ou mais de 4 horas, quando começa e termina em dias diferentes, quando fica fora do período de 19 a 23/10/2026 ou quando encontros da mesma atividade se sobrepõem. | A Rodada 1 listou encontros inválidos como cenário obrigatório, mas sem comportamento exato. A Rodada 2 definiu os casos. | CORRIGIDO | RN-104, RN-105 e RN-106 |
| R2-P38 | P-05 e P-32 | Casos que geram `QUANTIDADE_DE_ENCONTROS`. | Quando retornar `QUANTIDADE_DE_ENCONTROS`. | `QUANTIDADE_DE_ENCONTROS` ocorre quando palestra não possui exatamente 1 encontro ou quando minicurso possui menos de 2 ou mais de 5 encontros. | A Rodada 1 registrou limites de encontros como pendentes. A Rodada 2 definiu os limites e o erro correspondente. | CORRIGIDO | RN-102 e RN-103 |
| R2-P39 | P-13 e P-32 | Erro para `vagas < 1` ou valor não inteiro. | Erro quando `vagas < 1` ou não inteiro. | NÃO ESPECIFICADO. O documento define que vagas devem ser de no mínimo 1 até a capacidade da sala, mas não informa qual código específico deve ser usado para `vagas < 1` ou valor não inteiro. | A Rodada 1 registrou mínimo de vagas como desconhecido. A Rodada 2 definiu o mínimo, mas confirmou que o código de erro para valores abaixo do mínimo ou não inteiros não está especificado. | NÃO ESPECIFICADO | RN-107 |
| R2-P40 | P-32 | Comportamentos exatos dos cenários obrigatórios restantes. | Comportamentos exatos ainda não cobertos para criação válida, palestra e minicurso, conflito, edição, cancelamento, mudança de estado, listagem, filtros e consulta por ID. | Comportamentos adicionais importantes confirmados: encontro atravessando meia-noite é inválido; na mesma sala, intervalo de 14 minutos ainda gera `CONFLITO_DE_SALA` e 15 minutos é aceito; atividade só pode ser cancelada antes de começar; cancelamento é definitivo; `em_andamento` começa exatamente no início do primeiro encontro; `encerrada` começa exatamente no fim do último; listagem ordena pelo início do primeiro encontro e depois pelo título; canceladas aparecem na listagem; filtro `dia` considera o dia de Brasília e pode ser combinado com `tipo`. | A Rodada 1 listou os cenários obrigatórios, mas ainda sem comportamento exato. A Rodada 2 consolidou os comportamentos verificáveis. | CONFIRMADO | RN-105, RN-108, RN-112 a RN-116 |

## Fechamento da Rodada 2

### Requisitos confirmados

1. A diferença entre `palestra` e `minicurso` no M1 está na quantidade de encontros; duração, vagas e sala seguem regras comuns aos dois tipos.
2. `cargaHorariaMinutos` é calculado pela soma das durações dos encontros, em minutos, e valor enviado pela organização deve ser ignorado.
3. Vagas devem respeitar a capacidade da sala; acima da capacidade gera `VAGAS_ACIMA_DA_CAPACIDADE`.
4. Uma atividade cancelada não pode ser reativada; o cancelamento é definitivo.
5. O cancelamento afeta inscrições ativas e bloqueia novas inscrições, emissão de certificado, obtenção de código de presença, edição e novo cancelamento.
6. Os estados oficiais são `prevista`, `em_andamento`, `encerrada` e `cancelada`.
7. `prevista` vale antes do início do primeiro encontro; `em_andamento` vale a partir do início do primeiro encontro; `encerrada` vale a partir do fim do último encontro.
8. `GET /atividades` ordena pelo início do primeiro encontro e, em empate, pelo título.
9. Atividades canceladas aparecem normalmente em `GET /atividades`.
10. O filtro `dia` inclui atividades com pelo menos um encontro no dia de Brasília e pode ser combinado com `tipo`.
11. Os cenários de validação devem cobrir os comportamentos exatos confirmados para encontros inválidos, conflito com intervalo, cancelamento, estados, listagem e filtros.

### Hipóteses corrigidas

1. Palestra tem exatamente 1 encontro; minicurso tem de 2 a 5 encontros.
2. Cada encontro deve durar no mínimo 1 hora e no máximo 4 horas.
3. O conflito de sala não é apenas sobreposição; também exige intervalo mínimo de 15 minutos entre encontros na mesma sala.
4. Encontros de atividades canceladas não contam para conflito de sala.
5. `fim == início` é conflito na mesma sala, pois não cumpre intervalo mínimo de 15 minutos.
6. Vagas têm mínimo 1 e máximo igual à capacidade da sala.
7. Reduzir vagas abaixo da quantidade de inscrições que ocupam vaga gera `VAGAS_ABAIXO_DOS_INSCRITOS`.
8. Aumentar vagas é permitido e pode convocar automaticamente pessoas da lista de espera conforme regra de convocação.
9. Apenas `titulo` e `vagas` podem ser alterados depois da criação.
10. `sala`, `tipo` e `encontros` são imutáveis; tentativa de alteração gera `CAMPO_NAO_EDITAVEL`.
11. Cancelamento só pode acontecer antes de a atividade começar; depois disso gera `ATIVIDADE_JA_INICIADA`.
12. Cancelar atividade já cancelada gera `ATIVIDADE_CANCELADA`.
13. Nas bordas de tempo, `agora == início do primeiro encontro` já é `em_andamento` e `agora == fim do último encontro` já é `encerrada`.
14. `ENCONTRO_INVALIDO` cobre duração fora de 1 a 4 horas, encontro cruzando dias, encontro fora do período do evento e sobreposição entre encontros da própria atividade.
15. `QUANTIDADE_DE_ENCONTROS` cobre palestra diferente de 1 encontro e minicurso fora de 2 a 5 encontros.

### Pontos não especificados

1. Faixa diária de horário permitida dentro dos dias do evento.
2. Subconjunto de salas permitidas para o M1 ou salas excluídas.
3. Restrição de sala por tipo de atividade.
4. Proibição geral de editar atividade apenas por ela já ter iniciado ou encerrado.
5. Comportamento de `GET /atividades/:id` para atividade cancelada.
6. Comportamento de `GET /atividades?tipo=<valor inválido>`.
7. Comportamento de `GET /atividades?dia=<formato inválido>` ou dia fora do evento.
8. Ordem interna de precedência entre erros específicos de criação do M1.
9. Ordem interna de precedência entre erros específicos de edição e cancelamento do M1.
10. Código de erro específico para `vagas < 1` ou valor de vagas não inteiro.

### Requisitos novos identificados na Rodada 2

1. Se `cargaHorariaMinutos` for enviado pela organização, ele é ignorado.
2. `fim == início` é conflito porque não cumpre o intervalo mínimo de 15 minutos; 14 minutos conflita e 15 minutos é permitido.
3. Inscrições `confirmadas` e `convocadas` contam como ocupando vaga; `em_espera`, `canceladas` e `expiradas` não contam.
4. Aumento de vagas pode acionar convocação automática da lista de espera, conforme regra de M2.
5. Atividade cancelada não pode ser editada.
6. `cancelada` prevalece sobre todos os estados calculados pelo relógio.
7. O filtro `dia` usa o dia de Brasília.
8. Encontro atravessando meia-noite é inválido.
