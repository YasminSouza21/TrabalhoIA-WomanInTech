# Spec — M1 Grade de Atividades

## 1. Objetivo

O M1 permite que a organizacao organize e mantenha a grade de atividades da Semana Academica 2026 e permite que participantes consultem atividades, salas, horarios, vagas exibidas, carga horaria e situacao das atividades.

Regras:

- R01. O M1 cobre grade de atividades, salas, encontros, vagas exibidas, consulta e cancelamento de atividade. Origem: P-01 / P-02.
- R02. O sistema inicia sem atividades cadastradas; os dados iniciais relevantes ao M1 sao os usuarios e salas definidos no contrato da API. Origem: P-04.

## 2. Escopo

O M1 inclui as rotas HTTP do contrato para salas e atividades:

- `GET /salas`, para consulta das salas iniciais.
- `GET /atividades`, para listagem de atividades.
- `GET /atividades/:id`, para consulta de atividade por id.
- `POST /atividades`, para criacao de atividade pela organizacao.
- `PATCH /atividades/:id`, para edicao parcial de atividade pela organizacao.
- `POST /atividades/:id/cancelamento`, para cancelamento de atividade pela organizacao.

Regras:

- R03. `GET /salas`, `GET /atividades` e `GET /atividades/:id` podem ser usados por todos os usuarios identificados. Origem: contrato-api.md, rotas M1.
- R04. `POST /atividades`, `PATCH /atividades/:id` e `POST /atividades/:id/cancelamento` sao operacoes da organizacao. Origem: contrato-api.md, rotas M1.

## 3. Fora de escopo

- Inscricoes, lista de espera, presenca, certificados, painel da organizacao e bloqueios nao sao implementados pelo M1, exceto pelos pontos em que suas informacoes afetam regras do M1.
- O fluxo completo de convocacao automatica da lista de espera ao aumentar vagas pertence ao M2.
- A emissao ou bloqueio de certificados de atividade cancelada pertence ao M4.
- A obtencao de codigo de presenca de atividade cancelada pertence ao modulo de presenca.
- A atualizacao de inscricoes ativas ao cancelar atividade pertence ao M2, embora o M1 exponha a atividade como `cancelada` e impeça nova edicao/cancelamento dela.

Regras:

- R05. O M1 nao define o fluxo completo de inscricao, presenca, certificado ou painel; esses modulos devem consumir a atividade e sua situacao conforme contrato. Origem: P-02 / R2-P24.

## 4. Atores e permissoes

Regras:

- R06. Toda rota identificada do M1 exige `X-Usuario`; sem cabecalho ou com id inexistente, a API responde `401 USUARIO_DESCONHECIDO` antes das regras do recurso. Origem: contrato-api.md, convencoes.
- R07. Operacoes de organizacao do M1 recusam usuario participante com `403 SOMENTE_ORGANIZACAO` antes das regras do recurso. Origem: contrato-api.md, convencoes e rotas M1.
- R08. Recurso inexistente em `GET /atividades/:id`, `PATCH /atividades/:id` ou `POST /atividades/:id/cancelamento` gera `404 NAO_ENCONTRADO` antes das regras do recurso. Origem: contrato-api.md, convencoes.
- R09. Corpo que nao e JSON, campo obrigatorio ausente ou campo de tipo errado gera `422 DADOS_INVALIDOS` antes das regras do recurso. Origem: contrato-api.md, convencoes.

## 5. Modelo da atividade

Campos da entidade `Atividade`:

- `id`: gerado pela API, prefixo `atv_` seguido de 8 hexadecimais minusculos.
- `titulo`: informado pela organizacao.
- `tipo`: informado pela organizacao; valores validos no M1 sao `palestra` e `minicurso`.
- `salaId`: informado pela organizacao, referencia uma sala existente.
- `vagas`: informado pela organizacao e editavel conforme regras de vagas.
- `encontros`: informado pela organizacao na criacao, retornado em ordem de inicio; cada encontro recebe `id` gerado com prefixo `enc_` seguido de 8 hexadecimais minusculos.
- `cargaHorariaMinutos`: calculado pela API.
- `situacao`: calculado pela API, exceto pela persistencia do cancelamento.
- `ocupadas`: calculado a partir de inscricoes que ocupam vaga.
- `vagasRestantes`: calculado a partir de `vagas` e `ocupadas`.
- `emEspera`: calculado a partir da lista de espera.

Regras:

- R10. Os tipos de atividade do M1 sao somente `palestra` e `minicurso`. Origem: P-03 / R2-P01.
- R11. A diferenca de regra entre `palestra` e `minicurso` no M1 e apenas a quantidade de encontros; duracao, vagas e sala seguem regras comuns. Origem: R2-P01.
- R12. `Atividade.encontros` deve ser retornado em ordem de inicio. Origem: contrato-api.md, modelo de Atividade.

## 6. Regras de criacao

Regras:

- R13. `POST /atividades` com dados validos cria atividade e retorna `201 Atividade`. Origem: contrato-api.md, rotas M1.
- R14. `palestra` deve ter exatamente 1 encontro; caso contrario, a criacao retorna `422 QUANTIDADE_DE_ENCONTROS`. Origem: P-05 / R2-P02 / R2-P38.
- R15. `minicurso` deve ter de 2 a 5 encontros; caso contrario, a criacao retorna `422 QUANTIDADE_DE_ENCONTROS`. Origem: P-05 / R2-P02 / R2-P38.
- R16. Uma atividade deve ocorrer dentro do periodo do evento, de 19/10/2026 a 23/10/2026, considerando horario de Brasilia; encontro fora desse periodo gera `422 ENCONTRO_INVALIDO`. Origem: P-07 / R2-P05 / R2-P37.
- R17. A ordem interna de precedencia entre erros especificos de criacao do M1 nao esta especificada; a spec nao exige prioridade entre `QUANTIDADE_DE_ENCONTROS`, `ENCONTRO_INVALIDO`, `VAGAS_ACIMA_DA_CAPACIDADE` e `CONFLITO_DE_SALA`. Origem: P-31 / R2-P35.

## 7. Regras dos encontros

Regras:

- R18. Cada encontro deve durar no minimo 1 hora e no maximo 4 horas; duracao fora desse intervalo gera `422 ENCONTRO_INVALIDO`. Origem: P-06 / R2-P03 / R2-P37.
- R19. Cada encontro deve comecar e terminar no mesmo dia; encontro que atravessa meia-noite ou muda de dia gera `422 ENCONTRO_INVALIDO`. Origem: R2-P37 / R2-P40.
- R20. Encontros da mesma atividade nao podem se sobrepor; sobreposicao interna gera `422 ENCONTRO_INVALIDO`. Origem: R2-P37.

## 8. Regras de sala/conflito

Regras:

- R21. Existe conflito quando dois encontros de atividades nao canceladas usam a mesma sala em horarios sobrepostos; a criacao retorna `409 CONFLITO_DE_SALA`. Origem: P-10 / R2-P09.
- R22. Alem de nao haver sobreposicao, deve existir intervalo minimo de 15 minutos entre o fim de um encontro e o inicio do proximo encontro na mesma sala; se o intervalo for menor, a criacao retorna `409 CONFLITO_DE_SALA`. Origem: P-11 / R2-P09 / R2-P10.
- R23. Na mesma sala, intervalo de 14 minutos entre encontros ainda conflita e intervalo de 15 minutos e permitido. Origem: R2-P12 / R2-P40.
- R24. Na mesma sala, `fim == inicio` entre encontros de atividades diferentes e conflito, pois nao cumpre intervalo minimo de 15 minutos. Origem: R2-P12.
- R25. Encontros de atividades canceladas nao contam para conflito de sala. Origem: P-12 / R2-P11.

## 9. Regras de vagas

Regras:

- R26. `vagas` deve ser no minimo 1 e no maximo igual a capacidade da sala da atividade. Origem: P-13 / P-14 / R2-P08 / R2-P13.
- R27. `vagas` acima da capacidade da sala gera `422 VAGAS_ACIMA_DA_CAPACIDADE` na criacao ou edicao. Origem: R2-P08 / contrato-api.md, codigos de retorno.
- R28. Reduzir `vagas` para valor menor que a quantidade de inscricoes que ocupam vaga gera `409 VAGAS_ABAIXO_DOS_INSCRITOS`. Origem: P-15 / R2-P14.
- R29. Inscricoes `confirmadas` e `convocadas` contam como ocupando vaga para impedir reducao de vagas. Origem: R2-P16.
- R30. Inscricoes `em_espera`, `canceladas` e `expiradas` nao contam como ocupando vaga para impedir reducao de vagas. Origem: R2-P16.
- R31. Aumentar `vagas` e permitido quando respeita as demais regras do M1; eventual convocacao automatica da lista de espera e dependencia do M2. Origem: R2-P15.

## 10. Carga horaria

Regras:

- R32. `cargaHorariaMinutos` e calculada pela soma das duracoes de todos os encontros, em minutos. Origem: P-06 / R2-P04.
- R33. Se `cargaHorariaMinutos` for enviado na criacao ou edicao, o valor enviado e ignorado; a resposta deve retornar o valor calculado. Origem: R2-P04.

## 11. Regras de edicao

Regras:

- R34. `PATCH /atividades/:id` com alteracao valida retorna `200 Atividade`. Origem: contrato-api.md, rotas M1.
- R35. Apenas `titulo` e `vagas` podem ser alterados depois da criacao. Origem: P-16 / R2-P17.
- R36. `salaId`, `tipo` e `encontros` sao imutaveis depois da criacao; tentativa de alteracao retorna `422 CAMPO_NAO_EDITAVEL`. Origem: P-17 / R2-P18.
- R37. Atividade cancelada nao pode ser editada; tentativa de edicao retorna `422 ATIVIDADE_CANCELADA`. Origem: R2-P20.
- R38. A ordem interna de precedencia entre erros especificos de edicao do M1 nao esta especificada; a spec nao exige prioridade entre `ATIVIDADE_CANCELADA`, `CAMPO_NAO_EDITAVEL`, `VAGAS_ACIMA_DA_CAPACIDADE` e `VAGAS_ABAIXO_DOS_INSCRITOS`. Origem: P-31 / R2-P36.

## 12. Cancelamento

Regras:

- R39. `POST /atividades/:id/cancelamento` antes do inicio da atividade cancela a atividade e retorna `200 Atividade` com `situacao` igual a `cancelada`. Origem: P-18 / R2-P21 / contrato-api.md, rotas M1.
- R40. O cancelamento so pode acontecer antes de a atividade comecar; se a atividade ja comecou, retorna `422 ATIVIDADE_JA_INICIADA`. Origem: P-18 / R2-P21.
- R41. O cancelamento e definitivo; atividade cancelada nao pode ser reativada. Origem: P-19 / R2-P22.
- R42. Cancelar uma atividade ja cancelada retorna `422 ATIVIDADE_CANCELADA`. Origem: P-20 / R2-P23.
- R43. A ordem interna de precedencia entre erros especificos de cancelamento do M1 nao esta especificada; a spec nao exige prioridade entre `ATIVIDADE_CANCELADA` e `ATIVIDADE_JA_INICIADA`. Origem: P-31 / R2-P36.

## 13. Situacao calculada pelo relogio

Regras:

- R44. Os estados oficiais de `situacao` sao `prevista`, `em_andamento`, `encerrada` e `cancelada`. Origem: P-22 / R2-P25.
- R45. Uma atividade nao cancelada fica `prevista` antes do inicio do primeiro encontro. Origem: P-23 / R2-P26.
- R46. Uma atividade nao cancelada fica `em_andamento` a partir do inicio do primeiro encontro. Origem: P-23 / R2-P26.
- R47. Uma atividade nao cancelada fica `encerrada` a partir do fim do ultimo encontro. Origem: P-23 / R2-P26.
- R48. `cancelada` prevalece sobre todos os estados calculados pelo relogio. Origem: P-22 / P-23 / P-19 / R2-P28.

## 14. Consulta e listagem

Regras:

- R49. `GET /atividades` retorna `200 [Atividade]` ordenado pelo inicio do primeiro encontro. Origem: P-25 / R2-P29.
- R50. Em caso de empate no inicio do primeiro encontro, `GET /atividades` ordena pelo `titulo`. Origem: P-25 / R2-P29.
- R51. Atividades canceladas aparecem normalmente em `GET /atividades`; nao ha ordenacao especial para canceladas. Origem: P-26 / R2-P30.
- R52. `GET /atividades/:id` retorna `200 Atividade` para atividade existente, sem regra especial especificada para atividade cancelada. Origem: contrato-api.md, rotas M1 / R2-P31.

## 15. Filtros

Regras:

- R53. `GET /atividades?dia=AAAA-MM-DD` inclui a atividade quando ela tem pelo menos um encontro naquele dia de Brasilia. Origem: P-27 / R2-P32.
- R54. `GET /atividades?tipo=palestra|minicurso` filtra atividades pelo tipo informado. Origem: P-28 / contrato-api.md, rotas M1.
- R55. Quando `dia` e `tipo` forem enviados juntos em `GET /atividades`, os dois filtros devem ser aplicados ao mesmo tempo. Origem: P-29 / R2-P32.

## 16. Regras temporais e bordas

Regras:

- R56. Todas as regras temporais do M1 usam o relogio controlado quando `MODO_TESTE=1`. Origem: P-30 / contrato-api.md, modo de teste.
- R57. Quando `agora == inicio do primeiro encontro`, a atividade ja esta `em_andamento`. Origem: P-24 / R2-P27 / R2-P40.
- R58. Quando `agora == fim do ultimo encontro`, a atividade ja esta `encerrada`. Origem: P-24 / R2-P27 / R2-P40.
- R59. As bordas do periodo do evento sao inclusivas para os dias de 19/10/2026 a 23/10/2026, sem faixa diaria especifica definida. Origem: P-07 / R2-P05.

## 17. Dependencias com outros modulos

- M2 Inscricoes e lista de espera: `ocupadas`, `vagasRestantes`, `emEspera`, a restricao de reducao de vagas por inscricoes que ocupam vaga e a possivel convocacao automatica no aumento de vagas dependem dos estados e regras de inscricao do M2.
- M2 Inscricoes e lista de espera: o cancelamento de atividade deve impedir novas inscricoes e cancelar inscricoes ativas conforme regra do M2; o M1 registra a atividade como cancelada.
- M3 Presenca: atividade cancelada nao permite obter codigo de presenca, mas o fluxo pertence ao modulo de presenca.
- M4 Certificados: atividade cancelada nao permite emitir certificado, mas o fluxo pertence ao M4.

Regras:

- R60. O M1 deve expor `situacao`, `vagas`, `ocupadas`, `vagasRestantes`, `emEspera` e `cargaHorariaMinutos` de forma consistente para consumo por M2, M3 e M4, sem implementar dentro do M1 os fluxos completos desses modulos. Origem: R2-P15 / R2-P24 / contrato-api.md, modelos M1-M4.

## 18. Pontos nao especificados

Estes pontos foram explicitamente preservados como ausencia de regra adicional. Nao devem gerar comportamento inventado na implementacao do M1:

- N01. Faixa diaria especifica de horario permitida dentro dos dias do evento. Origem: R2-P05.
- N02. Subconjunto de salas permitidas ou salas excluidas do M1. Origem: R2-P06.
- N03. Restricao de sala por tipo de atividade. Origem: R2-P07.
- N04. Proibicao geral de editar uma atividade apenas por ela ja ter iniciado ou encerrado. Origem: R2-P19.
- N05. Comportamento especial do detalhe de uma atividade cancelada. Origem: R2-P31.
- N06. Comportamento de `GET /atividades?tipo=<valor invalido>`. Origem: R2-P33.
- N07. Comportamento de `GET /atividades?dia=<formato invalido>` ou dia fora do periodo do evento. Origem: R2-P34.
- N08. Precedencia interna dos erros de criacao. Origem: R2-P35.
- N09. Precedencia interna dos erros de edicao/cancelamento. Origem: R2-P36.
- N10. Codigo especifico para `vagas < 1` ou valor de vagas nao inteiro. Origem: R2-P39.

## 19. Criterios de aceitacao

1. (R01, R02, R03) Depois de `POST /_teste/reset`, `GET /atividades` com usuario valido retorna `200 []`.
2. (R02, R03) Depois de `POST /_teste/reset`, `GET /salas` com usuario valido retorna as salas iniciais do contrato: `auditorio`, `sala-101`, `sala-102` e `lab-3`.
3. (R04, R06, R07) `POST /atividades` sem usuario retorna `401 USUARIO_DESCONHECIDO`; com participante retorna `403 SOMENTE_ORGANIZACAO`.
4. (R10, R13, R14, R18, R26, R32, R33, R44, R45) `POST /atividades` de `palestra` valida com 1 encontro, vagas dentro da capacidade e `cargaHorariaMinutos` enviado incorreto retorna `201 Atividade` com carga calculada e situacao conforme relogio.
5. (R10, R13, R15, R18, R26, R32) `POST /atividades` de `minicurso` valido com 2 encontros retorna `201 Atividade` com carga igual a soma dos encontros.
6. (R14) `POST /atividades` de `palestra` com 0 ou 2 encontros retorna `422 QUANTIDADE_DE_ENCONTROS` quando essa for a regra do recurso aplicada.
7. (R15) `POST /atividades` de `minicurso` com 1 ou 6 encontros retorna `422 QUANTIDADE_DE_ENCONTROS` quando essa for a regra do recurso aplicada.
8. (R16, R18, R19, R20) `POST /atividades` com encontro fora do periodo, menor que 1h, maior que 4h, atravessando meia-noite ou sobreposto a outro encontro da mesma atividade retorna `422 ENCONTRO_INVALIDO` quando essa for a regra do recurso aplicada.
9. (R21, R22, R24) Criar atividade em sala ocupada por outra atividade nao cancelada com sobreposicao ou sem intervalo minimo retorna `409 CONFLITO_DE_SALA` quando essa for a regra do recurso aplicada.
10. (R23) Se uma atividade termina as 10:00 na mesma sala, outra iniciando as 10:14 retorna `409 CONFLITO_DE_SALA`; iniciando as 10:15 e aceita, mantendo as demais regras validas.
11. (R25, R39) Depois de cancelar uma atividade antes do inicio, seus encontros nao bloqueiam a criacao de nova atividade na mesma sala e horario.
12. (R26, R27) Criar ou editar atividade com `vagas` acima da capacidade da sala retorna `422 VAGAS_ACIMA_DA_CAPACIDADE` quando essa for a regra do recurso aplicada.
13. (R28, R29, R30) Reduzir vagas abaixo de inscricoes `confirmadas` e `convocadas` retorna `409 VAGAS_ABAIXO_DOS_INSCRITOS`; inscricoes `em_espera`, `canceladas` e `expiradas` nao aumentam esse limite.
14. (R31) Aumentar vagas em atividade nao cancelada e permitido quando respeita capacidade e demais regras do M1; a spec do M1 nao exige validar o fluxo completo de convocacao.
15. (R34, R35) `PATCH /atividades/:id` alterando apenas `titulo` ou `vagas` validos retorna `200 Atividade` com os campos alterados.
16. (R36) `PATCH /atividades/:id` tentando alterar `salaId`, `tipo` ou `encontros` retorna `422 CAMPO_NAO_EDITAVEL` quando essa for a regra do recurso aplicada.
17. (R37) `PATCH /atividades/:id` de atividade cancelada retorna `422 ATIVIDADE_CANCELADA` quando essa for a regra do recurso aplicada.
18. (R39, R40, R41, R42) Cancelar antes do inicio retorna `200` e `situacao=cancelada`; cancelar depois de iniciada retorna `422 ATIVIDADE_JA_INICIADA`; cancelar novamente retorna `422 ATIVIDADE_CANCELADA` quando essa for a regra do recurso aplicada.
19. (R44, R45, R46, R47, R48, R56, R57, R58) Alterando `/_teste/relogio`, a mesma atividade aparece como `prevista` antes do inicio, `em_andamento` exatamente no inicio do primeiro encontro, `encerrada` exatamente no fim do ultimo encontro, e permanece `cancelada` se tiver sido cancelada.
20. (R49, R50, R51) `GET /atividades` retorna atividades ordenadas pelo inicio do primeiro encontro, desempata por titulo e inclui canceladas.
21. (R52) `GET /atividades/:id` de atividade existente retorna `200 Atividade`; a spec nao exige comportamento especial para cancelada alem das regras gerais.
22. (R53, R54, R55) `GET /atividades?dia=AAAA-MM-DD`, `GET /atividades?tipo=palestra` e a combinacao `dia` + `tipo` filtram conforme dia de Brasilia e tipo.
23. (R17, R38, R43, N08, N09) Testes nao devem exigir ordem interna de precedencia entre erros especificos do recurso quando mais de uma regra do M1 e violada simultaneamente.

## 20. Cenarios de teste derivados da entrevista

1. Criacao valida de palestra com exatamente 1 encontro dentro do periodo, duracao entre 1h e 4h, vagas dentro da capacidade, carga calculada e `cargaHorariaMinutos` enviado ignorado. Regras: R13, R14, R16, R18, R26, R32, R33.
2. Criacao valida de minicurso com 2 encontros e carga horaria igual a soma das duracoes. Regras: R13, R15, R32.
3. Recusa de palestra com quantidade diferente de 1 encontro. Regras: R14.
4. Recusa de minicurso com menos de 2 ou mais de 5 encontros. Regras: R15.
5. Recusa de encontro menor que 1h, maior que 4h, fora do periodo, cruzando meia-noite ou sobreposto internamente. Regras: R16, R18, R19, R20.
6. Recusa de conflito de sala por sobreposicao com atividade nao cancelada. Regras: R21.
7. Recusa de conflito de sala por intervalo de 14 minutos e aceite com intervalo de 15 minutos. Regras: R22, R23.
8. Criacao em horario de atividade cancelada nao gera conflito de sala. Regras: R25, R39.
9. Recusa de vagas acima da capacidade da sala na criacao e na edicao. Regras: R26, R27.
10. Recusa de reducao de vagas abaixo de inscricoes que ocupam vaga, contando `confirmadas` e `convocadas`, sem contar `em_espera`, `canceladas` e `expiradas`. Regras: R28, R29, R30.
11. Edicao permite somente `titulo` e `vagas`; tentativa de alterar sala, tipo ou encontros e recusada. Regras: R35, R36.
12. Atividade cancelada nao pode ser editada nem cancelada novamente. Regras: R37, R42.
13. Cancelamento antes do inicio e aceito; cancelamento depois do inicio e recusado. Regras: R39, R40.
14. Situacao muda por relogio controlado: prevista antes do primeiro inicio, em andamento no instante inicial, encerrada no instante final, cancelada prevalece. Regras: R44, R45, R46, R47, R48, R56, R57, R58.
15. Listagem ordena pelo inicio do primeiro encontro, desempata por titulo e inclui canceladas. Regras: R49, R50, R51.
16. Filtro por dia usa dia de Brasilia; filtro por tipo usa `palestra` ou `minicurso`; filtros combinados aplicam ambos. Regras: R53, R54, R55.
17. Consulta por id retorna a atividade existente conforme contrato, sem inventar comportamento especial para cancelada. Regras: R52, N05.

## 21. Rastreabilidade entrevista -> regra

| Origem | Regras |
|---|---|
| P-01 | R01 |
| P-02 | R01, R05 |
| P-03 / R2-P01 | R10, R11 |
| P-04 | R02 |
| P-05 / R2-P02 / R2-P38 | R14, R15 |
| P-06 / R2-P03 / R2-P04 / R2-P37 | R18, R32, R33 |
| P-07 / R2-P05 / R2-P37 | R16, R59, N01 |
| P-08 / R2-P06 | N02 |
| P-09 / R2-P07 | N03 |
| P-10 / R2-P09 / R2-P12 | R21, R24 |
| P-11 / R2-P09 / R2-P10 / R2-P12 | R22, R23 |
| P-12 / R2-P11 | R25 |
| P-13 / P-14 / R2-P08 / R2-P13 / R2-P39 | R26, R27, N10 |
| P-15 / R2-P14 / R2-P15 / R2-P16 | R28, R29, R30, R31 |
| P-16 / R2-P17 / R2-P20 | R35, R37 |
| P-17 / R2-P18 | R36 |
| P-18 / R2-P21 | R39, R40 |
| P-19 / R2-P22 / R2-P28 | R41, R48 |
| P-20 / R2-P23 | R42 |
| P-21 / R2-P24 | R05, R60 |
| P-22 / R2-P25 / R2-P28 | R44, R48 |
| P-23 / R2-P26 / R2-P28 | R45, R46, R47, R48 |
| P-24 / R2-P27 / R2-P40 | R57, R58 |
| P-25 / R2-P29 | R49, R50 |
| P-26 / R2-P30 / R2-P31 | R51, R52, N05 |
| P-27 / R2-P32 / R2-P34 | R53, N07 |
| P-28 / R2-P33 | R54, N06 |
| P-29 / R2-P32 | R55 |
| P-30 | R56 |
| P-31 / R2-P35 / R2-P36 | R17, R38, R43, N08, N09 |
| P-32 / R2-P37 / R2-P38 / R2-P40 | R14, R15, R16, R18, R19, R22, R23, R40, R49, R50, R51, R53, R55, R57, R58 |
| contrato-api.md | R03, R04, R06, R07, R08, R09, R12, R13, R27, R34, R39, R52, R54, R56, R60 |

## Como isto sera verificado

As regras do M1 devem ser verificadas pela interface HTTP definida em `contrato-api.md`, usando o servidor da API e o modo de teste (`MODO_TESTE=1`) para resetar estado e controlar o relogio. Essa e a costura mais externa e cobre permissao, contrato de JSON, status HTTP, codigos de erro, persistencia em memoria e regras temporais observaveis pelo cliente.

## Fatias de entrega sugeridas para TDD

1. Dados iniciais, autenticacao/autorizacao e consulta vazia de salas/atividades.
2. Criacao valida de atividade, tipos, encontros, periodo, duracao, carga horaria e ordenacao de encontros.
3. Conflito de sala, intervalo minimo e canceladas fora do conflito.
4. Vagas, capacidade e campos calculados ligados a ocupacao.
5. Edicao de `titulo` e `vagas`, campos imutaveis e atividade cancelada nao editavel.
6. Cancelamento antes do inicio, definitivo e recusas temporais.
7. Situacao calculada por relogio controlado e bordas inclusivas.
8. Listagem, detalhe e filtros por dia/tipo.
