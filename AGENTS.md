# AGENTS.md — PsychoTest+

## Design System
Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

Référence visuelle : `~/Téléchargements/stitch_refonte_ui_ux_psychotest_b_nin/`
(screen.png = mockup approuvé, code.html = implémentation web de référence).
Direction : Academic Focus — ivoire/parchemin, vert pin institutionnel,
bordeaux cérémonial, Plus Jakarta Sans voix unique, anti-gamification sobre.

## Tests (run before completing any task)

```bash
cd supabase/functions && deno task test   # Edge Functions suite (175 tests)
flutter analyze                          # static analysis
flutter test                             # Flutter widget/unit suite (60 tests)
```

Coverage gate: ≥80% per-file. Do not merge without green `deno task test`.

## Release workflow

Ship on `feat/mock-paywall` → PR against `clean-main` (NOT `main`). Bump
`pubspec.yaml` version + update `CHANGELOG.md` each release. Deferred P1
items are tracked in `TODOS.md`.
