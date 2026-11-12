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
