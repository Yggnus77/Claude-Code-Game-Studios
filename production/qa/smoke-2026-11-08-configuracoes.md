# Smoke check: menu de configurações e troca de controles (2026-11-08)

Pedido do usuário: "Faça um menu de configurações dentro do jogo e umas das
opções para configurar os controles".

## O que mudou

- `src/core/controls.gd` (novo): tecla e botão principal de cada ação, troca
  com a ação que já usava a tecla, teclas reservadas (Esc, Start e as teclas
  de teste 1-4), nomes das teclas em português e pelo teclado do jogador,
  salvar e carregar todas as teclas de cada ação.
- `src/ui/settings_screen.gd` (novo): páginas Configurações, Controles e
  "Nova tecla"; Esc, Start ou B voltam uma página; tudo é salvo na hora.
- Menu de pausa e tela de título ganharam "Configurações".
- `Settings`: `fullscreen` e `controls`; aplicados ao abrir o jogo.
- HUD e caixa de diálogo mostram as teclas escolhidas; a dica do HUD diminui
  a letra se as teclas tiverem nomes longos.
- `MenuPanel`: listas longas rolam (`max_rows`), sem hint quando não há opção.
- Botões do controle valem para qualquer controle (device -1).

## Verificação

- Testes: 211 passaram, 0 falharam (`tests/unit/ui/test_controls.gd`,
  `tests/integration/ui/test_settings_menu.gd`, contagem do menu de pausa).
- Revisão: especialista GDScript (3000 sequências aleatórias de troca sem ação
  sem tecla nem tecla em duas ações) e QA (entrada simulada no jogo real).
  Todos os 15 pontos achados foram corrigidos; os de UX também.
- Imagens: `production/qa/evidence/configuracoes/` (pausa, configurações,
  controles, nova tecla, troca, dica do HUD, título).

## Limites conhecidos

- Os gatilhos LT/RT são eixos e não podem ser usados; a tela avisa.
