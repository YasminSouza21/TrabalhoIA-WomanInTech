# Resolucao M3 — `LIMITE_DE_MANUAIS`

O parecer do revisor aponta que `contrato-api.md` documenta o erro
`LIMITE_DE_MANUAIS`, mas a implementacao nao o retorna. A decisao aprovada para
este escopo, entretanto, nao autoriza inventar uma cota global.

- P13 e P14 fecham a idempotencia por `(encontroId, participanteId)`: uma
  segunda presenca devolve a primeira, com `200`, sem substituir seus campos.
- P17, P18 e P19 fecham que o registro manual e limitado por participante e
  encontro, que a chave e compartilhada entre organizacoes e que a duplicidade
  e resolvida antes de qualquer limite.
- A spec M3, R13 e R17, repete essas decisões e afirma que `Presenca` nao
  carrega organizacao como parte da chave de idempotencia. O modelo so guarda a
  organizacao da operacao manual para serializacao/auditoria, não uma cota por
  organizacao.

Assim, no modelo aprovado, toda tentativa que poderia ser chamada de excesso
para a mesma pessoa/encontro já é duplicidade idempotente e retorna `200`. Para
uma pessoa diferente, a regra aprovada permite o registro manual, desde que a
inscricao esteja confirmada e a janela/justificativa sejam validas. Nao existe
uma quantidade, escopo ou entidade de contagem definida para produzir
`LIMITE_DE_MANUAIS` sem alterar P13/P17/P18/P19 e o modelo.

Portanto, o ramo `LIMITE_DE_MANUAIS` e inatingivel no escopo aprovado. Nao deve
ser inventado agora. Os testes HTTP de regressao comprovam a duplicidade global
idempotente e registros de participantes distintos, sem criar uma nova cota;
o codigo de erro permanece documentado no contrato para uma futura decisao de
produto que defina explicitamente essa regra.
