# Changelog

## [1.1.0] - 2026-09-18

### Summary
Mock Paywall feature branch (ET1-ET10): ports the FedaPay payment rail
to Supabase Edge Functions, adds one-time 3000 FCFA lifetime purchase
with client-side resume verification, activation-code redemption RPC,
and a test/instrumentation scaffold.

### Features
- **ET1** — Supabase Edge Functions rail: `payments`, `payments_webhook`, `config`
  endpoints with FedaPay integration, anonymous & authenticated payment intents.
- **ET2** — `EntitlementService` superset: single source-of-truth premium
  aggregation across all legacy writers.
- **ET3** — Activation-code redemption RPC (`redeem_activation_code_for_user`)
  with JWT-scoped idempotence, rate-limiting (10/60), and grant by auth user.
- **ET4** — `ExamConfig` 25-question / 25-minute configuration.
- **ET5** — `apply_paid_payment` RPC lifetime support: `premium_until NULL`
  → 36500 days (100 years).
- **ET6** — Catalog-driven pricing (`catalog_products`), promo support.
- **ET7** — Anonymous sign-in via Supabase `signInAnonymously`, RLS by
  `auth.uid()`, anon rate-limit.
- **ET8** — Verify-on-resume (ET8): `WidgetsBindingObserver` resume hook,
  short-poll confirmation, CTA re-attach on app death.
- **ET9** — Test scaffold: removed legacy USSD tests, added entitlement OR
  matrix + results CTA test + `ExamConfig` tests + coverage gate (80%).
- **ET10** — Canonical plan refs and review-log integration.

### Bug Fixes (in this branch)
- **CRITICAL** — `redeemActivationCode` now returns 400 (not `premium:true`)
  for `not_found`, `revoked`, `expired`, and `already_used` activation codes.
- **CRITICAL** — Activation-code idempotence branch now filters by
  `auth_user_id`; a code redeemed by user A no longer leaks a grant
  to user B.
- Grant insert in `redeem_activation_code_for_user` now stamps
  `environment` (previously defaulted to `live`).

### Deferred (P1 TODOs)
- Client-side server verification wiring (before real-money).
- Webhook HMAC-only mode + token rotation.
- `is_anonymous` rejection on paid/redeem flows.
- 100% promo → 0 XOF safety cap.
- Body-size early 413 + app-token scoping.
- Legacy writer consolidation (`EntitlementService` wiring).

### Known (mock scope)
- Self-attestation is the only wired paywall rail; no client transport
  to payments Edge Functions exists yet.
- Static `PAYMENT_APP_TOKEN` in environment; no rotation.
- Deprecated `?token=` webhook auth still accepted alongside HMAC.
