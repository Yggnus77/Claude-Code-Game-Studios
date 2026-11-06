# Evidência — Etapa 4: Trecho de Versalhes

Fonte: `design/kit/plano-implementacao.md` § Etapa 4; `roteiro-jogo-completo.md` § Prólogo;
`auditoria-e-decisoes.md` item 8 (espada e escudo entregues na cena modal antes do combate).
Dados: cenas p00–p08 em `dialogos.pt-BR.json`, salas `v00_oficina` e `v01_praca`, encontro
`yame_oficina` em `chefes.json` (números propostos, marcados como tal).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **72 passed, 0 failed** (2026-11-06).

| Critério da etapa | Teste |
|---|---|
| Começa sem arma equipada | `test_prologue_flow::test_new_game_starts_unarmed` |
| Sequência jogada com todas as cenas puladas, sem travar | `test_prologue_flow::test_whole_stretch_with_every_scene_skipped` |
| Espada e escudo chegam antes dos ataques; nada duplica | idem (p05 entrega; `yame_entra` não toca de novo; 1 espada) |
| Três amarras, fuga de Yame, primeiro marco, saída para a estrada | idem |
| Um golpe não corta a mesma amarra duas vezes | `test_prologue_flow::test_cut_binding_needs_two_different_swings` |
| Morrer na invasão não perde a Matrix nem amarras cortadas | `test_prologue_flow::test_death_in_invasion_keeps_matrix_and_cut_bindings` |
| Escudo de frente segura os papéis | `test_prologue_flow::test_shield_stops_paper_from_the_front` |
| Objetivo compreensível sem narração externa | `test_prologue::test_objective_always_says_what_to_do` |
| Ordem das cenas, porta presa só por dentro | `test_prologue::*` |

## Execução observada (Movie Maker, 640×360)

- `1_novo_jogo_sem_arma.png`: novo jogo na Oficina, cena p00; Yggnus sem espada nem escudo.
- `2_decima_terceira_badalada_praca.png`: `--room=v01_praca --flags=seen.p00,seen.p01`: ao entrar na Praça, p02
  (a moradora esquece o nome). Objetivo no canto superior direito.
- `3_invasao_amarra_cortada.png`: invasão com `--gear --at=8,12 --autoattack`; Yame Black no alto, fios das
  amarras até a porta; uma amarra cortada (1/3).
- `4_escudo_contra_papeis.png`: papel em voo, escudo erguido e a fala curta p06 da Exódia.
- `5_praca_estrada_aberta.png`: depois de p07, a porta para a Estrada fica dourada (aberta) e o objetivo
  aponta o Marco.
