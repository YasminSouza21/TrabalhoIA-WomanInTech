# Semana Acadêmica — repositório inicial

Ponto de partida do projeto final da disciplina de desenvolvimento com agentes de IA (UniFil, 2026). O enunciado completo está no Classroom; aqui fica o que o grupo precisa para começar.

## Como começar

1. Um integrante clica em **Use this template → Create a new repository**, escolhe **PUBLIC** e dá o nome do repositório do grupo.
2. Em **Settings → Collaborators**, adiciona os colegas.
3. Cada integrante clona o repositório, abre o OpenCode na raiz e confere o que veio da aula: `opencode debug skill` precisa listar `grilling`, `to-spec`, `tdd` e `novo-subagente`, e `opencode debug agent auditor` precisa mostrar `write`, `edit` e `task` como `false`.
4. Preencham o `EQUIPE.md` e o `projeto.json`.
5. Escrevam o `AGENTS.md` da raiz (com a stack escolhida) e o de cada subprojeto.
6. Marco 1: a API responde `POST /_teste/reset` no modo de teste (seção 3 do `contrato-api.md`).

## O que já vem

| Caminho | O que é | O que fazer |
|---|---|---|
| `contrato-api.md` | Rotas, campos, códigos de retorno, `projeto.json`, dados iniciais e modo de teste | Não alterar |
| `projeto.json` | Como o juiz instala, inicia e testa a API | Preencher (modelo na seção 2 do contrato) |
| `EQUIPE.md` | O dono de cada módulo | Preencher |
| `.opencode/skills/` | As skills da aula: `grilling`, `to-spec`, `tdd`, `novo-subagente` | Ler. A `tdd` ainda fala do `biblioteca-api` e de `node --test`: adaptem para a stack de vocês |
| `.opencode/agent/auditor.md` | O subagente auditor: para cada regra da spec, confere a pergunta da entrevista que a originou e o teste que a comprova. Só lê | Ler antes de usar. Chamar com `@auditor audite o módulo M2 contra specs/M2-inscricoes.md` |
| `entrevistas/` | As duas rodadas da entrevista de cada módulo | Um arquivo por módulo, criado na rodada 1 |
| `specs/` | Uma spec por módulo | Criada com a skill `to-spec` depois das duas rodadas |
| `auditorias/` | Pareceres do `auditor` e do `revisor-de-contrato` | Salvar inteiros, sem editar |
| `evidencias/exportar-evidencias.js` | Exporta as sessões do OpenCode e gera a linha do tempo de cada uma | Cada integrante roda toda semana: `node evidencias/exportar-evidencias.js` |

## O que vocês criam

- `AGENTS.md` na raiz e em cada subprojeto.
- A API e a interface, com os testes.
- As skills do grupo em `.opencode/skills/` (`novo-endpoint`, `nova-tela`, `regra-de-tempo`) e o subagente `revisor-de-contrato` em `.opencode/agent/`, criado com a skill `novo-subagente`.

## O documento de requisitos fica fora daqui

O documento de requisitos é para vocês consultarem na rodada 2 da entrevista, e só nela. Guardem o arquivo fora desta pasta. Não façam commit dele, não o anexem à conversa e não peçam ao agente para lê-lo: as sessões exportadas e o histórico do git mostram as três coisas.

---

## Módulo M3 — Presença por QR (implementado)

O M3 integra os encontros do M1 e as inscrições confirmadas do M2. A organização
obtém um QR por encontro, participantes registram presença online/offline, e a
organização pode registrar manualmente e consultar presenças.

- Janela: 15 minutos antes do início até 15 minutos depois do fim, inclusiva.
- Troca do código: a cada 5 minutos; o código anterior é invalidado na troca.
- Offline: `lidoEm` é o instante da regra, com tolerância de 10 minutos e sem futuro.
- Idempotência: uma presença por participante/encontro; repetição retorna `200`.
- Manual: justificativa de 10 a 500 caracteres após `trim`, com limite compartilhado.
- Verificação: `dart test`, `dart analyze` e `dart run tool/smoke_m3.dart` em `api/`.
- Frontend: `PresencasPage` e métodos M3 do `ApiClient`, testados com `MockClient`.

Artefatos: `entrevistas/M3-presenca-qr.md`, `specs/M3-presenca-qr.md`,
`api/test/presenca_test.dart`, `api/tool/smoke_m3.dart` e
`evidencias/ENTREGA-M3.md`.

---

## Módulo M2 — Inscrições e lista de espera (implementado)

Backend em `api/` (Dart 3 + `dart:io`, sem banco ou serviço externo) e frontend em `frontend/` (Flutter web). Requer SDK Dart e Flutter instalados.

### Backend

Instalação e servidor:

```bash
cd api
dart pub get
MODO_TESTE=1 PORT=3000 dart run bin/server.dart
```

PowerShell (mesma pasta `api/`):

```powershell
cd api
dart pub get
$env:MODO_TESTE="1"; $env:PORT="3000"; dart run bin/server.dart
```

- `PORT` define a porta (padrão 3000).
- Verificação do backend: `dart test` e `dart analyze` (iguais em Linux e PowerShell).
- Smoke: `dart run tool/smoke_m2.dart` (executar em `api/`) — inicia o próprio servidor (`MODO_TESTE=1` na porta 3000) e aborta, sem tocar nenhum serviço, se a porta 3000 já estiver ocupada.

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

O nome real da variável no `ApiClient` é `API_BASE_URL` (padrão `http://localhost:3000`), lida em `frontend/lib/api_client.dart:70`. Verificação: `flutter analyze`, `flutter test` e `flutter build web --release` (mesmos comandos em Linux e PowerShell).

### Persistência — produção vs. modo de teste

- **Produção** (sem `MODO_TESTE`): o estado M1/M2 e a sequência de ordem de inserção são persistidos em arquivo JSON local, padronizado em `data/estado.json` relativo ao diretório `api/` (cwd); `ARQUIVO_ESTADO` sobrescreve o caminho (R40). Como o estado fica em memória e é reescrito no arquivo, rode **uma única instância por arquivo**.
- **Modo de teste** (`MODO_TESTE=1`): estado em memória isolada — não lê nem escreve o arquivo; `POST /_teste/reset` recarrega os dados iniciais e o relógio é controlado por `PUT/GET /_teste/relogio` (R41).

### Documentação e evidências do M2

- Entrevista: `entrevistas/M2-inscricoes.md`.
- Spec: `specs/M2-inscricoes.md`.
- Dono/equipe: `EQUIPE.md` — M2 é de Clara L Peretti (`claraperetti`).
- Evidências: `evidencias/sessoes/clara-l-peretti/`.
- Rastreabilidade: as decisões P-01 a P-29 da Rodada 2 são regras locais delegadas pela usuária em 22/09/2026 com base no `contrato-api.md` e na spec do M1. **Não foram validadas contra requisitos externos do professor** e não há fonte externa inventada.
- Auditoria: a auditoria final do M2 será registrada em `auditorias/M2-inscricoes-final.md` — **ainda pendente**, não concluída.

---

As skills da aula foram reescritas pelo professor a partir de [mattpocock/skills](https://github.com/mattpocock/skills).
