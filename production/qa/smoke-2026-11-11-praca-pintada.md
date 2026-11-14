# Smoke check — Praça pintada (2026-11-11)

Spec: `design/gdd/salas-pintadas.md`. Build: teste20 (inclui teste19).

## Automated

- Full suite: 311 passed, 0 failed (`tests/run_tests.gd`).
- New: `test_a_painted_room_draws_its_picture_instead_of_tiles`,
  `test_a_tile_room_is_not_painted`, `test_people_in_the_picture_get_no_sprite`,
  `test_a_wide_way_out_covers_its_whole_span`,
  `test_every_painted_map_matches_its_picture`,
  `test_every_painted_room_is_connected` (watched failing on the first grid,
  which cut off the workshop door and the road),
  `test_world_reward_tiles_match_the_maps` (watched failing on the old
  fragment tile), `test_a_save_standing_where_the_room_now_has_a_wall_still_loads`
  (watched failing without the fix),
  `test_leaving_the_workshop_lands_on_the_square_door_steps`,
  `test_the_square_road_is_barred_until_p07_then_leads_to_the_road`.

## Observed (screenshots in `production/qa/evidence/salas/`)

| Shot | What it shows | Result |
|---|---|---|
| praca_01 | Arriving from the workshop on the wooden door's steps | PASS |
| praca_02 | Facing the merchant at the stall (painted, no second sprite) | PASS |
| praca_03 | Road exit barred before p07 | PASS |
| praca_04 | Bushes in the picture's style, cut by the sword | PASS |
| praca_05 | Lower right corner, bush and pot area | PASS |

## Review findings fixed

- Grid split the square into 4 parts (fountain top and rim too wide).
- Floor over lamp bases, a pot, a crate and a gap under the stall.
- Barrier drawn 4 tiles wide for any closed way; now as wide as the span.
- Player glow brightened the already-lit picture; off in painted rooms.
- Fallback drawing hid the picture when the object sheet was missing.
- `recompensas-mundo.json` kept the old fragment tile.

## Known

- Doors between the square, the workshop and the road fade instead of
  sliding until those rooms are painted with matching sides.
- The lowest rows of the square sit under the HUD buttons and objective box.

## 2026-11-12 — Oficina de Exódia (teste21)

- Reference 1 with the painted Yggnus removed (mirror of the rug and floor);
  room 40 × 23, door on the south wall (span 4), slides to the square.
- Full suite: 312 passed, 0 failed. New: `test_the_workshop_and_the_square_slide_into_each_other`.
  The old tile workshop is kept as a test fixture (`tests/fixtures/maps/v00_oficina.json`)
  for the tile-art tests.
- QA review fixed: back-wall baseboard (row 7) and a crate were floor.
- Evidence: `production/qa/evidence/salas/oficina_01_inicio.png`,
  `oficina_02_relogio.png`, `oficina_03_invasao.png` — PASS.

## 2026-11-12: Yggnus e inimigos pelas folhas do usuário (teste22)

- Folhas 11, 12 e 13 (`design/art/referencias/personagens/`) recortadas por
  `tools/art/yggnus_referencia.py` e `tools/art/inimigos_referencia.py`
  (ajudantes em `tools/art/recorte.py`).
- Suíte completa: 311 de 312 passaram; a falha era o teste que fixava o
  tamanho antigo do quadro de Igris (48 × 64). Ele agora confere que Igris é
  maior que um inimigo comum, e passa.
- Evidência: `production/qa/evidence/personagens/01_inimigos_praca.png`,
  `02_yame.png`, `03_yggnus_oficina.png`, `04_igris.png`.
- Limite conhecido: antes da cena p05 Yggnus aparece com espada e escudo,
  porque a folha do usuário sempre os mostra.

## 2026-11-13: estrada pintada (referência 3, teste23)

- `r00_estrada` usa a referência 3 como fundo; grade, portas e entidades
  refeitas (design/gdd/salas-pintadas.md §3.3).
- Saída da praça ao norte chega na porta sul da estrada deslizando a tela
  (evidência `production/qa/evidence/salas/estrada_01_chegada.png`).
- Fragmento 2 atrás de dois arbustos ao lado do poço
  (`estrada_02_poco.png`).
- O teste de ligação agora exige que as portas sejam alcançadas sem cortar
  nada; vi ele falhar com arbustos tapando a porta leste antes de confiar nele.
- Suíte completa depois dos ajustes: 312 de 312.

## 2026-11-13: bomba, poço e torre pintados (imagens por sala, teste24)

- Bomba d'água, poço antigo e as oito salas da torre usam as imagens novas
  do usuário (`design/art/referencias/salas/`); a torre sobe de baixo para
  cima (design/gdd/salas-pintadas.md §3.4 e §3.5).
- Base, guardas, antecâmara e câmara de Igris ganharam a segunda saída
  copiada da própria porta pintada (`tools/art/gerar_salas.py`, `PORTAS`).
- O mapa da masmorra usa `map_side` para essas saídas; os nove cômodos
  aparecem (`test_the_tower_layout_follows_its_side_doors`).
- Testes genéricos de combate e movimento passaram a usar a adega (sala de
  blocos); os testes de porta em parede usam a base antiga como fixture
  (`tests/fixtures/maps/t00_base.json`).
- Suíte completa: 312 de 312.
- Evidência: `production/qa/evidence/salas/bomba_01.png`, `poco_01.png`,
  `travessia_01.png`, `contrapesos_01.png`, `oficina_gancho_01.png`,
  `sinos_01.png`, `torre-01_base.png`, `torre-02_guardas.png`,
  `torre-03_antecamara.png`, `torre-04_igris.png` (sino de Igris aceso no
  alto da parede durante a mostra da ordem).

## 2026-11-13: Yggnus andando de lado e correntes de Yame (teste25)

- Os quadros de andar de lado vinham da folha do usuário olhando para a
  esquerda; agora são espelhados em `tools/art/yggnus_referencia.py`.
  Teste novo `test_yggnus_walks_sideways_facing_where_he_goes`: falhou com a
  folha antiga e passa com a nova.
- As amarras de Yame viraram correntes de ferro (elos com contorno escuro,
  estaca com um elo por golpe, rachadura depois do primeiro golpe, faíscas
  ao partir). Textos do objetivo e avisos passaram a dizer "correntes".
- Suíte completa: 313 de 313.
- Evidência: `production/qa/evidence/personagens/05_andando_direita.png`,
  `06_andando_esquerda.png`, `07_correntes_yame.png`.

## 2026-11-13: cruzamento pintado (teste26)

- `r01_cruzamento` usa a imagem nova do usuário (`r01-cruzamento.png`);
  portas para estrada, bomba, torre e adega refeitas (salas-pintadas.md §3.3).
- Testes que usavam posições do cruzamento (carga, pista m01, parede rachada)
  ajustados ao chão novo.
- Evidência: `production/qa/evidence/salas/cruzamento_01.png`.

## 2026-11-14: salas trafegáveis, avisos e mecanismos na pintura (teste27)

- Botão de correr: segurar Shift (ou LB) multiplica a velocidade por 1,6
  (`combate.json` `player.run_speed_factor`); configurável no menu.
- Chão refeito pela pintura na oficina (vão da porta é chão) e na praça
  (calçamento em volta do chafariz e da estrada). Pista m01 do chafariz
  passou para 26, 16.
- Caminhos que a pintura mostra e não levam a lugar nenhum viraram avisos
  `examine` (estrada do norte, portão da cidade, moinho e ruínas no
  cruzamento; portão e moinho na estrada). Os que mostram passagem aberta
  ganham a barreira listrada. O aviso quebra em duas linhas.
- Bomba: escada e mezanino andáveis, baú da Lamparina no mezanino; os
  lampiões pintados ao lado da porta do poço são as tochas (apagados no
  fundo, chama e luz desenhadas quando acesos).
- Poço: a rachadura pintada leva à adega (antes era o arco das ruínas do
  cruzamento). O sinal salvo da parede é o mesmo, então jogos antigos
  continuam com a passagem aberta. Depois da explosão aparece um buraco.
- Baú, pista, recipiente, placa e marco das salas pintadas usam recortes
  das próprias pinturas (`tools/art/objetos_pintados.py`).
- Testes novos: aviso do portão examinável; lampiões pintados são as
  tochas; parede rachada no poço. Suíte completa: 316 de 316.
- Evidência: `production/qa/evidence/ambiente/01_oficina.png` a
  `10_poco_buraco_aberto.png`, `04b_cruzamento_portao_aviso.png`,
  `11_torre_salas.png`.

## 2026-11-14: correções do teste27 (teste28)

- Praça: a frente do chafariz é calçamento livre; a estrada do norte se
  alcança pelos dois lados.
- Portão da cidade (estrada e cruzamento) pintado com a grade baixada,
  como o aviso diz.
- Voltar pela porta logo depois de chegar funciona (teste novo
  `test_turning_straight_back_through_the_door_just_used`).
- Suíte completa: 317 de 317.
- Evidência: `production/qa/evidence/ambiente/12_praca_estrada_direita.png`,
  `13_estrada_portao_grade.png`, `14_cruzamento_portao_grade.png`.
