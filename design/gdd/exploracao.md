# Exploração: telas deslizantes, arbustos, potes e fragmentos

Status: implementado (2026-11-08). Pedido do usuário: trazer as mecânicas do
gênero de ação e aventura de cima para baixo, na ordem escolhida (exploração,
depois masmorras de chaves, depois itens novos). Só mecânicas gerais do
gênero; nomes, arte, mapas e músicas são do próprio jogo.

## 1. Visão geral

Andar pelo mundo fica mais vivo: a tela desliza de uma sala para a vizinha,
a espada corta arbustos e quebra potes que às vezes deixam uma gota de vida
ou Bronze, e os Fragmentos de Âncora (que já davam +1 de vida a cada 4)
ganham um indicador de 4 losangos ao lado da vida, como pedaços de coração.

## 2. Fantasia do jogador

"Cada canto da sala pode ter algo." O jogador corta o mato do caminho, quebra
potes da torre atrás de um respiro de vida, e sente o mapa como um lugar
contínuo, não telas soltas.

## 3. Regras

- **Tela deslizante.** Portas com `side` (north, south, east, west) deslizam
  a câmera da sala antiga para a nova em `slide_time` s, quando a porta de
  chegada fica no lado oposto da nova sala; o jogo fica pausado
  durante o deslize. A sala antiga é uma cópia só de desenho, encostada na
  nova com as portas alinhadas. Portas sem `side` continuam com o
  escurecimento.
- **Arbustos e potes.** Listados no mapa em `"breakables": {"bush": [[x, y]]}`,
  só em chão. Bloqueiam a passagem. Um golpe de espada que alcança o objeto o
  quebra (um golpe basta). Arbusto deixa um toco que não bloqueia; pote some.
- Um golpe pode quebrar dois objetos vizinhos de uma vez (como no gênero);
  cada um sorteia seu prêmio. Os pesos já contam com isso.
- **Reaparecem** ao entrar de novo na sala (são do cenário, não progresso).
- **Prêmios.** Sorteio com pesos de `exploracao.json`: nada, `vida_1` (cura 1
  ao tocar) ou `bronze_N`. A gota some depois de `life_drop.lifetime` s.
- **Arena de chefe:** nada cai enquanto um chefe está na sala, e os mapas de
  arena não têm quebráveis (mecânicas §"snapshot de tentativa": sem lucro
  repetindo tentativas).
- **Fragmentos de Âncora:** inalterados (4 = +1 de vida máxima, até 14). O HUD
  mostra quantos dos 4 já foram achados; ao completar 4 o indicador brilha.

## 4. Fórmulas

- Prêmio: `roll ∈ [0,1)`, `alvo = roll × Σpesos`; percorre a tabela subtraindo
  os pesos até ficar negativo. Pesos negativos contam como 0.
- Chance por arbusto (padrão): nada 70%, vida 15%, Bronze 1 15%.
- Chance por pote (padrão): nada 40%, vida 25%, Bronze 1 20%, Bronze 5 15%.
- Vida máxima: `min(14, 6 + fragmentos ÷ 4)` (já existia).

## 5. Casos especiais

- Sair da sala no meio do deslize (voltar ao título): a pausa é desfeita.
- Chão do mapa com parede ou célula repetida em `breakables`: ignorada.
- Gota de vida com vida cheia: é recolhida sem efeito.
- Cópia da sala antiga não tem paredes nem quebráveis que a espada alcance.

## 6. Dependências

Room/RoomData (mapas), Player (alcance da espada), Pickup (gotas), GameState
(Bronze, fragmentos), HUD, `tools/art/objetos_hd.py` (arbusto, toco, pote).

## 7. Ajustes

`assets/data/exploracao.json`: `drops` por tipo, `solid`, `stub`,
`fx_color`, `life_drop.lifetime`, `slide_time`. Posições nos
mapas (`breakables`).

## 8. Critérios de aceite

- Atravessar uma porta lateral mostra as duas salas lado a lado durante o
  deslize e termina com a câmera presa à nova sala
  (`tests/integration/world/test_exploration.gd`).
- Um golpe corta o arbusto à frente; o toco não bloqueia; o arbusto volta na
  próxima visita.
- Pote some e o prêmio sorteado aparece; nada cai na arena do chefe.
- Todo quebrável dos mapas está em chão alcançável e não fecha caminhos.
- O indicador mostra fragmentos % 4 e brilha ao completar 4.
