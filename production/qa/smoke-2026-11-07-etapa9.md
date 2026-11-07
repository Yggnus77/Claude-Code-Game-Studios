## Smoke Check Report
**Date**: 2026-11-07
**Sprint**: Etapa 9 — Salvamento e exportação (`design/kit/plano-implementacao.md`)
**Engine**: Godot 4.7.2
**QA Plan**: Not found (the kit's stage plan is the scope)
**Argument**: blank

### Automated Tests

**Status**: PASS (169 tests, 169 passing), `commands.test`, exit 0. The runner counts script errors
during a test and unloadable test files as failures.

**Build check**: PASS. Windows and Linux release exports exit 0. The exported Linux binary, copied to
an unrelated folder with a separate user-data folder, ran `--headless --quit-after 120 -- --slot=1`
twice with exit 0 and no errors: the first run created `slot_1.json`, the second continued it and
created `slot_1.bak.json`. No developer path appears in the binary.

### Test Coverage

Every Etapa 9 criterion maps to a test: `production/qa/evidence/etapa-9-salvamento/README.md`.

### Manual Smoke Checks

Checklist source: standard fallback list (no QA plan scope, no `production/qa/smoke-tests.md`, no `tests/smoke/`).

- [x] Game launches without crash. PASS (exported Linux build, headless, from another folder)
- [x] Title, recovery notice, pause menu and continue render. PASS (screenshots retained)
- [x] Save, close and load in all 13 rooms. PASS (qa-tester headless probe)
- [ ] Developer playthrough on Windows and on a second machine. NOT RUN: pending the user's "teste 9"

### Verdict: NOT ASSESSED (manual)

Automated tests and build PASS. The verdict becomes PASS or FAIL with the user's teste 9 feedback.
