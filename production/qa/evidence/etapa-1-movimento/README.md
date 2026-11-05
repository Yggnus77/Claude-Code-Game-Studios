# Evidência — Etapa 1: projeto, movimento e câmera

Fonte: `design/kit/plano-implementacao.md` § Etapa 1; números de `assets/data/combate.json`.
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, renderer opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **14 passed, 0 failed** (2026-11-05).

| Critério da etapa | Teste |
|---|---|
| Diagonal não é mais rápida | `test_player_motor::test_diagonal_is_not_faster`, `test_room_movement::test_diagonal_distance_equals_straight` |
| Não atravessa paredes, desliza nelas | `test_room_movement::test_cannot_walk_through_outer_wall`, `test_slides_along_wall_on_diagonal` |
| Distância depende só do passo de física | `test_room_movement::test_distance_matches_speed` (60 passos = 1 s) |
| Velocidade, aceleração e frenagem vindas do JSON | `test_player_motor::*` |
| Todas as 13 salas carregam e a entrada fica no piso | `test_room_data::test_every_prototype_room_loads` |

## Execução observada (Movie Maker, 640×360)

```
godot --path . --windowed --resolution 1280x720 --write-movie walk.png --quit-after 240 \
  res://src/scenes/main.tscn -- --room=t00_base --autowalk=-1,-1
```

- `t00_base_inicio.png`: quadro 0, Yggnus na entrada padrão da Base da torre.
- `t00_base_canto_noroeste.png`: quadro 239, após 4 s andando na diagonal: parou no canto,
  sem atravessar a parede; a câmera parou no limite da sala.
- `v01_praca.png`: a Praça carregada com `--room=v01_praca`.

## Não verificado ainda

- Sensação do controle e latência medida (precisa de teste em máquina real, com pessoa jogando).
- Câmera sem tremor a 30/120 fps de renderização: a lógica roda só no passo de física com
  interpolação ligada, mas não foi medido em tela.
- Pausa ao perder foco ou desconectar controle: implementado, testado só por leitura do código.
- Arte: tudo é forma provisória.
