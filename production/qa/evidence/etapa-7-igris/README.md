# Evidência — Etapa 7: Igris

Fonte: `design/kit/plano-implementacao.md` § Etapa 7; `mecanicas-e-dificuldade.md` (Igris, §9 tentativas);
`chefes.json` "igris" (ciclos, golpes, janelas, telegrafias); ligação proposta em
`assets/data/torre-akurame.json` "igris" (raio e dano das ondas, intervalo, sequências de sinos, ordem das
ondas do ciclo 2 por índice nas telegrafias do kit, cena final).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **123 passed, 0 failed**, sem SCRIPT ERROR (2026-11-06).

| Critério da etapa | Teste |
|---|---|
| Todos os estados de reinício funcionam | `test_igris::test_death_returns_flasks_and_skips_the_opening`, `test_death_at_the_regulator_restarts_from_the_first_cycle`, `test_leaving_the_chamber_ends_the_attempt`, `test_igris_fight::test_reset_restarts_the_attempt`, `test_missed_muffler_window_repeats_waves` |
| Zero energia não impede vitória | Não há sistema de energia no jogo; `IgrisFight` não lê custo (`chefes.json mandatory_energy_cost` = 0). Coberto por `test_free_igris_then_he_chooses_to_leave` (vence sem energia) |
| O diálogo inicial não se repete a cada tentativa | `test_igris::test_death_returns_flasks_and_skips_the_opening`, `test_death_at_the_regulator_restarts_from_the_first_cycle` |
| O chefe não pode ser morto por dano comum | `test_igris_fight::test_ordinary_hits_never_advance_the_fight`, `test_regulator_only_takes_hits_while_open_and_keeps_them`; `test_igris` (golpe comum só ressoa) |
| O resultado não depende de apertar botão durante a fala | `test_igris::test_outcome_scenes_offer_no_choice`, `test_free_igris_then_he_chooses_to_leave` |
| Dois ciclos; três ondas → abafador 2,0 s → sinos → regulador 2,4 s; 2 golpes por ciclo | `test_igris_fight::*` |
| Ciclo 2 mistura onda lenta e rápida, ambas ensinadas | `test_igris_fight::test_later_cycles_only_use_taught_telegraphs`, `test_tower_data_mixes_slow_and_fast_in_cycle_two` |
| Saída voluntária, registro entregue, atalho, retorno à oficina (t12, espada afinada) | `test_igris::test_free_igris_then_he_chooses_to_leave`, `test_return_to_the_workshop_upgrades_the_sword` |

## Execução observada (Movie Maker, 640×360)

Argumentos: `--room=t07_igris --flags=<torre resolvida>,seen.t08 --items=gancho_retorno --at=20,16`.

- `1_onda_anunciada.png`: a onda marcada sob Yggnus; o anel externo fecha sobre o círculo até o golpe.
- `2_abafador_brilha.png`: após a terceira onda o abafador pisca dourado; aviso "use o gancho".
- `3_sino_aceso_na_ordem.png` (`--autoitem`): o gancho soltou o abafador; o primeiro sino da ordem acende com halo.

## Observação conhecida

Com Yggnus na metade de baixo da câmara, os sinos (linha 6) ficam sob as linhas do HUD. O halo os
mantém legíveis; o enquadramento fica para a etapa de arte.
