# Evidência — revisão completa das etapas 1–7

Pedido do usuário (2026-11-06): ao final de cada etapa, revisar tudo e corrigir. Revisão feita com o
`/code-review` do Game Studios em três frentes paralelas (agente `godot-gdscript-specialist` em
combate/jogador/inimigos, em main.gd/mundo/mapas, e com `qa-tester` em estado/diálogos/UI).
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **133 passed, 0 failed**, sem SCRIPT ERROR.

| Achado corrigido | Teste |
|---|---|
| Passar por uma porta curava a vida toda | `test_review_fixes::test_a_door_does_not_heal`, `test_death_still_restores_life` |
| Tab abria o inventário e o jogo travava pausado | `test_review_fixes::test_inventory_closes_while_paused` |
| Uma cena podia despausar a loja, o inventário ou a transição | `test_review_fixes::test_scene_restores_an_existing_pause` |
| Falas curtas mostravam só a primeira linha, sem quem fala | `test_review_fixes::test_bark_shows_every_line_with_speaker` |
| Escolhas saíam pela borda de baixo da tela | `test_review_fixes::test_dialogue_box_grows_upward_with_choices` |
| Escudo continuava erguido ao beber ou lançar o gancho | `test_combat_room::test_drinking_lowers_the_shield` |
| Esquiva logo após beber quase não saía do lugar | `test_combat_room::test_dodge_after_drinking_travels_full_distance` |
| Ataque apertado durante o gancho saía muito depois | `test_combat_room::test_attack_pressed_while_hooking_expires` |

Também corrigidos (sem efeito visível hoje): inimigos param enquanto Yggnus está caído; tempo de
atordoamento zero não gera empurrão infinito; recibo de baú e trava do contrapeso presos à cena certa;
reaparecer em outra sala conta como entrar nela; quantidades negativas recusadas no estado; destaque
de escolha volta à primeira opção; sala redesenhada só quando muda; valores de empurrão, reinício de
combo e cancelamento do golpe final lidos de `combate.json`; abertura do guarda lida de `inimigos.json`.

## Execução observada (640×360)

- `1_escolhas_cabem_na_tela.png`: cena e03 com três opções; a caixa cresce para cima e a dica de teclas fica visível.
- `2_fala_curta_com_duas_linhas.png`: câmara de Igris, abafador solto; a fala t09 mostra Igris e Ádally, com a dica "Falta o outro vínculo!".

## Pontos de fixação da arena (decidido pelo usuário: "Faça agora!")

`catalogo-atlas.md`: arena de Igris com quatro pontos de fixação. O mapa do kit tinha dois aros sem
função; foram acrescentados `hook_c` (4,12) e `hook_d` (35,12). Na arena, o gancho num aro puxa Yggnus
até ele, e durante o puxão nenhum golpe acerta: é uma rota de fuga das ondas
(`torre-akurame.json` igris.free_anchors). Teste: `test_igris::test_arena_rings_pull_yggnus_out_of_a_wave`.

- `3_aro_da_arena_puxa_para_fora_da_onda.png`: a onda marcada sob Yggnus; o gancho prendeu no aro da
  esquerda e o puxou para fora do círculo (fala de Ádally sobre o aro seguro).

O executor de testes agora conta como falha um arquivo de teste que não carrega (antes rodava zero
testes em silêncio).

## Não alterado, com motivo

- Reserva de Bronze pagando a loja: o kit diz "compras na vila"; o comerciante fica na estrada. Mantido.
- Salvamento em disco: é a etapa 9.
