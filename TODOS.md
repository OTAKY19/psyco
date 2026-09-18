# TODOS

Deferred work captured by plan reviews. Nothing here blocks the Mock Paywall validation ladder.

## P3 — deferred

### Demo unlock popup restyle
- **What:** Restyle `UnifiedActivationWidget` (demo path, kept after CT4) to DESIGN.md — `rounded-full` pill, drop the star icon, palette-correct copy.
- **Why:** Current rounded-25 pill + star icon + off-palette "Contenu Premium" copy violate DESIGN.md anti-gamification rules on a user-facing surface.
- **Pros:** Visual consistency; removes a hard design-spec violation.
- **Cons:** ~20m of cosmetic work outside the payment wedge.
- **Context:** Real results path uses the inline CTA (D4); this is only the retained demo-path popup. See `lib/widgets/unified_results_widget.dart` and `UnifiedActivationWidget`.
- **Depends on / blocked by:** CT4.
- **Source:** plan-design-review 2026-09-17 (TODO A).

### CI job for edge-function tests
- **What:** Add a CI job running `deno task test` in `supabase/functions/` on push/PR.
- **Why:** D16 ships a local `deno task test` runner, but nothing runs it automatically; regressions surface only at deploy time.
- **Pros:** Makes the test suite load-bearing; catches webhook/auth/amount regressions early.
- **Cons:** Net-new CI surface inside a 2-week validation box; Flutter tests stay local, so coverage is partial.
- **Context:** The webhook verifies HMAC + amount-vs-intent; D12 cuts two legacy auth paths. The runner command is `deno task test`.
- **Depends on / blocked by:** CT6 (tests must exist first).
- **Source:** plan-devex-review 2026-09-18 (D16).

### Webhook durability rail
- **What:** Port the full FedaPay webhook (HMAC `x-fedapay-signature`, dedup via `payment_provider_events`, callback redirect page, second FedaPay live account with its own webhook secret) on top of the verify-only rail once the probe shows >= 1 paying candidate.
- **Why:** Mobile-money confirmations are async (2–3 min); with verify-only, a grant only lands when the user returns/resumes. The webhook grants independently on `transaction.completed`.
- **Pros:** Smallest probe critical path now; the proven reference port stays documented instead of half-built; dedup is DB-enforced so there is no race.
- **Cons:** Adds HMAC, env guard, dedup table writes, a callback page, and a second FedaPay KYC/secret on the critical path — all deferred on purpose.
- **Context:** `verifyAuthenticatedPayment` (reference `payments/handlers.ts:291-327`) already fulfills on `completed` via `fetchFedaPayTransaction` (`_shared/fedapay.ts:367`), so verify-only is self-sufficient at probe scale. Webhook port reference: `code_permis_benin/supabase/functions/payments_webhook/` + `_shared/fedapay.ts`.
- **Depends on / blocked by:** demand signal from the ladder (0/3 vs 1/3); ET8 (verify-on-resume) must exist first.
- **Source:** plan-eng-review 2026-09-18 (outside voice #6 / verify-only ruling).

### CAPTCHA re-arm on anonymous sign-in
- **What:** Add hCaptcha (Supabase project-config keys + `supabase_flutter` CAPTCHA on `signInAnonymously`) if anon abuse is observed.
- **Why:** `signInAnonymously` floods bloat `auth.users`; the reference historically revoked anon RPC exposure twice. Server-side rate limiting alone bounds (not stops) abuse.
- **Pros:** Keeps the probe critical path lean (no project-config dependency); abuse is visible in rate-limit logs before anything ship-breaking happens.
- **Cons:** Requires Supabase dashboard-config keys; adds a widget and verification step on the sign-in path.
- **Context:** 4A lean ruling. Rate-limiter infra exists (`_shared/rate_limit.ts`); ET7 covers anon sign-in + rate-limit + RLS by `auth.uid()`.
- **Depends on / blocked by:** ET7; observed abuse signal.
- **Source:** plan-eng-review 2026-09-18 (lean-4A ruling).

## Ship-deferred items (feat/mock-paywall → clean-main)

### Client-side server-verification wiring (before any real-money release)
- **What:** Wire the Flutter paywall to `createAuthenticatedPayment` + `verifyAuthenticatedPayment` (bearer path) and gate the "Confirmer" CTA on server-attested intent state; remove/disable the local self-attestation rail in release builds.
- **Why:** Red-team review 2026-09-18 — self-attestation (`markUserAttested` → local `has_premium_access`) plus `EntitlementService.backfill()` gives free lifetime premium in one tap. Acceptable for the mock branch; blocking for real-money.
- **Context:** `mtn_payment_screen.dart:786-842`, `one_time_purchase_service.dart:165-205,365-370,444-465`, `entitlement_service.dart:117-131`.
- **Depends on / blocked by:** this ship; a real FedaPay live account.
- **Source:** ship pre-landing review 2026-09-18 (red-team #1).

### Redeem endpoint hardening (before client consumption)
- **What:** Add server negative-path tests already added (revoked/expired/already_used → 400, gated on `status='redeemed'`). Remaining: chain anti-rotation for anonymous accounts (`is_anonymous` rejection or account-upgrade link), rate-limit keyed on anon identity + IP.
- **Why:** `requireAuthenticatedStudent` does not exclude `is_anonymous`; fresh anon identities rotate past per-user rate limits.
- **Context:** `payments/handlers.ts:668-687`, `payments/db.ts:125-136`, `payments/index.ts` GET verify has no rate limit.
- **Source:** ship pre-landing review 2026-09-18 (red-team #4, api-contract).

### Webhook HMAC-only mode + token rotation
- **What:** Accept only `x-fedapay-signature` HMAC; drop header/`?token=` static-token paths; rotate all webhook tokens; add event-timestamp/replay guard; forbid transitions out of completed/failed (terminal-state downgrade).
- **Why:** static token is a single leaked-string gateway to free premium (forge approved webhook → `fulfill_payment_intent`).
- **Context:** `payments_webhook/index.ts:50-102,337-346`, `update_payment_intent_status_if`.
- **Source:** ship pre-landing review 2026-09-18 (red-team #3, #5).

### Payment-context hardening
- **What:** Cap promos (percentage 1..99, min remaining ≥ 1 XOF) in `computePromoAmount` + DB check; early 413 on hostile bodies instead of silent `{}`→anon path; rate-limit GET verify; scope app-token verify to intents created by that token; restricted columns on `catalog_products_select_anon`.
- **Why:** 100% promo ⇒ 0 XOF free premium; oversize bodies route to confusing 401; app-token is a master key.
- **Context:** `_shared/pricing.ts:85-91`, `_shared/body_limit.ts`, `payments/index.ts:103-126`, `fedapay_flow.ts`, `20260913000003_psyco_anon_rls_hardening.sql:19-23`.
- **Source:** ship pre-landing review 2026-09-18 (red-team #6, #8, security).

### Maintainability backlog
- **What:** Wire all live premium gates to `EntitlementService.isPremium()` or delete it (paid-via-ActivationScreen user still sees "Activer" CTA on home); route or delete the orphaned `/mtn-payment` screen (only ET8 caller) and `/payment` `/subscription` routes; collapse the four inconsistent provider configs (MTN/Moov prefixes, USSD) to ApiConfig; resolve 2499 (timed subscription) vs 3000 (lifetime) price conflict and `EntitlementService.backfill` silently converting timed grants to lifetime; strip ~85% dead ApiConfig + placeholder secrets.
- **Why:** maintainability review 2026-09-18 — six legacy writers still live and conflicting; dead ET8 rail; provider mismatch (e.g. '9' in both MTN and Moov lists).
- **Source:** ship pre-landing review 2026-09-18 (maintainability).
