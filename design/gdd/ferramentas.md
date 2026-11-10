# Ferramentas novas: Arco de Fio, Cargas de Bronze e Lamparina

Status: em implementação (2026-11-10), parte 3 do pedido "Tudo, nessa ordem"
(configurações → exploração → masmorras → itens). Mecânicas gerais do
gênero; nomes, mapas e arte são do próprio jogo. Números do kit
(`design/kit/mecanicas-e-dificuldade.md` §7, `roteiro-jogo-completo.md`)
onde o kit já os define.

## 1. Visão geral

Três ferramentas novas vão para o botão de item, junto do frasco e do gancho:

- **Arco de Fio** (`arco_fio`, item do kit): dispara **agulhas**
  (`agulha_fio`, munição do kit, até 20). Fere inimigos e aciona **placas**
  a distância. Agulha que erra fica cravada e pode ser recolhida.
- **Cargas de Bronze** (`carga_bronze`, item do kit, até 9): uma carga
  posta no chão explode depois de um pavio. Fere tudo em volta (inclusive
  Yggnus), quebra potes e arbustos e derruba **paredes rachadas**.
- **Lamparina de Óleo** (`lamparina_oleo`, item novo): acende **tochas**.
  Com ela, Yggnus enxerga mais longe em salas escuras.

Tudo é opcional: o caminho da história do kit não muda. Cada ferramenta
abre um segredo novo, em cadeia: Lamparina → Poço escuro (Cargas) → Adega
atrás da parede rachada (Arco) → Mirante da torre atrás da placa.

## 2. Fantasia do jogador

"Cada ferramenta nova muda o que eu vejo nas salas que já conheço." A
parede rachada que parecia decoração, as tochas apagadas na casa da bomba e
a placa alta na antecâmara viram convites para voltar.

## 3. Regras

### Botão de item e troca rápida

- O botão de item usa a ferramenta equipada. A troca rápida passa pela
  ordem `frasco → gancho → arco → cargas → lamparina`, pulando o que
  Yggnus não tem.
- Ganhar uma ferramenta nova equipa ela na hora e mostra como usar.
- O HUD mostra a ferramenta e a munição: "Item (L): Arco 12".
- As Cargas continuam na troca mesmo com 0 (flag `gear.cargas`), para o
  jogador lembrar que pode comprar mais.
- Usar o arco ou as cargas sem munição avisa onde conseguir mais.
- Nenhuma ferramenta funciona enquanto Yggnus ataca, esquiva, bebe, usa o
  gancho ou está atordoado. Usar uma ferramenta abaixa o escudo, como o
  gancho. Durante a preparação do arco (0,18 s), Yggnus fica ocupado.

### Arco de Fio

- Preparação 0,18 s, agulha a 260 px/s, recarga 0,30 s, dano 2 (kit §7).
  Alcance 224 px.
- A agulha voa reto na direção em que Yggnus olha. Passa por cima de vãos.
- Para no primeiro inimigo (fere), na primeira **placa** (aciona) ou na
  primeira parede, pote, arbusto, baú, pessoa, marco, sino, argola ou peso
  (para sem quebrar).
- Agulha que para numa parede ou chega ao fim do alcance cai no chão e
  pode ser recolhida por 10 s (kit: "agulhas sem alvo podem ser
  recuperadas"). Agulha que acerta alguma coisa é gasta.
- Escudo do guarda bloqueia agulha de frente, como bloqueia a espada.
- Igris não é ferido por agulhas: elas batem e caem.
- **Placa** (entidade `plate`): a primeira agulha que chega à linha da
  placa a até 16 px do centro dela (a coluna da placa e um pouco das
  vizinhas) liga a flag `sets_flag` da placa para sempre. A espada não
  aciona a placa.
- **Recipiente de agulhas** (entidade `refill`): examinar completa as
  agulhas até `amount` (10), quantas vezes quiser. Fica antes de cada
  placa (kit: reposição fixa antes dos desafios).

### Cargas de Bronze

- Usar põe uma carga um passo à frente de Yggnus (no chão livre; se a
  frente for parede, aos pés dele). No máximo 2 cargas ao mesmo tempo.
- Pavio 1,6 s, piscando mais rápido no fim. A explosão tem raio 28 px.
- Dentro do raio: inimigos levam 3 de dano (o escudo não bloqueia),
  potes e arbustos quebram, e Yggnus leva 1 de dano se estiver perto, mas
  a própria carga nunca tira o último ponto de vida.
- **Parede rachada** (porta com `"cracked": true`): se a explosão alcança o
  arco da porta (raio + 12 px), a parede desmorona, a flag do portão da
  porta é ligada e a passagem fica aberta para sempre.
- O comerciante vende "Três cargas" por 12 Bronze (`precos.tres_cargas`),
  só depois que o jogador já teve cargas.

### Lamparina de Óleo

- Usar acende a **tocha** (entidade `torch`) à frente de Yggnus (até
  18 px). Sem tocha à frente, a chama só tremula.
- Uma tocha acesa fica acesa durante a visita. Quando todas as tochas da
  sala com a mesma `sets_flag` estão acesas, a flag é ligada e elas ficam
  acesas para sempre.
- Sala escura (`"art": {"dark": true}`): a luz ambiente cai. Com a
  Lamparina, a luz em volta de Yggnus fica maior.

### Onde cada coisa está

| Coisa | Sala | Detalhe |
|---|---|---|
| Lamparina de Óleo | Bomba d'água (`r02_bomba`) | baú em (5, 20) |
| Tochas | Bomba d'água | (30, 10) e (30, 14), abrem a porta leste (`world.torches.r02_bomba`) |
| 3 Cargas de Bronze | Poço antigo (`r03_poco`, novo, escuro) | baú |
| Parede rachada | Cruzamento (`r01_cruzamento`) | porta norte (`world.cracked.r01_adega`) |
| Arco de Fio + 10 agulhas | Adega escondida (`r04_adega`, nova) | baú, com recipiente de agulhas |
| Placa | Antecâmara (`t06_marco`) | no alto da parede norte, abre a porta norte (`world.plate.t06_marco`) |
| Recipiente de agulhas | Antecâmara | ao lado da entrada |
| 60 Bronze | Mirante (`t08_mirante`, novo, faz parte do mapa da torre) | baú |

Potes e arbustos podem soltar agulhas (`agulha_3`) só depois que o jogador
tem o arco; antes disso a mesma sorte não dá nada.

## 4. Fórmulas

- Agulha: posição(t) = origem + direção × 260 × t, até 224 px
  (≈ 0,86 s). Checagem a cada 4 px (como o gancho), então nunca atravessa
  parede.
- Dano da agulha = 2 (`dano_base` do kit). Dano da carga = 3 nos inimigos,
  1 em Yggnus.
- Alcance da explosão: distância(centro da carga, alvo) ≤ 28 px
  (+ raio do corpo do inimigo; + 12 px para o arco da parede rachada, ou seja, a carga posta logo abaixo da parede alcança).
- Recipiente: agulhas = max(agulhas, 10), limitado a 20.
- Compra: 12 Bronze → +3 cargas, só se couber (≤ 9).

Todos os números estão em `assets/data/ferramentas.json`.

## 5. Casos especiais

- Agulha numa sala que muda (porta, morte): some com a sala; não é
  devolvida.
- Carga com pavio aceso quando Yggnus passa pela porta: some com a sala,
  sem explodir e sem devolver a carga.
- Explosão dentro da arena de Igris: fere os inimigos comuns, nunca Igris.
- Carga posta em cima de um vão: vai para os pés de Yggnus.
- Placa já acionada: agulhas seguintes só param nela.
- Tochas acesas e flag ligada de saves anteriores: a sala já abre com as
  tochas acesas.
- Sem nenhuma ferramenta nova: o botão continua igual (frasco/gancho).
- Save antigo com `equipped_tool` "frasco" ou "gancho": continua válido.

## 6. Dependências

Player (estados de ocupado, direção), Room (desenho, colisão, luzes),
RoomData (portas e entidades), GameState (itens, flags, recibos), Shop,
HUD, EnemyBase (dano), Breakable, Dungeons (o Mirante entra no mapa da
torre pela porta norte da antecâmara), SaveGame (`equipped_tool`).

## 7. Ajustes (tuning)

`assets/data/ferramentas.json`: preparação, velocidade, recarga, dano e
alcance do arco; tempo que a agulha caída dura; pavio, raio, dano, dano em
Yggnus, distância de colocação e máximo de cargas; alcance da lamparina e
tamanho da luz em sala escura; quantidade do recipiente.
`economia-progressao.json` `precos.tres_cargas` e `exploracao.json` (sorte
de agulhas nos potes e arbustos).

## 8. Critérios de aceitação

1. A troca rápida passa só pelas ferramentas que o jogador tem, na ordem
   acima, e o HUD mostra a munição.
2. Uma agulha fere um inimigo em 2 e para na primeira parede; a agulha
   que erra pode ser recolhida.
3. Uma agulha na placa da antecâmara abre a porta norte; a espada não.
4. Uma carga perto da parede rachada do Cruzamento abre a porta norte;
   longe dela, não.
5. A carga fere inimigos (3), quebra potes e fere Yggnus (1) quando ele
   está no raio.
6. As duas tochas acesas pela Lamparina abrem a porta leste da Bomba
   d'água, e continuam acesas ao voltar.
7. Sem munição, o uso avisa e não gasta nada.
8. Saves antigos carregam; saves novos guardam a ferramenta equipada.
