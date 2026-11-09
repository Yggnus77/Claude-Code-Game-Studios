# Smoke check: exploração (2026-11-09)

Escolha do usuário no cartão de decisão: "Tudo, nessa ordem"; esta é a
primeira parte (exploração). Desenho: `design/gdd/exploracao.md`.

## O que mudou

- Tela deslizante entre salas por portas laterais em lados opostos; demais
  portas continuam escurecendo (t00 ↔ t07, ambas "north", usam o escurecer).
- Arbustos (praça, estradas) e potes (torre, bomba): bloqueiam até a espada
  quebrar; prêmios de `assets/data/exploracao.json`; voltam a cada visita;
  nada cai com chefe na sala.
- Gotas de vida (`Pickup.KIND_LIFE`).
- HUD: indicador de 4 losangos para os Fragmentos de Âncora (4 = +1 vida).
- Arte nova: arbusto, toco e pote (`tools/art/objetos_hd.py`).

## Verificação

- Testes: 224 passaram, 0 falharam (`tests/unit/world/test_breakables.gd`,
  `tests/integration/world/test_exploration.gd`).
- Revisão GDScript: 6 achados corrigidos (câmera sem interpolação durante o
  deslize, sem salto no início e no fim, cópia da sala antiga com potes e
  tocos como ficaram, sem luzes extras, gota não atravessa a porta).
- QA (26 portas, 111 objetos): caminho nunca bloqueado; corrigidos o par
  t00/t07, o indicador durante o brilho e objetos encostados em móveis.
- Imagens: `production/qa/evidence/exploracao/`.
