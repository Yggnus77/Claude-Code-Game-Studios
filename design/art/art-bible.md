# A Lenda de Yggnus — Guia de arte (Art Bible)

Status: rascunho 1 (2026-11-07), escrito com a primeira leva de pixel art (pacote P1 do kit).
Fontes: `design/kit/arte-e-audio-pendentes.md`, as ilustrações e pranchas do kit (yggnus, igris,
yame-black, pranchas 03, 08, 09, 14 e 16). Toda a arte do jogo é desenhada pixel a pixel pelos
scripts em `tools/art/`, sem copiar nem decalcar nada: é arte original do projeto.

## 1. Identidade visual

- Pixel art de visão superior (top-down) em grade de 16 px, tela base 640×360 com escala inteira.
- "Relojoaria marinha": latão, madeira, papel e índigo. Máquinas que guardam memórias, numa costa
  à noite. Calor das lâmpadas contra o azul-roxo da pedra.
- A leitura do jogo vem antes do detalhe: a silhueta e a pose dizem o estado (preparar, atacar,
  aberto), e a cor confirma.

## 2. Clima por lugar

| Lugar | Clima | Luz | Elemento que carrega o clima |
|---|---|---|---|
| Oficina de Exódia | abrigo, ofício | quente, madeira clara | tábuas e bancadas |
| Praça de Versalhes | cidade ferida pela invasão | neutra, pedra clara | calçamento e água do porto |
| Estrada | passagem, campo aberto | dia, verde | grama, barrancos de terra |
| Torre Akurame | mistério mecânico | fria, roxo e azul-noite | pedra roxa, latão, sinos |

## 3. Linguagem de formas

- Yggnus: retângulos firmes, casaco longo, cachecol claro que marca a direção.
- Inimigos de papel e tinta (Rastejo, Mariposa, Yame): formas moles e pontudas, dobras.
- Inimigos de máquina (Soldado, Guarda, Igris): blocos e círculos de latão, peças visíveis.
- Coisas que se usam (argolas, válvulas, marcos, baús) têm contorno escuro e um ponto de brilho.

## 4. Cores

Paleta fixa em `tools/art/pixel.py` (`PAL`). Uso com significado:

| Significado | Cor | Reforço além da cor |
|---|---|---|
| Perigo, ataque vindo | vermelho-laranja (`danger`, aviso #e0503c) | anel no chão e linha de direção |
| Defesa precisa, cristal, marco ativo | ciano (`crystal`, `safe`) | brilho e partículas |
| Interagível, latão | dourado (`brass`, `gold`) | contorno escuro e ponto claro |
| Yggnus | índigo + creme | silhueta do casaco e do cachecol |

Daltonismo: vermelho e verde nunca são o único sinal (sempre há forma, anel ou pose). O contorno
`outline` (#1b1420) separa qualquer sprite do chão.

## 5. Personagens

Segunda versão (detalhada): os personagens são desenhados à mão, linha a linha, em texto (uma
letra por pixel, legenda de cores no topo de `tools/art/yggnus_frente.py`). Contorno escuro de 1 px,
luz do alto à esquerda, 3 tons por material (claro, base, sombra) e um brilho pontual em metal e
olhos.

- Yggnus: quadro 32×48, pivô [16,44] (pés), 3 vistas (frente, costas, lado; a esquerda é espelho).
  Rosto com olhos, sobrancelhas e boca; cabelo cacheado com brilho; casaco índigo com galão
  dourado; cachecol creme; nas costas, o farol bordado. Peças (cabeça, cachecol, tronco, braços,
  pernas) são deslocadas pelas poses: parado 2, andar 4, corte 1 (2), corte 2 (2), finalização (3),
  defesa 2, esquiva 2, dano 1, queda 2, ferramenta 1. Espada, broquel e ferramenta são desenhados
  por cima, com contorno próprio (`tools/art/yggnus_hd.py`).
- Inimigos: quadro 32×48, pivô nos pés, uma pose por estado de combate (parado, preparar, atacar,
  aberto). A preparação muda a silhueta, não só a cor. Volumes sombreados (`inimigos_hd.py`).
- Yame Black: pequena, papel preto em dobras, olhos de brasa que acendem antes de lançar. Não é
  derrotada.
- Igris: quadro 48×64, maior que todos; abafador e regulador aparecem no peito na fase certa.
  Sem animação de morte (kit).

## 6. Cenário

- Uma linha de ladrilhos 16×16 por tema (oficina, praça, estrada, torre), colunas em
  `cenario_detalhado.HD_COLS`: parede alta em 3 peças (alto, meio, base), 4 pisos (o quarto é raro:
  bueiro, runa), topo de parede, móveis (4 tampos, sendo um aceso, e a frente), vão e borda,
  4 decalques de chão e tapete/caminho em 9 peças.
- A parede de cima tem 3 ladrilhos de altura: a base fica na linha 0 do mapa e as outras duas
  sobem acima dele (a câmera mostra). Blocos de parede no meio da sala viram móveis do tema
  (bancada, canteiro, pedra, bloco de pedra com braseiro).
- Decoração 16×32 pendurada na parede alta (`decor.png`, 6 por tema), alternando uma que dá luz e
  uma que não dá. Tapetes e caminhos vêm do mapa (`"art": {"rugs": [[x, y, w, h]]}`).
- Sombra suave no chão logo abaixo e à direita de paredes e móveis.
- Variação de piso, decalques e decoração por posição (sem aleatoriedade em tempo de jogo).
- Objetos em quadros 16×32 com pivô [8,24]: portas em arco, baús, pistas, relojoeiro, placa de
  examinar, marco apagado e aceso, argola, bloco, fragmento, sino e sino aceso.

## 6.1 Luz e efeitos

- Cada tema escurece a sala com uma cor ambiente (CanvasModulate) e acende luzes nas lamparinas,
  janelas, lampiões, tochas e braseiros (`cenario.json` → `lighting`). As chamas respiram de leve.
- Yggnus leva uma luz suave para ser visto em qualquer canto; fragmentos e marcos brilham.
- Efeitos: faíscas com clarão no golpe (douradas quando bloqueado), poeira nos passos e na esquiva,
  respingo ao derrotar um inimigo, poeira ou vaga-lumes flutuando no ar e o golpe como um
  crescente branco.

## 7. Interface

A interface atual continua (barras e textos). Ícones de itens e relíquias ficam para a próxima
leva (lista em `design/kit/arte-e-audio-pendentes.md` § Ícones).

## 8. Padrões técnicos

- PNG com transparência, importado com filtro Nearest (projeto já usa
  `default_texture_filter=0` e `snap_2d_transforms_to_pixel`).
- Cada folha tem um JSON ao lado (tamanho do quadro, pivô, nomes) lido pelo jogo.
- Gerar tudo de novo: `python3 tools/art/gerar_tudo.py` (precisa de Pillow).
- Os desenhos antigos de formas continuam como reserva no código caso a folha falte.

## 9. Referências

Somente o material do próprio kit (ilustrações e pranchas listadas no topo). Nada de outros jogos.
