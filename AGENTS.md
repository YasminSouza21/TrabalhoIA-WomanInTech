# Agentes e Skills

Este projeto utiliza o OpenCode com agentes especializados para garantir a qualidade e fidelidade ao contrato.

## Stack

O backend é Dart executável com `dart:io`; a interface é Flutter web. O contrato `contrato-api.md`, as specs, entrevistas e auditorias históricas são preservados e não devem ser alterados.

## Agentes Disponíveis

- **@auditor**: Audita módulos contra suas specs e testes. Possui acesso apenas de leitura para garantir imparcialidade.

## Skills Disponíveis

- **grilling**: Utilizada para realizar a entrevista de levantamento de requisitos.
- **to-spec**: Transforma as decisões da entrevista em uma especificação técnica verificável.
- **tdd**: Implementa as funcionalidades seguindo o ciclo Red-Green-Refactor.
- **novo-subagente**: Cria novos subagentes conforme a necessidade do projeto.
