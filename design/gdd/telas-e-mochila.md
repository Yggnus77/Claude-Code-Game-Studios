# Telas: abertura, menus, HUD e mochila

Status: em implementação (2026-11-11). Pedido do jogador: "imagem do início
do jogo, menu bem desenhado tanto no início do jogo e ao jogar, precisa
mostrar uma mochila do inventário com os itens dentro". O jogador mandou
três referências, guardadas em `design/art/referencias/`:

- `tela-inicial-usuario.png`: a imagem da abertura (usada no jogo, reduzida);
- `telas-usuario.png`: o modelo das quatro telas (abertura, menu
  principal, HUD de exploração e inventário);
- `jogo-esperado-usuario.png`: como o jogador espera ver o jogo (guia a
  próxima passada de arte dos cenários, fora deste documento).

## 1. Visão geral

- **Abertura**: a imagem do jogador, o nome "A LENDA DE YGGNUS", a frase
  "Toda memória deixa um caminho." e "Pressione qualquer botão" piscando.
- **Menu principal**: Continuar, Novo jogo, Carregar jogo, Configurações,
  Créditos e Sair do jogo, com a última jornada no rodapé.
- **HUD**: painel de Yggnus (nome, vida em segmentos, fragmentos), painel da
  área (região, sala, minimapa da masmorra, Bronze e chaves), botões de ação
  (Atacar, item, Cura, Relíquia) e a caixa do objetivo.
- **Mochila**: abas por tipo, a mochila aberta com cada item desenhado num
  bolso e o painel de detalhes do item escolhido.
- Painéis em azul-marinho escuro com borda fina e destaque turquesa, como
  nas referências. Pausa, configurações, loja e diálogo usam o mesmo painel.

## 2. Fantasia do jogador

"Ligo o jogo e já estou no mundo de Rouge, ao pôr do sol. O menu é limpo,
o HUD diz só o que eu tenho, e abrir a mochila mostra tudo o que carrego,
desenhado, cada coisa no seu bolso."

## 3. Regras detalhadas

### 3.1 Abertura e menu principal

1. A abertura espera qualquer tecla, botão do controle ou clique (depois de
   `MenuPanel.OPEN_GUARD` s) e mostra o menu principal.
2. "Continuar" só aparece se algum espaço pode ser aberto (salvo ou com
   cópia recuperada). "Carregar jogo" aparece se algum espaço não está
   vazio, mesmo danificado, para o jogador ver o que houve com ele.
3. Continuar abre o último espaço jogado (`settings.last_slot`) se ele pode
   ser aberto; senão o primeiro que pode. Um espaço com cópia recuperada
   passa pelo aviso do espaço antes.
4. Novo jogo começa no primeiro espaço vazio. Sem espaço vazio, o jogador
   escolhe um e confirma a troca ("Começar de novo no espaço N?").
5. Carregar jogo mostra os três espaços com as regras de
   `integracao-e-salvamento.md` §7 (danificado, cópia, versão nova).
6. A tecla de pausa (ou o botão de voltar do controle) volta um passo: da
   página de um espaço aberto por Continuar, ao menu principal; da
   confirmação, à página de onde veio. Do menu principal não volta à
   abertura.
7. O rodapé mostra "Última jornada · Espaço N · sala · tempo".

### 3.2 Menus

Painel azul-marinho com borda fina. A opção escolhida fica numa faixa com
borda turquesa e "▸". No menu principal as opções ficam sem caixa, sobre a
imagem.

### 3.3 Mochila

1. Tab (mapa) abre e fecha; Esc fecha. O jogo pausa enquanto está aberta.
2. Os itens com quantidade maior que zero ocupam os bolsos (6 × 4), em
   ordem de tipo (`inventario.json` "order"), depois na ordem de
   `itens.json`. Mais de 24 itens rolam por fileira (▲ ▼).
3. As abas (`inventario.json` "tabs") filtram por tipo; o botão de troca
   passa para a próxima. O Arco de Fio fica em Ferramentas. Magias só
   aparece quando Yggnus tem uma magia; Relíquias, com o espaço de relíquia.
   Enquanto a mochila está aberta, o HUD de jogo some.
4. As setas movem o cursor; nas pontas ele dá a volta.
5. O painel mostra desenho, nome, tipo, "equipado", quantidade (ou
   Cheio/Vazio para frascos), descrição e o efeito de uma relíquia.
6. Examinar usa o item: ferramenta, munição ou frasco vão para o botão de
   item; relíquia entra no espaço de relíquia (ou sai, se já estava), com
   as regras de antes (só com o espaço liberado, nunca em combate).
7. Abaixo: frascos, fragmentos, pistas, munição, a relíquia equipada e os
   mistérios (no máximo 8 linhas; o efeito de cada relíquia aparece quando
   ela é escolhida), e o mapa da masmorra quando houver. Rodapé: Bronze,
   reserva e fragmentos.

### 3.4 HUD

1. Painel de Yggnus: "YGGNUS", "vida / máxima" e um segmento por ponto de
   vida; embaixo os quatro losangos dos Fragmentos de Âncora.
2. Painel da área: região (`hud.json` "areas", pelo prefixo da sala), nome
   da sala, minimapa da masmorra (salas vistas; a atual marcada), Bronze e
   chaves.
3. Botões, só o que o jogador tem: Atacar (espada), o item equipado (nome,
   munição, tecla e a tecla de troca), Cura (frascos cheios / total; com o
   frasco no botão de item, a Cura leva a tecla e não há botão de item
   separado) e Relíquia (com o espaço liberado).
4. A caixa do objetivo some quando não há objetivo.
5. A linha de teclas aparece por `hint_seconds` quando muda (início, nova
   habilidade, nova tecla) e some.
6. A barra de Ressonância e o botão Magia entram quando Yggnus tiver poderes
   da Matrix.

## 4. Fórmulas

- Largura do segmento de vida: `s = floor(min(20, (150 − 16 − 2·(m − 1)) / m))`
  px, `m` = vida máxima (6 → 20 px; 14 → 7 px).
- Bolso `i` na tela: `mochila + origem + ((i − 6·f) mod 6, (i − 6·f) div 6) · 28`
  px, `f` = primeira fileira mostrada.
- Fileira mostrada: o cursor `c` fica entre `f` e `f + 3`
  (`f = min(f, c div 6)`, `f = max(f, c div 6 − 3)`).
- Exemplo: `m = 14` → `floor((134 − 26) / 14) = 7` px.

## 5. Casos-limite

- Sem nenhum salvamento: o menu não mostra Continuar nem Carregar jogo.
- Último espaço jogado danificado: Continuar abre o primeiro que pode.
- Aba vazia: "Nada aqui ainda" e a explicação.
- Item sem desenho: uma bolsinha genérica.
- Arte ausente (arquivos apagados): fundo liso, nome em texto, mochila como
  retângulo; nada quebra.
- Usar pão ou peça de missão: só mostra a descrição (sem mensagem).
- Trocar relíquia em combate: "Não dá para trocar a relíquia em combate."

## 6. Dependências

`TitleScreen`, `MenuPanel`, `Hud`, `InventoryScreen`, `UiArt`,
`DungeonMapView`, `PauseOverlay`, `SettingsScreen`, `ShopPanel`,
`DialogueBox`; dados `inventario.json`, `hud.json`, `itens.json`,
`ferramentas.json`; arte `tools/art/gerar_interface.py` →
`assets/art/ui/` (titulo, logo, mochila, itens, interface.json).

## 7. Parâmetros ajustáveis

| Onde | Chave | Valor |
|---|---|---|
| hud.json | areas | v Versalhes, r Campos de Versalhes, t Torre de Akurame |
| hud.json | hint_seconds | 10 |
| inventario.json | order, tabs, categories, descriptions | textos |
| gerar_interface.py | GRID_COLS, GRID_ROWS, CELL, SLOT | 6, 4, 28, 26 |

## 8. Critérios de aceitação

1. A abertura mostra a imagem, o nome e "Pressione qualquer botão"; uma
   tecla abre o menu principal.
2. Sem salvamento, o menu tem Novo jogo, Configurações, Créditos e Sair.
3. Com um salvamento, Continuar abre esse espaço.
4. Novo jogo usa o primeiro espaço vazio; com todos cheios, pede para
   escolher e confirmar.
5. O HUD mostra "5 / 6" e cinco segmentos cheios depois de um golpe.
6. A mochila mostra cada item num bolso com desenho; as abas filtram.
7. Examinar no gancho põe o gancho no botão de item.
8. Examinar numa relíquia a equipa; de novo, a tira.
