# Evidência — Etapa 5: Estrada e recompensas

Fonte: `design/kit/plano-implementacao.md` § Etapa 5; `auditoria-e-decisoes.md` itens 2 (frascos) e 14
(primeira compra sem repetir inimigos); `mecanicas-e-dificuldade.md` §8 (Frasco Restaurador);
`integracao-e-salvamento.md` §5. Dados: `r00_estrada`, `r01_cruzamento`, `r02_bomba`, cenas r03–r05,
`recompensas-mundo.json`, `economia-progressao.json` (preços, recuperação, frascos), `combate.json`
(`healing`), `misterios.json` (m01 exige `seen.t11`), `inimigos.json` (`repeatable_drop`).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **90 passed, 0 failed** (2026-11-06).

| Critério da etapa | Teste |
|---|---|
| A bomba entrega apenas o segundo frasco | `test_road::test_pump_side_quest_gives_second_flask_once`, `test_shop_and_flasks::test_pump_gives_only_the_second_flask` |
| Coleta de 100 com bolsa 190/200 → 200 e reserva 90 | `test_shop_and_flasks::test_drops_overflow_to_reserve`, `test_game_state::test_bronze_overflow_goes_to_reserve` |
| Reabrir o objeto não altera o saldo | `test_road::test_travel_reserves_buy_a_refill_and_the_flask_heals` |
| Não é preciso repetir inimigos para avançar | `test_road::test_road_needs_no_enemy_defeated`; as duas reservas de 10 compram a recarga (mesmo teste acima) |
| Peça do bicho de sucata só na primeira derrota | `test_road::test_pump_side_quest_gives_second_flask_once` |
| Compra recusada não cobra | `test_shop_and_flasks::test_refused_purchase_costs_nothing` |
| Frasco: +3 no quadro do efeito, nada com vida cheia, interrompido não gasta | `test_healing::*`, `test_road::test_hit_while_drinking_spends_nothing` |
| Pistas do troco bloqueadas até o registro de Igris | `test_road::test_m01_clues_wait_for_igris_record` |
| Inimigo comum deixa Bronze | `test_road::test_common_enemy_drops_bronze` |
| Chave da base | `test_interaction::test_key_chest_gives_key_once`, `test_door_needs_its_gate` (etapa 3) |

## Execução observada (Movie Maker, 640×360)

- `1_estrada_bronze_do_rastejo.png`: Estrada, `--autoattack`; o Rastejo foi derrotado e a moeda recolhida
  (Bronze 1/200). O HUD mostra os frascos (0 cheios de 1).
- `2_bomba_cena_r03.png`: Bomba d'água, a Mecânica do Cais pede as duas peças (r03).
- `3_comerciante_loja.png`: Praça, depois da primeira conversa o comerciante abre direto a loja.
- `4_pista_m01_bloqueada.png`: Cruzamento, a pista do cais ainda não é registrada antes de Igris.
