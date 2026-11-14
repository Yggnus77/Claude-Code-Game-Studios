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
7. Arbustos, potes e os objetos dos mecanismos (baú aberto e fechado,
   pista, recipiente de agulhas, placa, marco) de uma sala pintada usam o
   desenho no estilo das referências (`obj_<tipo>.png`), não o da folha de
   ladrilhos. Os mecanismos são recortados das próprias pinturas do
   usuário por `tools/art/objetos_pintados.py` (pedido de 2026-11-13: "os
   mecanismos precisam coexistir no mesmo ambiente como um só").
8. Todo chão que a pintura mostra é andável (pedido de 2026-11-13: "deixe
   cada sala totalmente trafegável"). Nenhum item fica atrás de cenário sem
   passagem.
9. Todo caminho pintado que sai da sala leva a algum lugar ou termina num
   aviso (decisão do usuário: "Ligar onde der, fechar o resto"). O aviso é
   uma entidade `"kind": "examine"` numa célula de parede, com `"text"` (o
   que Yggnus lê ao examinar) e, se a pintura mostra a passagem aberta,
   `"barrier"` (a mesma barreira listrada de uma porta fechada, no formato
   de porta: `tile`, `span`, `side`).
10. Lâmpadas pintadas que são tochas do jogo ficam apagadas no fundo
   (`APAGAR` em `gerar_salas.py`); a tocha tem `"painted": true` e
   `"flame_at"` (posição do vidro a partir do centro da célula) e o jogo só
   desenha a chama e a luz quando acesa.
11. O que o aviso diz, a pintura mostra: um portão que o jogo diz fechado é
   pintado fechado (`GRADES` em `gerar_salas.py` baixa uma grade de ferro
   no vão do portão da cidade na estrada e no cruzamento).
11b. Uma parede rachada pintada (`"cracked": true`) não ganha barreira: a
   rachadura já está na imagem. Depois da explosão o jogo abre um buraco
   escuro no lugar.
12. Um salvamento feito antes de a sala ser redesenhada pode estar numa
   célula que agora é parede: ele continua válido e o jogo põe Yggnus na
   entrada padrão da sala.
13. O cenário se mexe (pedido de 2026-11-14: "se o jogo diz que o moinho
   está girando, então por que permanece parado?"). `tools/art/
   animacoes_salas.py` recorta as pás dos moinhos da pintura, preenche o
   lugar delas no fundo e grava as peças em `assets/art/salas/anim/` e a
   lista em `assets/data/animacoes-salas.json`. `Ambient`
   (`src/world/ambient.gd`) desenha por cima do fundo e por baixo de tudo o
   que fica de pé: pás, engrenagens, rodas e polias giram (`spin`),
   estandartes balançam (`sway`), chamas pintadas respiram (`glow`) e a
   água cintila (`water`). Sala sem peças não ganha o nó (`Scenery`), e
   só a camada que tem o que mexer é redesenhada a cada quadro.
14. Toda pessoa no mapa é desenhada no estilo dos personagens principais
   (pedido de 2026-11-14). Um NPC que não está na pintura tem `"look":
   "<nome>"` e o jogo desenha `assets/art/personagens/npc_<nome>.png`
   (gerado por `tools/art/npcs_referencia.py` a partir das referências do
   usuário, com o contorno escuro de 1 px) em pé na célula, com sombra.
   Exódia sai da referência 21; a Mecânica do Cais é a mesma figura de
   trabalho com outras cores, espelhada.

### 3.1 Praça de Versalhes

- Portas: a oficina de Exódia é a porta de madeira no alto, à esquerda
  (célula 11, 6); a estrada é a saída no alto, no meio (células 18–21,
  linha 1), fechada por barreira até a cena p07.
- Mercador na barraca da esquerda (pintado, célula 6, 10); marco em 7, 12;
  baú da reserva de viagem em 5, 14; pistas em 33, 10 (barraca de frutas) e
  26, 16 (degraus do chafariz); fragmento 1 em 33, 21, ao lado do pote.
- Seis arbustos cortáveis no chão (3, 13–14; 14, 17–18; 25, 17–18).

### 3.2 Oficina de Exódia

- 40 × 23 células (640 × 368 px). A referência 1 tinha Yggnus pintado no
  meio; a cópia `01-oficina-de-exodia-sem-yggnus.png` tem o chão refeito.
- Porta para a praça: a porta de madeira embaixo, no meio (células 18–21,
  linha 18, `span` 4, lado sul; o vão da porta é chão). A porta da praça para a oficina fica no lado
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
  roldana à direita. O portão da vila (7, 11) e o portão do moinho
  (22–24, linha 6, com barreira) são avisos `examine`.
- Porta para a praça: o caminho de terra embaixo, no meio (células 21–24,
  linha 22, `span` 4, lado sul). A saída da praça para a estrada fica ao
  norte, então a troca entre as duas desliza a tela de novo.
- Porta para o cruzamento: o caminho que sai pela direita (célula 38,
  linhas 10–11, `span` 2, lado leste).
- Baú da peça da bomba ao lado do poço (30, 21); reserva de viagem nos
  degraus do portão (11, 13); fragmento 2 escondido na grama atrás do poço
  (37, 15), atrás de dois arbustos (37–38, 12) que é preciso cortar.

**Cruzamento** (imagem do usuário de 2026-11-13, `r01-cruzamento.png`,
40 × 24): a estrada do oeste chega pela borda esquerda (1, linhas 11–13), a
bomba d'água fica descendo a estrada do sul (19–22, linha 22) e a torre
pela borda direita (38, linhas 11–13). Avisos: a estrada do norte termina
numa cancela (19–21, linha 1, "ponte caída"); o portão da cidade tem o
chão até o arco e uma barreira (5–7, linha 7); o caminho do moinho sobe até
a porta trancada (29, 6); o arco das ruínas tem uma barreira de pedras
(36–37, linha 9). A casinha e o poço cercado são cenário. O fragmento 3 fica no
calçamento do portão (6, 9), e a pista m01 fica na beira da estrada do
sul (16, 15).

### 3.4 Bomba d'água e poço antigo

- Imagens novas do usuário, uma por sala (`r02-bomba-d-agua.png`,
  `r03-poco-antigo.png`). As duas salas passam a 40 × 23 células, o
  formato 16:9 das imagens (antes 32 × 24 e 24 × 18).
- Bomba: a porta da roda, no alto da escada, leva ao cruzamento (células
  18–21, linha 5, norte). A passagem entre os lampiões, embaixo, desce ao
  poço (células 17–20, linha 21, sul) e continua selada até os dois
  lampiões pintados ao lado dela (tochas em 15, 19 e 22, 19) acenderem. A
  bomba é pintada e se examina de frente para os degraus (23, 14).
- A escada da esquerda (2–3, linhas 7–14) e o mezanino (2–10, linha 6) são
  andáveis; o baú da Lamparina fica lá em cima (9, 6).
- Poço: sala escura; entra-se pela corda embaixo (células 19–20, linha 19,
  sul). As duas portas ficam do lado sul, então essa troca é por
  esmaecimento.
- A rachadura pintada na parede do fundo (20–21, linha 8, norte) é a
  parede rachada da adega: uma Carga a derruba (o baú das Cargas fica na
  mesma sala). Antes ficava no cruzamento; o sinal salvo continua o mesmo
  (`world.cracked.r01_adega`), então um jogo que já abriu a parede a encontra
  aberta.

### 3.5 Torre: a subida passa a ser de baixo para cima

As imagens da torre têm a entrada embaixo e a saída no alto, então cada
sala de passagem liga a porta sul à porta norte da seguinte, e a troca
desliza a tela. Salas com uma terceira porta (Base, Guardas, Antecâmara e
câmara de Igris) ganham uma segunda saída desenhada no estilo das imagens
(decisão do usuário, 2026-11-13): `tools/art/gerar_salas.py` (`PORTAS`)
copia a saída pintada da própria sala para outro trecho da parede da
frente, com a borda suavizada. Uma porta lateral desenhada em perspectiva
ficou fina demais e foi descartada.

Todas as salas da torre têm 40 × 23 células. Ordem da subida:

| Sala | Entrada | Saídas |
|---|---|---|
| Base (t00) | sul (18–21, linha 21), vinda do cruzamento | norte (18–21, linha 8), cadeado da chave da base; segunda saída sul (31–34) para o atalho de Igris, aberta depois de t11 |
| Guardas (t01) | sul (18–21, linha 21) | norte (18–21, linha 8) para a oficina, abre sem guardas; segunda saída sul (30–33) para a travessia, pede o gancho |
| Oficina do gancho (t02) | sul (18–21, linha 16) | — |
| Travessia (t03) | oeste (linha 20–21, coluna 4), vinda dos guardas | norte (18–21, linha 3) |
| Contrapesos (t04) | sul (18–21, linha 21) | norte (18–21, linha 5) |
| Galeria dos sinos (t05) | sul (18–21, linha 21) | norte (18–21, linha 6), abre com os sinos |
| Antecâmara (t06) | sul (18–21, linha 17) | norte (18–21, linha 6), Chave Grande; segunda saída sul (30–33) para o mirante, abre com a placa |
| Câmara de Igris (t07) | sul (18–21, linha 21) | segunda saída sul (8–11) para o atalho da base, aberta depois de t11 |

- Base: o baú grande pintado à esquerda é o baú da chave (6, 13, aberto de
  (6, 14)); o marco fica na placa de engrenagem do centro (19, 11).
- Guardas: os dois guardas ficam no salão, longe das colunas, em (17, 15)
  e (24, 13); o baú do mapa fica no canto direito (34, 16).
- Travessia: o abismo é vão (`~`): o gancho passa por cima. O aro que sai
  da passarela (20, 15) e o aro da plataforma de cima (20, 7) formam a
  travessia.
- Contrapesos: o peso é o contrapeso pintado da esquerda (6, 13), puxado
  com o gancho de (6, 14); a trava é a alavanca da direita (31, 16),
  examinada de (31, 17).
- Antecâmara: a placa de bronze fica na parede do fundo ao lado da porta
  grande (16, 5); a agulha a acerta vinda do chão, a espada não. O baú do
  arco fica à esquerda (8, 9) e as agulhas em (6, 15).
- Câmara de Igris: os quatro aros pintados na borda da arena são os pontos
  do gancho (20, 6), (5, 11), (35, 11) e (20, 16). Os dois sinos pintados
  ficam no alto da parede, fora do alcance da espada: cada um é tocado
  numa placa no chão logo abaixo (9, 7) e (31, 7), e o brilho que mostra a
  ordem aparece sobre o sino pintado (`glow_at`).
- Mapa da masmorra: uma segunda saída na parede da frente leva para o lado
  dela no mapa (`map_side`): a travessia fica a leste dos guardas e o
  mirante a leste da antecâmara. O atalho Igris–base não entra no mapa.
- O teste de ligação segue as travessias do gancho (`special_edges`).

## 4. Fórmulas

- Tamanho da imagem: `L = largura · 16`, `A = altura · 16` px. Praça: 40 × 24
  células → 640 × 384 px (a referência 16:9 de 960 × 540 é reduzida a
  2/3 na largura e 0,711 na altura).
- Paleta: 96 cores por sala (`COLORS`), sem pontilhado.
- Giro: ângulo `a = t · vel` (rad, `t` em segundos). A pintura foi
  achatada na altura pelo fator `k = (A_sala / A_ref) ÷ (L_sala / L_ref)`;
  a peça gira no espaço da pintura: escala `(1, 1/k)`, gira `a`, escala
  `(1, k)`. Pás dos moinhos: `vel = 0,9` (uma volta em ~7 s).
- Balanço: a faixa de 2 px na altura `y` de um estandarte de altura `h`
  desloca `dx = round(amp · u² · sin(t · vel − 2,2 u))`, `u = y / (h − 1)`;
  `amp = 1,6` px, `vel = 2,2`.
- Chama: `respira = 0,5 + 0,3 sin(6t + 1,9i) + 0,2 sin(13t + i)`; o halo
  de raio 14 px tem alfa `0,05 + 0,05 · respira`, o miolo de raio 7 px
  `0,08 + 0,10 · respira` e o ponto de 2 px `0,25 + 0,3 · respira` (soma
  de luz).
- Área de uma porta com `span = n` ao norte ou ao sul: o retângulo das
  células `(x, y)` a `(x + n − 1, y)`, mais as células até o arco.

## 5. Casos-limite

- Imagem com tamanho diferente do mapa: o teste
  `test_every_painted_map_matches_its_picture` falha.
- Porta ou entidade (sem `painted`) numa parede: o mesmo teste falha.
  Placas (`plate`) e avisos (`examine`) são a exceção: ficam na parede de
  propósito.
- Voltar pela porta logo depois de passar por ela funciona: depois de
  chegar, basta parar ou dar um passo para dentro e andar de volta. Segurar
  o mesmo sentido em que chegou (porta do mesmo lado nas duas salas) não
  faz voltar.
- Aviso examinado: o texto aparece por 3,5 s e quebra em duas linhas se
  for longo.
- Segunda saída na parede da frente que leva a uma porta de outro lado
  (guardas → travessia, antecâmara → mirante): a tela não desliza, faz o
  escurecimento; o mapa usa `map_side`.
- Salvamento numa célula que virou parede: carrega na entrada padrão
  (`test_a_save_standing_where_the_room_now_has_a_wall_still_loads`).
- Peça de animação sem imagem (arquivo apagado): `Ambient` a pula; o
  teste `test_the_mills_turn_and_every_moving_piece_has_its_picture` falha.
- `look` sem imagem: o NPC não é desenhado; o teste
  `test_every_person_on_a_map_is_drawn_in_the_character_style` falha.
- Oficina, praça e estrada ficam em lados opostos umas das outras, então
  todas as trocas entre elas deslizam a tela.
- Um arbusto pode esconder uma parte da sala (o fragmento 2): o teste de
  ligação passa por arbustos e potes, porque Yggnus começa com a espada.

## 6. Dependências

`Room` (desenho, colisão, `door_zone`), `RoomData` (`art`), `SaveGame`
(`_entry_ok`), `Main.continue_from`; dados `assets/data/maps/*.json`;
arte `tools/art/gerar_salas.py` → `assets/art/salas/`. Depende das
referências do jogador em `design/art/referencias/salas/`. O cenário em
movimento depende de `tools/art/animacoes_salas.py` (chamado por
`gerar_salas.py`; usa numpy e OpenCV, licenças BSD e Apache 2.0) e de
`Ambient`, que `Room.build` cria. Os NPCs dependem de
`tools/art/npcs_referencia.py` e de `design/art/referencias/personagens/`.

## 7. Parâmetros ajustáveis

| Onde | Chave | Valor | Faixa segura |
|---|---|---|---|
| gerar_salas.py | SALAS | sala → referência | — |
| gerar_salas.py | COLORS | 96 | 48–256 (menos: mais "pixel art", mais faixas) |
| mapa | art.background | nome da imagem | — |
| mapa | door.span | 4 (estrada da praça) | 1 até a largura da passagem |
| mapa | entity.painted | true (mercador) | — |
| mapa | examine.text / barrier | aviso de caminho fechado | — |
| mapa | torch.flame_at | [3, −7] e [−9, −7] (bomba) | dentro da célula da tocha |
| gerar_salas.py | APAGAR | caixas das lâmpadas apagadas | — |
| animacoes_salas.py | PECAS.vel | 0,9 (pás) | 0,3–2 rad/s (mais: parece motor) |
| animacoes_salas.py | GIROS.vel | engrenagens ±0,6–1,5 | 0,2–3 rad/s |
| animacoes_salas.py | estandarte amplitude / vel | 1,6 px / 2,2 | 0,5–3 px / 1–4 |
| animacoes_salas.py | LUZES | pontos das chamas pintadas, raio 14 | 8–24 px |
| animacoes_salas.py | AGUA | chafariz, tanque, poça | — |
| mapa | entity.look | exodia, mecanica | nome de `npc_<nome>.png` |
| npcs_referencia.py | HEIGHT | 40 px | 36–44 (Yggnus tem 42) |

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
7. Em toda sala pintada, cada porta, entidade e arbusto é alcançável a
   partir da entrada (`test_every_painted_room_is_connected`).
8. Examinar a barreira do portão da cidade no cruzamento mostra o aviso.
9. A Lamparina acende os dois lampiões pintados da bomba e eles brilham;
   a porta do poço abre.
10. Uma Carga junto à rachadura do poço abre um buraco que leva à adega.
11. As pás dos moinhos da estrada e do cruzamento giram; as engrenagens do
   cruzamento, da bomba e das torres giram; os estandartes balançam; as
   chamas pintadas respiram; a água do chafariz, do tanque e da poça
   cintila. Duas capturas com 1 s de intervalo mostram as pás em ângulos
   diferentes.
12. Exódia (oficina) e a Mecânica do Cais (bomba) aparecem no estilo dos
   personagens principais, sem o bloco do estilo antigo.
