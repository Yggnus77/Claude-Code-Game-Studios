# Jogabilidade clássica: espada, escudo, progressão e HUD

Status: em implementação (2026-11-10). Pedido do jogador: "a espada é
pequena e logo no início já aparece com todos os itens de combate"; o jogo
deve jogar como os action-adventures clássicos de visão de cima. Usamos as
**mecânicas do gênero** (golpe em arco, giro carregado, escudo passivo,
corações, caixa de item, item novo no baú grande da masmorra). Nomes,
personagens, arte, música e mapas continuam sendo do próprio jogo.

Substitui, para o combate de Yggnus, o combo de três golpes, a defesa
segurada e a esquiva livre de `design/kit/mecanicas-e-dificuldade.md` §3–5.
As regras das ferramentas (`ferramentas.md`) e das masmorras
(`masmorras.md`) continuam valendo.

## 1. Visão geral

- **Espada**: um golpe por toque, em arco largo na frente de Yggnus, com a
  lâmina desenhada grande, visível e com rastro. Segurar o botão depois do
  golpe **carrega** a espada (Yggnus anda devagar com a lâmina à frente; ela
  fere quem encosta). Soltar com a carga cheia faz o **giro**: a lâmina dá
  uma volta inteira em volta de Yggnus, com o dobro do dano.
- **Escudo**: passivo. Bloqueia golpes leves que vêm de frente enquanto
  Yggnus anda ou está parado. Não bloqueia enquanto ele golpeia, carrega,
  usa um item ou bebe. Golpes pesados ainda derrubam a guarda.
- **Esquiva**: fora do início. Nenhum botão de esquiva ou defesa aparece.
  Fica reservada para um item de corrida futuro.
- **Progressão**: Yggnus começa sem nada (só o frasco vazio). Espada e
  escudo vêm da história (cena p05). Gancho, Lamparina e Cargas continuam
  em seus lugares. O **Arco de Fio** sai da adega e vai para um baú da
  Torre de Akurame (antecâmara t06), para ser usado logo ali, na placa.
- **HUD**: corações (meio coração = 1 ponto de vida), caixa do item
  equipado com desenho e munição, contadores de Bronze e chaves, e a linha
  de teclas mostra só o que o jogador já tem.

## 2. Fantasia do jogador

"A espada tem peso e alcance: cada golpe varre a frente, a grama voa, o
inimigo é jogado para trás. Segurar e soltar o giro limpa a roda inteira.
Começo fraco e cada baú me deixa mais forte."

## 3. Regras detalhadas

### 3.1 Golpe

1. Tocar o botão da espada começa um golpe (se Yggnus tem a espada e não
   está ocupado). Um toque durante o golpe fica guardado por
   `input_buffer` s e começa o próximo assim que este termina.
2. O golpe tem **preparo** (`swing_startup`), **corte** (`swing_active`) e
   **volta** (`swing_recovery`). No preparo, a direção ainda pode mudar.
3. No corte, a lâmina gira de `arc_from` a `arc_to` graus em relação à
   direção de Yggnus, sempre no sentido horário da tela. Acerta tudo que a
   lâmina varre: inimigo, arbusto, pote, sino. Cada alvo leva no máximo um
   acerto por golpe.
4. O alcance é medido do pivô (`hit_pivot`, um pouco acima dos pés) até a
   ponta: `blade_inner` (cabo) a `reach` px.
5. Yggnus para durante o golpe (desacelera).

### 3.2 Carga e giro

1. Se o botão continua apertado quando o golpe termina, Yggnus passa a
   **carregar**: a lâmina fica apontada para a frente, ele anda a
   `charge_speed_factor` da velocidade e não vira (anda de lado).
2. Inimigos que encostam na lâmina carregada levam `poke_damage` e são
   empurrados; o mesmo inimigo só leva de novo depois de `poke_interval` s.
3. Depois de `charge_time` s a ponta brilha: carga cheia.
4. Soltar com a carga cheia faz o **giro**: a lâmina percorre
   `spin_degrees` em `spin_time` s, alcance `spin_reach`, dano do golpe
   × `spin_damage_factor`. Soltar antes disso só guarda a espada.
5. Levar dano cancela golpe, carga e giro.

### 3.3 Escudo passivo

1. Com o escudo, a guarda fica levantada sozinha quando Yggnus não está
   golpeando, carregando, girando, usando item, bebendo, puxando o gancho
   nem atordoado.
2. Cobre o cone frontal (`guard.angle_degrees`). Golpe leve de frente: sem
   dano. Golpe pesado: guarda quebra por `guard_break` s e entra
   `heavy_guard_damage`. A onda de Igris nunca é bloqueada.
3. Não há bloqueio perfeito nem botão de defesa.

### 3.4 Dano em Yggnus

Ao levar dano: recuo de `knockback` px em `hitstun` s e invencibilidade de
`damage_invulnerability` s, piscando.

### 3.5 Progressão

| Item | Onde | Como |
|---|---|---|
| Espada e escudo | Oficina (cena p05) | história |
| Gancho | Torre, t02/t03 | história |
| Lamparina | Casa da bomba (r02) | baú |
| Cargas de Bronze | Poço escuro (r03) | baú |
| Arco de Fio | Torre, antecâmara (t06) | baú, com 10 agulhas |
| 50 Bronze | Adega (r04) | baú (onde estava o arco) |

### 3.6 HUD

- Canto superior esquerdo: caixa do item equipado (desenho do item e
  munição), depois Bronze, chaves (em masmorra) e frascos.
- Canto superior direito: "VIDA" e os corações; abaixo, os quatro losangos
  dos Fragmentos de Âncora e o objetivo.
- Linha de teclas: andar, examinar e inventário sempre; espada só com a
  espada; item e troca só com ferramenta além do frasco.

## 4. Fórmulas

- Ângulo da lâmina no corte: `a(t) = facing + arc_from + (arc_to − arc_from) · e(t)`,
  `e(t) = 1 − (1 − u)²`, `u = (t − swing_startup) / swing_active` (rápido no
  começo, freia no fim: dá peso).
- Acerto de varredura: alvo em `p`, raio `r`, pivô `o`, `d = |p − o|`.
  Acerta se `d ≤ reach + r` e (`d ≤ blade_inner + r` ou o ângulo de `p − o`
  cai entre os ângulos da lâmina no passo anterior e no atual, com folga
  `asin(min(1, r / d))`).
- Dano do giro: `dano_espada × spin_damage_factor` (espada da oficina:
  1 × 2 = 2).
- Corações: `ceil(vida_max / 2)` corações; o coração `i` (0…) está cheio se
  `vida ≥ 2i + 2`, pela metade se `vida = 2i + 1`.

## 5. Casos-limite

- Golpe com o botão já solto antes do fim: nenhuma carga.
- Soltar a carga antes de cheia: volta ao normal, sem giro.
- Carga ao entrar em outra sala, morrer ou abrir diálogo: perdida.
- Giro que passa por vários sinos: cada sino toca uma vez, na ordem em que
  a lâmina passa.
- Escudo quebrado por golpe pesado: volta sozinho depois de `guard_break`.
- Save antigo com o arco já pego na adega: o arco continua com o jogador
  (o recibo é o mesmo); o baú da antecâmara abre vazio de arco e entrega só
  as agulhas que faltarem. Ver §8.

## 6. Dependências

`combate.json` (player, sword, guard), `inimigos.json` (knockback),
`recompensas-mundo.json`, mapas `t06_marco` e `r04_adega`, `Player`,
`SwordSwing`, `Guard`, `HitResolver`, `Hud`, `Controls`.

## 7. Parâmetros ajustáveis

`combate.json`:

| Chave | Valor | Nota |
|---|---|---|
| player.speed | 100 | px/s |
| player.acceleration / deceleration | 6000 / 6000 | partida e parada quase imediatas |
| player.knockback | 30 | px |
| player.hitstun | 0.22 | s |
| player.damage_invulnerability | 1.0 | s |
| sword.swing_startup / active / recovery | 0.03 / 0.12 / 0.08 | s |
| sword.arc_from / arc_to | −100 / 75 | graus |
| sword.reach / blade_inner | 27 / 5 | px |
| sword.hit_pivot | [0, −6] | px |
| sword.charge_time | 0.75 | s |
| sword.charge_speed_factor | 0.55 | |
| sword.spin_time / spin_degrees / spin_reach | 0.36 / 380 / 31 | |
| sword.spin_damage_factor | 2 | |
| sword.poke_damage / poke_interval | 1 / 0.35 | |
| guard.perfect_window / minimum_retrigger | 0 / 0 | escudo passivo |
| weapons.espada_oficina | 1 | dano por golpe |

`inimigos.json` knockback: rastejo 24, mariposa 20, soldado 22, guarda 10.

## 8. Critérios de aceitação

1. Um novo jogo começa sem espada, sem escudo, e a linha de teclas não
   mostra espada, item, troca, esquiva nem defesa.
2. Depois de p05 a linha mostra a espada; esquiva e defesa nunca aparecem.
3. Um golpe para a direita acerta um inimigo acima-à-direita, à frente e
   abaixo-à-direita dentro do alcance, e não acerta um inimigo atrás.
4. Segurar o botão por `charge_time` depois do golpe e soltar faz o giro,
   que acerta inimigos dos quatro lados com dano 2.
5. Soltar antes de `charge_time` não gira.
6. Com o escudo, um golpe leve de frente não tira vida com Yggnus parado, e
   tira enquanto ele golpeia.
7. O arco está no baú de t06; a adega dá 50 Bronze.
8. O HUD mostra corações (3 cheios no começo) e a caixa do item.
