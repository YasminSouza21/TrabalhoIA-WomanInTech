---
name: tdd
description: Implementa uma spec em fatias verticais, teste primeiro — vermelho, verde, próxima fatia. Use quando existir uma spec para implementar, ou quando pedirem "TDD", "teste primeiro", "red-green".
---

# Teste primeiro, uma fatia por vez

O ciclo é: **um teste que falha → o código mínimo que faz ele passar → a próxima fatia.**
Nada de escrever a suíte inteira e depois o código inteiro.

Você precisa de uma spec com regras numeradas. Sem ela, pare: você vai acabar testando o
que você mesmo inventou. Sem contrato, verde não significa nada.

## Onde o teste mora

Teste verifica **comportamento pela interface pública**, nunca implementação.

- **API (backend Dart):** a interface é HTTP. Suba `ApiServer` (`api/lib/server.dart`)
  num `HttpServer` de loopback e fale por `HttpClient`, espelhando o helper `request(...)`
  de `api/test/server_test.dart`. Não importe serviço nem repositório no teste — se
  importar, o teste quebra quando você refatorar sem que o comportamento tenha mudado.
  Padrão: `dart test` (`package:test`), arquivos em `api/test/`.
- **Interface mínima (frontend Flutter):** a interface é o `ApiClient` e as telas. Use
  `flutter test` (`flutter_test`) e injete um transporte HTTP fake com `MockClient` de
  `package:http/testing` — nunca HTTP real, nunca espiar estado interno do widget. A API
  continua sendo a costura das regras de domínio; o frontend apenas exibe o que ela calcula.

O nome do teste é a regra em português: `test('recusa inscrição em atividade cancelada com ATIVIDADE_CANCELADA')`
para a API, `testWidgets('mostra estado vazio depois do loading')` para a interface.

## O ciclo, por fatia

Para cada fatia da spec, nesta ordem:

1. Escreva **um** teste que prova **um** critério de aceite. O nome do teste é a regra
   em português: `test('recusa o quarto minicurso confirmado do mesmo participante')`.
2. Rode. **Ele tem que falhar.** Teste que passa antes do código existir não está
   testando nada — descubra por quê antes de seguir.
3. Escreva o mínimo de código que faz ele passar. Nada de já implementar a regra
   seguinte "que eu vou precisar mesmo".
4. Rode a suíte inteira. Verde? Próxima fatia.

Só passe para a fatia seguinte com a suíte inteira verde.

## A regra que não se quebra

**Quando o teste falha, o suspeito é o código.**

Se você mudar um teste para ele passar, você trocou o contrato pela sua implementação e
o verde virou enfeite. Só se altera um teste quando a **spec** mudou — e aí você diz, em
voz alta, qual regra da spec mudou e por quê.

Vale para o valor esperado, para o status HTTP e para o cenário. Trocar
`expect(vagasRestantes, 8)` por `expect(vagasRestantes, 7)` porque o código deu 7 é a
forma mais comum de mentir sozinho.

## Três testes que não valem nada

- **Acoplado à implementação** — na API, chama repositorio/serviço direto em vez de pedir
  pela rota HTTP; na interface, confere estado interno do widget em vez de exercitar o
  `ApiClient` ou a tela. Quebra em refatoração, não em regressão.
- **Tautológico** — o esperado é calculado do mesmo jeito que o código calcula
  (`expect(vagasRestantes, vagas - ocupadas)`). Passa por construção, nunca discorda do
  código. O valor esperado vem da spec, escrito na mão: `expect(vagasRestantes, 8)`.
- **Frouxo** — confere só o status e ignora o corpo. `201` com `convocadaAte` errado passa;
  também é frouxo conferir no widget só que algo apareceu, sem o conteúdo (status, posição,
  prazo) que a tela promete.

## Fechamento

Terminada a última fatia, rode a suíte inteira uma vez — `dart test` na API e `flutter test`
no frontend — e relate o número real que apareceu na saída. Não estime, não arredonde, não
repita um número de outra rodada.