## Smoke Check Report
**Date**: 2026-11-08
**Sprint**: Arte P2, arte detalhada (`design/art/art-bible.md` §§ 5, 6, 6.1)
**Engine**: Godot 4.7.2
**Argument**: blank

### Automated Tests

**Status**: PASS (194 tests, 194 passing), `commands.test`, exit 0.
New: `tests/unit/world/test_room_art.gd` (tall wall, furniture, rugs, decor, lights, light cap, doors set in the wall, effects without a parent).

**Build check**: PASS. Linux and Windows release exports exit 0 (builds teste13).

### Manual Smoke Checks

- [x] Every theme draws the tall wall with decoration, rugs/paths, decals, shadows and lights. PASS (`production/qa/evidence/arte-p2/sala_*.png`)
- [x] Yggnus in three views and every animation; enemies, Yame, Igris and objects redrawn. PASS (`folha_*.png`, `sala_z_combat.png`)
- [x] Telegraphs readable under the darker ambient; Igris's wave drawn above Yggnus with a red light. PASS (`igris_onda.png`; QA pass over 13 rooms)
- [x] Hit sparks with a light flash, step dust, motes, slash crescent. PASS (`golpe_faiscas.png`)
- [x] Doors drawn set into the nearest wall; chasm has an edge. PASS (`porta_na_parede.png`, `abismo_t03.png`)
- [ ] Playing the slice start to end with the new art. NOT ASSESSED until the author's "Testado"

### Review

`godot-gdscript-specialist` and `qa-tester` passes; all verified findings fixed (static ground layer drawn once per build, old room nodes removed at once, light cap, height sorting of effects, data-driven flicker and pickup lights, furniture vs. tall wall, gradient cache, Igris wave contrast, doors in the wall, chasm edge, guard badge, ink contrast, clue glow).

### Verdict: PASS (automated), manual NOT ASSESSED
