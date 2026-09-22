# Rodada de correção M1 — Dart e Flutter

## Escopo

Correções aplicadas após `auditorias/M1-dart-flutter-final.md`, sem alterar contrato,
specs, entrevistas ou auditorias históricas. O agente `@auditor` reavaliou o estado
final em modo somente leitura.

## Evidências executadas

- Backend: 22 testes HTTP aprovados e `dart analyze` sem problemas.
- Frontend: 9 testes Flutter aprovados e `flutter analyze` sem problemas.
- Cobertura acrescentada: precedência de autenticação/perfil/existência, corpo inválido,
  limites de encontros, duração máxima, sobreposição interna e entre atividades,
  período do evento, conflito de 14/15 minutos, capacidade no PATCH, PATCH atômico,
  cancelamento definitivo, bordas do relógio, detalhe, filtros combinados e campos
  calculados vazios.
- Flutter: transporte centralizado com `X-Usuario`, consulta de salas, seletor de
  usuários/papéis, leitura exclusiva de participante e detalhe com sala/encontros.

## Limitações explícitas

- R28-R31 dependem dos estados de inscrição do M2. O M1 não cria endpoints públicos
  de inscrição; `ocupadas`, `vagasRestantes` e `emEspera` são comprovados
  deterministicamente no estado vazio.
- A política para `tipo` inválido e o código específico para `vagas < 1` continuam não
  especificados pela entrevista/spec; não foi inventada regra adicional.
- `flutter build web --release` permanece bloqueado pelo SDK ambiental, que não contém
  `dart2wasm_product.snapshot` nem `dart2js_aot.dart.snapshot`.

## Auditoria independente

O `@auditor` confirmou as correções funcionais de R16, R21, R54/R55 dentro do que está
especificado, o relógio real fora de `MODO_TESTE`, autenticação, salas, detalhe e papéis.
Também registrou como limitações de evidência as dependências M2 e regras cuja origem
permanece apenas contratual ou não especificada.
