# Smoke check: ferramentas novas (2026-11-10)

Parte 3 do pedido "Tudo, nessa ordem" (configurações → exploração →
masmorras → itens). Desenho: `design/gdd/ferramentas.md`.

## O que mudou

- Botão de item com cinco ferramentas na troca rápida: frasco, gancho,
  Arco de Fio, Cargas de Bronze e Lamparina de Óleo (só as que o jogador
  tem). HUD com munição ("Arco 9", "Cargas 2"); inventário com a linha
  MUNIÇÃO.
- Arco de Fio (números do kit): agulha a 260 px/s, dano 2, para na parede;
  a que erra fica no chão e pode ser recolhida. Placas acionadas só por
  agulha. Recipiente de agulhas completa até 10.
- Cargas de Bronze: pavio 1,6 s, raio 28 px, 3 de dano (escudo não
  bloqueia), quebra potes, fere Yggnus (1) se ele estiver perto, derruba
  paredes rachadas. Comerciante vende três por 12 Bronze depois da
  primeira vez.
- Lamparina: acende tochas; duas acesas na Bomba d'água abrem o Poço
  antigo (escuro), onde a luz de Yggnus fica maior com ela.
- Salas novas: Poço antigo (`r03_poco`), Adega escondida (`r04_adega`),
  Mirante (`t08_mirante`, no mapa da torre). O caminho da história não mudou.
- Arte nova: tocha apagada e acesa, placa de alvo (normal e acertada),
  recipiente de agulhas, arco tapado de tijolos rachados; carga, agulha,
  explosão (anel de fogo, fumaça, lascas, clarão) desenhadas no jogo.

## Verificação

- Testes: 262 passaram, 0 falharam (`tests/unit/world/test_tool_rules.gd`,
  `tests/integration/world/test_tools.gd`, mais os antigos).
- Revisão GDScript e QA: 13 achados corrigidos. Os 8 testes de regressão
  falharam no código antigo antes da correção:
  - a agulha voava quase o dobro da velocidade e do alcance;
  - durante a preparação do arco ainda dava para atacar, esquivar ou
    lançar o gancho;
  - agulhas tocadas com a aljava cheia sumiam;
  - a agulha atravessava baús, pessoas, sinos e o peso;
  - errar a placa por uma coluna não contava;
  - a carga podia matar o próprio Yggnus;
  - a loja vendia cargas escondidas;
  - o texto dos baús não dizia a quantidade nem as agulhas que vêm junto.
  Também corrigidos, sem teste próprio: agulha caída nunca fica num vão,
  ferramentas válidas no save lidas do `ferramentas.json`, números da tocha
  e da placa no JSON, dica de troca de item nas quatro ferramentas,
  coordenadas das tochas no GDD e foto da parede rachada refeita.
- Imagens: `production/qa/evidence/ferramentas/` (01–18, do baú da
  lamparina à loja).
