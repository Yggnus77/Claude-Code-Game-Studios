# Evidência — Etapa 8: dois mistérios e uma relíquia

Fonte: `design/kit/plano-implementacao.md` § Etapa 8; `misterios-e-reliquias.md` ("Regras de vantagens
raras", mistérios 01 e 02). Dados: `misterios.json` (pistas, respostas, cenas, recompensas, modificadores),
`base-modificadores-reliquias.json` (números-base), cenas x01a–x01d e x02a–x02d. Ligação proposta:
`assets/data/misterios-ligacao.json` (quem conduz cada mistério, a pergunta, rótulos das relíquias,
raio de "em combate" 160 px).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Como funciona

- **O troco (m01):** depois de Igris, o comerciante da praça conta a venda a mais (x01a). Pistas: recibo do
  mercado e carimbo de doação na praça, via do cais no Cruzamento. Com as três, a comparação (x01b); depois
  ele pergunta, com as respostas do kit por código, mais "Ver as mercadorias". Certo: x01c, 30 Bronze e Selo
  do Restaurador. Errado: x01d e a próxima dica (até três), sem tirar dinheiro.
- **O quarto toque (m02):** ao entrar na Galeria dos sinos depois de Igris, x02a. Três pistas na galeria,
  comparação x02b, pergunta na inscrição. Certo: x02c, 50 Bronze e Mola de Retorno.
- **Relíquia:** a primeira recompensa abre o espaço. No inventário (Tab) aparecem as relíquias com os
  efeitos (antes de equipar) e K troca: nenhuma → Selo → Mola → nenhuma. Recusado com inimigo a 160 px ou
  numa tentativa de chefe. Os números são sempre refeitos da base e aplicados ao Yggnus.

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **149 passed, 0 failed**, sem SCRIPT ERROR.

| Critério da etapa | Teste |
|---|---|
| Acerto sem as pistas não conclui a missão | `test_mysteries_and_relics::test_right_answer_without_clues_does_not_solve` |
| Erro não retira dinheiro | `test_wrong_answer_costs_nothing_and_gives_the_next_hint`, `test_mystery_flow::test_troco_from_first_talk_to_the_seal` |
| Recompensa é única | `test_troco_from_first_talk_to_the_seal`, `test_steps_follow_the_kit_order` |
| Mola de Retorno altera somente a recarga | `test_spring_changes_only_the_hook_cooldown`, `test_spring_shortens_only_the_hook_cooldown_in_play` |
| Selo altera os dois tempos e mantém a cura em 3 | `test_seal_changes_both_times_only`, `test_seal_keeps_healing_at_three_and_equips_outside_combat` |
| Equipar e desequipar muitas vezes, sempre da base | `test_relic_params_never_stack`, `test_seal_keeps_healing_at_three...` (20 trocas) |
| Uma relíquia; fora de combate; nunca em tentativa de chefe | `test_no_swap_after_a_kill_with_an_enemy_near_or_in_a_boss_attempt` |
| Insistir não entrega pistas | `test_pressing_again_never_gives_clues` |
| Fluxo do quarto toque pelo mundo | `test_quarto_toque_starts_on_entering_the_bells`, `test_quarto_toque_through_the_tower` |
| Só relíquia no espaço; salvamento não traz relíquia sem dono | `test_slot_takes_only_relics_and_loads_safely`, `test_equip_needs_the_slot_and_the_relic` |

## Execução observada (640×360)

- `1_pergunta_do_troco_por_opcao.png`: o comerciante pergunta; três respostas do kit e "Ver as mercadorias".
- `2_reliquia_e_misterios_no_inventario.png`: inventário com o Selo equipado, efeito "Preparo do frasco
  0,65 → 0,55 s; Recuperação após beber 0,2 → 0,3 s" e o andamento dos dois mistérios.

## Revisão (Game Studios)

`/code-review` com `godot-gdscript-specialist` e `qa-tester`: todos os achados verificados foram corrigidos
(checagem de combate com inimigo já liberado da memória, só relíquias no espaço, salvamento validado,
pergunta sem vazar memória e sem abrir sobre outra cena, contador de pistas visível na inscrição, loja
abre pela apresentação na primeira visita).
