## Smoke Check Report
**Date**: 2026-11-06
**Sprint**: Etapa 8 — Dois mistérios e uma relíquia (`design/kit/plano-implementacao.md`)
**Engine**: Godot 4.7.2
**QA Plan**: Not found (the kit's stage plan is the scope)
**Argument**: blank

### Automated Tests

**Status**: PASS (149 tests, 149 passing), `commands.test`, exit 0. The runner counts script errors
during a test and unloadable test files as failures.

**Build check**: PASS — Windows and Linux release exports exit 0; the exported Linux binary runs
`--headless --quit-after 120` with exit 0 and no errors.

### Test Coverage

Every Etapa 8 criterion maps to a test: `production/qa/evidence/etapa-8-misterios/README.md`.

### Manual Smoke Checks

Checklist source: standard fallback list — no QA plan scope, no `production/qa/smoke-tests.md`, no `tests/smoke/`.

- [x] Game launches without crash — PASS (exported Linux build, headless)
- [x] Mystery question and relic inventory render — PASS (screenshots retained)
- [ ] Developer playthrough — NOT RUN: pending the user's "teste 8"

### Verdict: NOT ASSESSED (manual)

Automated tests and build PASS; the verdict becomes PASS or FAIL with the user's teste 8 feedback.
