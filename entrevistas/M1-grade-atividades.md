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
