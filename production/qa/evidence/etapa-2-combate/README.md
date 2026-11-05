# Evidência — Etapa 2: combate mínimo

Fonte: `design/kit/plano-implementacao.md` § Etapa 2; regras em
`design/kit/mecanicas-e-dificuldade.md` §3–6 e §10; números de `assets/data/combate.json`,
`inimigos.json` e `economia-progressao.json` (vida inicial 6).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **35 passed, 0 failed** (2026-11-05).

| Critério da etapa | Teste |
|---|---|
| Um golpe não acerta o mesmo alvo duas vezes | `test_combat_room::test_swing_hits_enemy_once_and_two_swings_defeat_it`, `test_sword_combo::test_each_swing_has_new_attack_id` |
| Dois contatos simultâneos não tiram duas vidas | `test_health::test_invulnerability_blocks_second_contact_same_step`, `test_combat_room::test_rastejo_charges_and_hurts_player_once` |
| Esquiva não cruza parede | `test_combat_room::test_dodge_does_not_cross_wall` |
| Defesa distingue frente e costas | `test_dodge_guard::test_guard_cone_front_not_back`, `test_resolver_outcomes`, `test_combat_room::test_guard_blocks_charge_from_front` |
| Combo: sem golpe automático, buffer de 0,12 s, reinício após 0,38 s, cancelamentos | `test_sword_combo::*` |
| Esquiva: invulnerável só entre 0,03 e 0,15 s, ~50,6 px, recarga de 0,65 s | `test_dodge_guard::test_dodge_*` |
| Defesa precisa de 0,11 s e nova tentativa só após 0,25 s | `test_dodge_guard::test_perfect_window_and_retrigger` |
| Morte devolve ao início da sala com vida cheia | `test_combat_room::test_death_respawns_with_full_life` |

## Execução observada (Movie Maker, 640×360)

```
godot --path . --windowed --resolution 1280x720 --write-movie c.png --quit-after 200 \
  res://src/scenes/main.tscn -- --room=r00_estrada --autowalk=0.05,0 \
  --spawn=rastejo_tinta@9,12 --autoattack
```

- `1_rastejo_inflando.png` (quadro 49): o Rastejo infla, com anel e seta da direção da investida.
- `2_investida_acerta_yggnus.png` (quadro 105): a investida acerta e Yggnus pisca (invulnerável).
- `3_espada_acerta_rastejo.png` (quadro 133): a espada acerta e o Rastejo fica branco; a barra mostra 5/6.
- `4_rastejo_derrotado.png` (quadro 175): o Rastejo sumiu depois do segundo golpe.

## Valores novos (propostos, para ajustar em teste)

O kit não definia a investida do Rastejo em números. Acrescentei em `inimigos.json`:
percepção 112 px, distância de ataque 64 px, direção travada nos últimos 0,2 s do aviso,
investida a 150 px/s por 0,35 s (~52 px), atordoamento de 0,2 s e recuo de 10 px ao ser atingido.

## Não verificado ainda

- Sensação: pausa de impacto (0,035 s), tremor de câmera e sons ficaram para depois.
- Mariposa, Soldado e Guarda (o plano os adiciona depois do primeiro inimigo).
- Defesa precisa só muda a cor do escudo: ainda não há pulsos para redirecionar.
- Diretor de encontro (limite de ataques simultâneos): só faz diferença com vários inimigos.
