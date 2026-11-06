# Evidência — Etapa 6: Torre e gancho

Fonte: `design/kit/plano-implementacao.md` § Etapa 6; `mecanicas-e-dificuldade.md` §7 (gancho, guardas);
`integracao-e-salvamento.md` §62 (o vão é real na grade). Dados: salas `t00`–`t06`, cenas t01–t07,
`combate.json` (`hook`), nova ligação `assets/data/torre-akurame.json` (gatilhos de sala, flag de sala
limpa, contrapeso, ordem dos sinos).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **106 passed, 0 failed** (2026-11-06).

| Critério da etapa | Teste |
|---|---|
| Existe caminho até o gancho sem possuí-lo (chave → guardas vencidos sem gancho → oficina) | `test_tower::test_way_to_the_hook_without_owning_it` |
| O gancho não atravessa paredes (checa o caminho, não só o ponto final) | `test_hook::test_wall_on_the_path_stops_the_tip`, `test_tower::test_hook_never_passes_a_wall` |
| O vão não vira piso caminhável; só a aresta de travessia cruza | `test_tower::test_gap_is_not_floor_and_hook_crosses_it`, `test_hook_from_elsewhere_does_not_pull`, `test_bell_puzzle::test_grapple_destination_needs_item_and_start_point` |
| Ida e volta pela porta usam o mesmo estado | `test_tower::test_counterweight_then_lock_opens_bells_for_good` |
| Reiniciar o enigma não fecha um baú já recolhido | `test_tower::test_restarting_a_room_keeps_its_chest_open` |
| Guardas não voltam depois de vencidos | `test_tower::test_way_to_the_hook_without_owning_it` |
| Gancho abre o escudo do guarda (1,2 s) | `test_tower::test_hook_opens_a_guard_shield` |
| Sinos na ordem da inscrição; dica só quando pedida | `test_tower::test_bells_in_drawn_order`, `test_bell_puzzle::*` |
| Alcance 112 px, preparação 0,10 s, recarga 0,35 s | `test_hook::*` |

## Execução observada (Movie Maker, 640×360)

- `1_gancho_atravessa_o_vao.png`: Travessia, `--items=gancho_retorno --at=13,12 --face=1,0 --autoitem`;
  o cabo prende no aro duplo do outro lado e puxa Yggnus sobre o vão (fala t04 de Ádally).
- `2_contrapeso_erguido.png`: Contrapesos; o gancho puxou o peso (aro simples, diferente do aro de travessia).
- `3_galeria_dos_sinos.png`: os três sinos com as marcas círculo, fenda e ondas nas placas.
- `4_gancho_abre_escudo_do_guarda.png`: Sala dos guardas; o gancho deixa o escudo aberto.
