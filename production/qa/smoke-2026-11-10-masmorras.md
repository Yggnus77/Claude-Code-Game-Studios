# Smoke check: masmorras de chaves na torre (2026-11-10)

Escolha do usuário: mapa, bússola e chaves na torre de Akurame que já existe.
Desenho: `design/gdd/masmorras.md`.

## Verificação

- Testes: 232 passaram, 0 falharam (`tests/unit/world/test_dungeons.gd`,
  porta de Igris em `tests/integration/world/test_exploration.gd`, objetivo
  em `tests/unit/story/test_prologue.gd`).
- Revisão GDScript + QA: 7 achados corrigidos:
  - save antigo dentro da arena não fica preso (sala do chefe já visitada);
  - inventário com mapa cabe na tela (letra menor quando precisa);
  - objetivo pede a Chave Grande depois dos sinos;
  - o mapa para de redesenhar com o inventário fechado;
  - flag de visita gravada uma vez só;
  - teste garante que a vitória e a arena batem com `torre-akurame.json`;
  - documento cita o atalho arena → base fora do mapa.
- Imagens: `production/qa/evidence/masmorras/`.
