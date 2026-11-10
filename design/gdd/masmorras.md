# Masmorras de chaves: chave pequena, chave grande, mapa e bússola

Status: implementado (2026-11-10) na Torre de Akurame, por escolha do usuário
(cartão de decisão de 2026-11-09). Mecânicas gerais do gênero; nomes, mapas e
arte são do próprio jogo. A história do kit não muda.

## 1. Visão geral

Cada masmorra (`assets/data/masmorras.json`) tem um mapa, uma bússola, chaves
pequenas e uma Chave Grande. O mapa da masmorra aparece no inventário ao lado
do texto: salas visitadas acesas, as conhecidas só pelo mapa apagadas, e a
sala atual piscando. A bússola marca baús fechados e a sala do chefe. A porta
do chefe pede a Chave Grande.

## 2. Fantasia do jogador

"Estou dominando este lugar." Achar o mapa revela o que falta; a bússola diz
onde ainda há tesouro; a Chave Grande é o sinal de que o chefe está perto.

## 3. Regras

- **Torre de Akurame:** salas com prefixo `t`, início `t00_base`.
  - Chave pequena: a `key_ak_base` do kit (baú da base), gasta ao abrir a
    porta base ↔ guardas pela primeira vez (regra original do kit).
  - Mapa da Torre: baú na sala dos guardas (`t01_guardas`, 26,4).
  - Bússola da Torre: baú dos contrapesos (`t04_pesos`, 6,20).
  - Chave Grande de Akurame: baú da galeria dos sinos (`t05_sinos`, 4,20).
  - Mirante (`t08_mirante`, sala opcional ao norte da antecâmara): abre com
    uma agulha do Arco de Fio na placa (`design/gdd/ferramentas.md`); entra
    no mapa como qualquer sala e a bússola marca o baú dele.
  - Porta antecâmara ↔ Igris: `gate: "boss_key:chave_chefe_akurame"`. A
    chave não é gasta. Saves que já venceram Igris (`seen.t10`) nunca ficam
    presos.
- **Disposição do mapa:** busca a partir do início pelas portas laterais cuja
  porta de volta fica no lado oposto (as mesmas que deslizam a tela).
- **Salas visitadas:** flag `visited.<sala>` na primeira entrada.
- **HUD:** dentro da masmorra a linha de status mostra "Chaves N" e "Chave
  Grande".
- **Avisos:** porta grande diz qual chave falta; ao abrir mapa, bússola ou
  Chave Grande, o aviso explica para que servem.

## 4. Fórmulas

Sem números novos. Célula da sala no mapa = soma dos passos das portas
(norte (0,-1), sul (0,1), leste (1,0), oeste (-1,0)) desde o início.

## 5. Casos especiais

- Duas salas que cairiam na mesma célula: a segunda fica fora do mapa.
- Portas sem lado oposto (base ↔ arena, ambas "north") não entram no mapa:
  o atalho de volta da arena para a base não aparece nele.
- Saves de antes da Chave Grande que já chegaram à arena (`visited.t07_igris`)
  passam pela porta sem a chave, para ninguém ficar preso.
- Objetivo: depois dos sinos, "Encontre a Chave Grande na Galeria dos sinos"
  até pegar a chave.
- Recompensa de baú já recebida: o baú some da bússola.
- Fora de masmorra: sem mapa no inventário e sem linha de chaves.

## 6. Dependências

RoomData (portas e baús), GameState (itens, flags, recibos), recompensas do
mundo (`recompensas-mundo.json`), itens (`itens.json`), HUD/inventário.

## 7. Ajustes

`masmorras.json` (itens, sala do chefe, flag de chefe vencido, prefixo,
início); posições dos baús nos mapas.

## 8. Critérios de aceite

- `tests/unit/world/test_dungeons.gd`: disposição da torre, salas mostradas
  por visita ou mapa, bússola com baús e chefe, porta grande, contagem de
  chaves.
- `tests/integration/world/test_exploration.gd`: a porta de Igris fica
  fechada sem a Chave Grande e abre com ela; linha de chaves só na torre.
- Imagens em `production/qa/evidence/masmorras/`.
