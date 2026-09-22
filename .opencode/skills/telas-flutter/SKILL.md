---
name: telas-flutter
description: Constrói telas Flutter de inscrições da Semana Acadêmica (M2) consumindo o ApiClient injetável, com estados de carregamento, vazio, erro e sucesso, permissões por papel, layout sem overflow em 360px, timers descartados, refresh após mutação e testes de widget com MockClient em TDD. Use quando pedirem para criar ou alterar telas de inscrição, "Minhas inscrições", detalhe de atividade com inscrever/cancelar, confirmação de convocação, ou testes de widget do frontend.
---

# Telas Flutter de inscrições (M2)

Você escreve **telas**, não regras de negócio. O frontend exibe o que a API calcula;
nunca replica domínio no widget. Tudo passa pelo `ApiClient` — nada de `http` direto,
nada de URL hardcoded fora do cliente.

## Antes de escrever

Leia `frontend/lib/api_client.dart`, `frontend/lib/main.dart` e os testes existentes em
`frontend/test/`. O M1 (grade) é histórico preservado: **não quebre as telas do M1** ao
adicionar as do M2.

## O que toda tela de inscrição precisa

- **ApiClient injetável**: receba o `ApiClient` construtor (ou por parâmetro do widget),
  nunca instancie dentro do widget. A tela depende da interface, não de um cliente global.
- **`X-Usuario`**: quem chama o `ApiClient` define `client.user` antes de consultar/mutar
  (testes cobrem o cabeçalho). Permissões são da API; a tela apenas adapta o que aparece:
  participante vê "Minhas inscrições" e inscreve/cancela/confirma; organização consulta
  todas e não muta inscrição.
- **Estados = 4**: `loading` (indicador), `vazio` (widget de vazio quando a lista é `[]`),
  `erro` (mensagem de erro com ação de tentar de novo, preservando o `code` do `ApiFailure`),
  `sucesso` (conteúdo). Um por vez, nunca dois ao mesmo tempo.
- **Contagem regressiva de convocação**: use um `Timer.periodic` para atualizar o prazo,
  **descartado no `dispose()`**. Sem `cancel()` no dispose o teste falha com "Timer is
  still pending".
- **Refresh após mutação**: após inscrever/cancelar/confirmar ter sucesso, recarregue a
  lista (ou o estado local) — o usuário vê o reflexo imediato da mutação.
- **Layout 360px sem overflow**: as telas rodam em web desktop e cabem em viewport de
  360px de largura. Use `ListView`, `Wrap`, `Expanded`, `Flexible` e `SingleChildScrollView`,
  evite `Row` fixo com filhos overflow. Teste de widget roda com `tester.view.physicalSize`
  360px de largura para provar que não estoura.

## TDD

Primeiro o teste de widget com `MockClient` (`package:http/testing`) — vermelho, depois o
código mínimo que faz passar. O teste prova comportamento pela interface:
- estados de carregamento, vazio, erro e sucesso;
- inscrever/cancelar/confirmar disparam as rotas certas via `ApiClient` (método, caminho,
  `X-Usuario`);
- status, posição na espera, prazo e contagem regressiva aparecem na tela;
- o 360 sem overflow.

O nome do teste é a regra em português: `testWidgets('mostra estado vazio depois do loading')`.
Testes de `ApiClient` e de widget com HTTP fake, nunca HTTP real.

## O que você não faz

- Não replica regra de domínio no widget (fila, convocação, conflito, limite de minicursos).
- Não altera `contrato-api.md`, specs, entrevistas ou auditorias.
- Não troca um teste para ele passar; se a spec mudou, diga qual regra mudou.