# Entrega M1 — Grade de atividades

## Escopo

Concluído o M1 sem alterar M2, M3, `contrato-api.md`, entrevistas/specs
históricas ou pareceres históricos. Foi atualizada a célula de usuário GitHub
do M1 em `EQUIPE.md` para `YasminSouza21`.

## Arquivos alterados nesta sessão

- `EQUIPE.md` — somente a célula GitHub da linha M1.
- `api/test/m1_regressao_test.dart` — testes regressivos novos, sem editar testes existentes.
- `frontend/lib/main.dart` — oculta editar/cancelar para atividade cancelada.
- `frontend/test/widget_test.dart` — teste Flutter da regra de papel/estado cancelado.
- `auditorias/M1-dart-flutter-pos-correcao-final.md` — auditoria nova.
- `evidencias/ENTREGA-M1.md` — este registro.
- Índice/sessão de evidências gerados por `node evidencias/exportar-evidencias.js`.

## Rastreabilidade das correções

| Pendência | Teste novo | Implementação |
|---|---|---|
| ID inexistente, autenticação e papel no cancelamento | `api/test/m1_regressao_test.dart` | Já existente e confirmado |
| Duração 1h/4h e limites do minicurso | `api/test/m1_regressao_test.dart` | Já existente e confirmado |
| Vagas inválidas sem inventar código | `api/test/m1_regressao_test.dart` | Já existente e confirmado |
| Cancelamento no instante do início | `api/test/m1_regressao_test.dart` | Já existente e confirmado |
| PATCH válido e status | `api/test/m1_regressao_test.dart` | Já existente e confirmado |
| Ações de organização em atividade cancelada | `frontend/test/widget_test.dart` | `frontend/lib/main.dart` |

## Testes e validações

- `dart test` em `api`: **108 aprovados**.
- `flutter test` em `frontend`: **51 aprovados**.
- `dart analyze` em `api`: **sem problemas**.
- `flutter analyze` em `frontend`: **sem problemas**.
- `dart run tool/smoke_m2.dart`: **16 cenários OK**.
- `dart run tool/smoke_m3.dart`: **OK**.
- `git diff --check`: **OK**.
- `node evidencias/exportar-evidencias.js`: executado ao concluir.

## Limitações e pendências justificadas

- O build `flutter build web --release` continua bloqueado pelo cache local do
  Flutter, que não contém `dart2wasm_product.snapshot` e
  `dart2js_aot.dart.snapshot`.
- Ocupação, redução de vagas por status de inscrição, convocação e efeitos do
  cancelamento sobre inscrições são M2+.
- Presença e certificados de atividade cancelada são M3/M4.
- N01–N10 e regras com origem somente contratual não podem receber comportamento
  inventado nem rastreabilidade de entrevista adicional nesta entrega.
- Não houve commit nem push.

## Auditoria

Relatório final: `auditorias/M1-dart-flutter-pos-correcao-final.md`.
Veredito: **PASSOU COM LIMITAÇÕES AMBIENTAIS E DE ESCOPO**.
