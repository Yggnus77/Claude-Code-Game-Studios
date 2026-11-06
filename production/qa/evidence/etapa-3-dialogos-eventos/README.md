# Evidência — Etapa 3: diálogos, inventário e eventos

Fonte: `design/kit/plano-implementacao.md` § Etapa 3; regras em
`design/kit/integracao-e-salvamento.md` §3–6. Dados: `dialogos.pt-BR.json` (147 cenas),
`itens.json`, `recompensas-mundo.json`, salas em `assets/data/maps/`.
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **61 passed, 0 failed** (2026-11-06).

| Critério da etapa | Teste |
|---|---|
| Concluir e pular uma cena concedem exatamente o mesmo | `test_dialogue::test_complete_and_skip_give_the_same_state` (p04, p05, r04, m02, e04, o07) |
| Repetir o evento não duplica nada | `test_dialogue::test_effects_apply_once_even_if_replayed`, `test_game_state::test_unique_grant_once`, `test_interaction::test_chest_gives_bronze_once`, `test_key_chest_gives_key_once`, `test_clue_sets_flag_once` |
| Interagir rapidamente não abre duas caixas | `test_interaction::test_scene_pauses_world_and_one_box_only` |
| Fala de história não corta uma esquiva | `test_interaction::test_scene_waits_for_dodge_to_end` |
| Transação tudo ou nada | `test_game_state::test_transaction_is_all_or_nothing` |
| Bolsa 190/200 + coleta de 100 = 200 e reserva 90 | `test_game_state::test_bronze_overflow_goes_to_reserve` |
| Bolsas fora de ordem não reduzem a capacidade | `test_game_state::test_capacities_never_shrink` |
| Vida = 6 + fragmentos/4, até 14 | `test_game_state::test_life_from_fragments` |
| Pré-requisitos, itens exigidos, recarga de falas curtas | `test_dialogue::*` |
| Portas respeitam o bloqueio (`seen.p07`) | `test_interaction::test_door_needs_its_gate` |

## Execução observada (Movie Maker, 640×360)

- `1_cena_de_abertura.png`: novo jogo na Oficina; a cena p00 abre com Exódia, a tecla de cada ação vem da configuração.
- `2_bau_da_reserva_10_bronze.png`: Praça, `--at=7,18 --autointeract`: o baú entrega 10 Bronze
  (HUD 10/200). A porta para a Estrada aparece fechada (vermelha) até `seen.p07`.

## Não verificado ainda

- A cadeia de cenas da invasão (p02 a p07) depende dos acontecimentos da Etapa 4.
- Ícones de controle no lugar dos nomes de tecla.
- Salvamento em arquivo (Etapa 9): o progresso vive só na memória da sessão.
