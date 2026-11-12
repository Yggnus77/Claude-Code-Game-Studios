# Smoke check: telas (abertura, menus, HUD, mochila) — 2026-11-11

Build: teste19 (telas). GDD: `design/gdd/telas-e-mochila.md`.

## Suíte automática

`godot --headless --path . -s res://tests/run_tests.gd` → **301 passed, 0 failed**.
Novos: `tests/integration/ui/test_screens.gd` (21 testes). Atualizados:
`test_save_flow.gd`, `test_settings_menu.gd` (o título abre na abertura;
Configurações saiu da lista de espaços para o menu principal).

## Revisão (godot-gdscript-specialist + qa-tester)

Corrigido:
1. Painel da mochila crescia para fora da tela com muitas relíquias → no máximo 8 linhas; o efeito da relíquia aparece só na escolhida.
2. Seta para baixo numa última fileira curta não andava → vai ao último bolso.
3. Marca da troca no botão errado sem espada → cada botão diz se leva a marca.
4. Frasco aparecia duas vezes (botão de item e Cura) → a Cura leva a tecla.
5. Troca de relíquia: um só caminho (`use_from_backpack`), regra de combate testada pelos dois.
6. "Não" na confirmação voltava à lista → volta à página do espaço.
7. HUD aparecia por trás da mochila → o HUD de jogo some com a mochila aberta.
8. Abas Magias e Relíquias apareciam antes da hora → só com magia / espaço de relíquia.
9. Botão B do controle (ui_cancel) não voltava → volta no título e fecha a mochila.
10. Só um salvamento danificado: nada no menu → "Carregar jogo" aparece com qualquer espaço usado.
11. Voltar da página de um espaço aberto por Continuar → volta ao menu principal.
12. Fórmula do GDD (m = 14 → 7 px) corrigida; largura do segmento virou função testada.
13. Testes novos para os casos-limite do §5 (espaço danificado, cópia recuperada, aba vazia, ícone genérico, rolagem com mais de 24 itens, Tab pausa, combate).
14. Testes de regressão vistos falhando com as correções desfeitas (4 falhas) e passando com elas.

Fica como está: as dicas de tecla mostram o teclado também com controle (comportamento antigo do jogo inteiro).

## Capturas

`production/qa/evidence/telas/01`–`13`: abertura, menu principal, carregar,
créditos, HUD na praça, mochila (todos, equipar, ferramentas), HUD na torre
com minimapa, mochila na torre com mapa, relíquias, HUD com relíquia, pausa.
