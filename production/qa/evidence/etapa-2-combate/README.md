# Evidência — Etapa 2: combate mínimo

Fonte: `design/kit/plano-implementacao.md` § Etapa 2; regras em
`design/kit/mecanicas-e-dificuldade.md` §3–6 e §10; números de `assets/data/combate.json`,
`inimigos.json` e `economia-progressao.json` (vida inicial 6).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **42 passed, 0 failed** (2026-11-05). O executor agora reprova um teste que gere erro de script ou de engine.

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
| Mariposa só leva golpe pousada; um mergulho tira 1 de vida | `test_enemies::test_mariposa_*` |
| Soldado não é interrompido ao erguer a espada; defesa de frente bloqueia o corte | `test_enemies::test_soldado_*` |
| Guarda pode ser vencido sem gancho (abertura de 0,7 s após a pancada, só pelas laterais e costas) | `test_enemies::test_guarda_shield_blocks_until_slam_opening`, `test_guarda_can_be_beaten_without_hook` |
| Pancada do Guarda quebra a defesa e tira 1 em vez de 2 | `test_enemies::test_guarda_slam_breaks_guard` |

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

Segunda gravação, sala `t00_base` com Mariposa, Soldado e Guarda (`--spawn=...`):

- `5_soldado_ergue_espada.png` (quadro 108): espada erguida e área do corte marcada.
- `6_soldado_corta.png` (quadro 135): o corte.
- `7_guarda_ergue_contrapeso.png` (quadro 234): contrapeso erguido, área da pancada no chão.
- `8_guarda_pancada.png` (quadro 243): a pancada acerta Yggnus.
- `9_mariposa_voando.png` (quadro 120): Mariposa no ar, com sombra no chão.

## Valores novos (propostos, para ajustar em teste)

O kit não definia a investida do Rastejo em números. Acrescentei em `inimigos.json`:
percepção 112 px, distância de ataque 64 px, direção travada nos últimos 0,2 s do aviso,
investida a 150 px/s por 0,35 s (~52 px), atordoamento de 0,2 s e recuo de 10 px ao ser atingido.

## Não verificado ainda

- Sensação: pausa de impacto (0,035 s), tremor de câmera e sons ficaram para depois.
- Defesa precisa só muda a cor do escudo: ainda não há pulsos para redirecionar.
- Diretor de encontro (limite de ataques simultâneos): só faz diferença com vários inimigos.

Mariposa, Soldado e Guarda também ganharam números propostos em `inimigos.json`: distâncias de
percepção e ataque, velocidade e duração do mergulho, alcance do corte, raio da pancada (22 px),
velocidade de giro do escudo do Guarda e abertura pelo gancho (1,2 s, para quando o gancho existir).
