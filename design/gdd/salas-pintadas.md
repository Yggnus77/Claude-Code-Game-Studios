# Salas pintadas

Status: em implementação (2026-11-11). Decisão do jogador: "Imagem vira o
fundo da sala". O jogador mandou 14 referências feitas no ChatGPT
(`design/art/referencias/salas/`); cada sala passa a usar a sua imagem,
reduzida ao tamanho do jogo, como fundo. Paredes, portas e objetos do mapa
são refeitos à mão para bater com a imagem. Primeira sala: a Praça de
Versalhes (referência 2).

## 1. Visão geral

Uma sala pintada não é montada com ladrilhos: ela é uma imagem só, do tamanho
da sala (largura × 16 por altura × 16 px). O mapa continua dizendo onde há
parede, porta, baú, pista e marco; o desenho de cada coisa que já está na
imagem (casas, barracas, chafariz, canteiros, lampiões, o mercador) vem da
própria imagem. O jogo desenha por cima só o que muda durante o jogo: baús,
pistas, fragmentos, marcos, arbustos, saídas fechadas e os personagens.

## 2. Fantasia do jogador

"Saio da oficina e a praça é igual à imagem que eu imaginei: o chafariz de
latão, as barracas listradas, os lampiões acesos ao pôr do sol. E eu ando por
ela, falo com o mercador na barraca e corto os arbustos."

## 3. Regras detalhadas

1. O mapa liga o fundo com `"art": {"background": "<nome>"}`; a imagem fica
   em `assets/art/salas/<nome>.png`, gerada por `tools/art/gerar_salas.py`.
2. Sem a imagem (arquivo apagado), a sala volta a ser desenhada com
   ladrilhos; nada quebra.
3. Uma sala pintada não tem a parede alta acima da linha 0, nem decoração
   de parede, tapetes, sombras ou luzes de ladrilho: a luz já está pintada.
   Uma sala marcada escura (`"dark": true`) mantém a escuridão e as tochas.
4. Uma entidade com `"painted": true` (o mercador) já está na imagem: o jogo
   não desenha nada para ela, só o anel de destaque quando dá para falar
   com ela. Ela pode ficar numa célula de parede (o balcão), desde que o
   jogador alcance a interação de uma célula de chão vizinha.
5. Porta aberta: nada é desenhado (a imagem mostra a passagem). Porta
   fechada: uma barreira de madeira listrada atravessa a passagem.
6. Uma saída larga usa `"span": n`: a área da porta cobre `n` células
   lado a lado (a estrada da praça tem 4).
7. Arbustos e potes de uma sala pintada usam o desenho no estilo das
   referências (`obj_bush.png`, `obj_bush_cut.png`), não o da folha de
   ladrilhos.
8. Um salvamento feito antes de a sala ser redesenhada pode estar numa
   célula que agora é parede: ele continua válido e o jogo põe Yggnus na
   entrada padrão da sala.

### 3.1 Praça de Versalhes

- Portas: a oficina de Exódia é a porta de madeira no alto, à esquerda
  (célula 11, 6); a estrada é a saída no alto, no meio (células 18–21,
  linha 1), fechada por barreira até a cena p07.
- Mercador na barraca da esquerda (pintado, célula 6, 10); marco em 7, 12;
  baú da reserva de viagem em 5, 14; pistas em 33, 10 (barraca de frutas) e
  25, 15 (degraus do chafariz); fragmento 1 em 33, 21, ao lado do pote.
- Seis arbustos cortáveis no chão (3, 13–14; 14, 17–18; 25, 17–18).

### 3.2 Oficina de Exódia

- 40 × 23 células (640 × 368 px). A referência 1 tinha Yggnus pintado no
  meio; a cópia `01-oficina-de-exodia-sem-yggnus.png` tem o chão refeito.
- Porta para a praça: a porta de madeira embaixo, no meio (células 18–21,
  linha 17, `span` 4, lado sul). A porta da praça para a oficina fica no lado
  norte, então a troca entre as duas desliza a tela.
- Relógio da bancada: o relógio aberto em cima da mesa grande (pintado; o
  jogador examina de frente para a gaveta, célula 22, 15).
- Yame Black aparece entre a bancada de ferramentas e a mesa (12, 8); as
  três amarras ficam no chão perto da porta (12, 15; 17, 16; 28, 15).
- O mentor não está na imagem: a entidade fica marcada como pintada e não
  desenha nada (ela não tem conversa).

### 3.3 Estrada inicial

- A referência 3 inteira vira a estrada (40 × 24 células): o portão da
  vila à esquerda, a placa no cruzamento, o moinho ao fundo e o poço com
  roldana à direita. O portão e o caminho do moinho são cenário.
- Porta para a praça: o caminho de terra embaixo, no meio (células 21–24,
  linha 22, `span` 4, lado sul). A saída da praça para a estrada fica ao
  norte, então a troca entre as duas desliza a tela de novo.
- Porta para o cruzamento: o caminho que sai pela direita (célula 38,
  linhas 10–11, `span` 2, lado leste).
- Baú da peça da bomba ao lado do poço (30, 21); reserva de viagem nos
  degraus do portão (11, 13); fragmento 2 escondido na grama atrás do poço
  (37, 15), atrás de dois arbustos (37–38, 12) que é preciso cortar.

### 3.4 Bomba d'água e poço antigo

- Imagens novas do usuário, uma por sala (`r02-bomba-d-agua.png`,
  `r03-poco-antigo.png`). As duas salas passam a 40 × 23 células, o
  formato 16:9 das imagens (antes 32 × 24 e 24 × 18).
- Bomba: a porta da roda, no alto da escada, leva ao cruzamento (células
  18–21, linha 5, norte). A passagem entre os lampiões, embaixo, desce ao
  poço (células 17–20, linha 21, sul) e continua selada até as duas tochas
  ao lado dela (16, 20 e 21, 20) acenderem. A bomba é pintada e se examina
  de frente para os degraus (23, 14).
- Poço: sala escura; entra-se pela corda embaixo (células 19–20, linha 19,
  sul). As duas portas ficam do lado sul, então essa troca é por
  esmaecimento.

## 4. Fórmulas

- Tamanho da imagem: `L = largura · 16`, `A = altura · 16` px. Praça: 40 × 24
  células → 640 × 384 px (a referência 16:9 de 960 × 540 é reduzida a
  2/3 na largura e 0,711 na altura).
- Paleta: 96 cores por sala (`COLORS`), sem pontilhado.
- Área de uma porta com `span = n` ao norte ou ao sul: o retângulo das
  células `(x, y)` a `(x + n − 1, y)`, mais as células até o arco.

## 5. Casos-limite

- Imagem com tamanho diferente do mapa: o teste
  `test_every_painted_map_matches_its_picture` falha.
- Porta ou entidade (sem `painted`) numa parede: o mesmo teste falha.
- Salvamento numa célula que virou parede: carrega na entrada padrão
  (`test_a_save_standing_where_the_room_now_has_a_wall_still_loads`).
- Oficina, praça e estrada ficam em lados opostos umas das outras, então
  todas as trocas entre elas deslizam a tela.
- Um arbusto pode esconder uma parte da sala (o fragmento 2): o teste de
  ligação passa por arbustos e potes, porque Yggnus começa com a espada.

## 6. Dependências

`Room` (desenho, colisão, `door_zone`), `RoomData` (`art`), `SaveGame`
(`_entry_ok`), `Main.continue_from`; dados `assets/data/maps/*.json`;
arte `tools/art/gerar_salas.py` → `assets/art/salas/`. Depende das
referências do jogador em `design/art/referencias/salas/`.

## 7. Parâmetros ajustáveis

| Onde | Chave | Valor | Faixa segura |
|---|---|---|---|
| gerar_salas.py | SALAS | sala → referência | — |
| gerar_salas.py | COLORS | 96 | 48–256 (menos: mais "pixel art", mais faixas) |
| mapa | art.background | nome da imagem | — |
| mapa | door.span | 4 (estrada da praça) | 1 até a largura da passagem |
| mapa | entity.painted | true (mercador) | — |

## 8. Critérios de aceitação

1. A praça mostra a imagem 2 inteira como chão, sem ladrilhos.
2. Yggnus não atravessa casas, barracas, canteiros, bancos, lampiões nem o
   chafariz; anda livre pelo calçamento.
3. Falar com o mercador de frente para o balcão abre a conversa; não há um
   segundo mercador desenhado.
4. Sair da oficina põe Yggnus nos degraus da porta de madeira da praça.
5. Antes de p07 a estrada mostra a barreira e avisa; depois de p07 ela
   leva à estrada.
6. Um salvamento antigo na praça continua carregando.
