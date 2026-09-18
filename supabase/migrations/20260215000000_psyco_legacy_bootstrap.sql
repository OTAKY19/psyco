-- PsycoTest+ — Bootstrap legacy.
-- PsychoTest+ est une application mobile avec paiement unique "Accès à vie" (3000 FCFA).
-- Cette migration de base recrée UNIQUEMENT la table legacy la plus structurante :
--   activations (liens device_id -> paiement premium).
-- La table DOIT exister avant 20260218183000_payment_hardening.sql qui indexe
--   activations(premium_until) dès le premier appel.
-- Toutes les autres tables/collègues (partners, activation_codes, catalog_products,
--   payment_intents, user_access_grants, etc.) sont créées par leurs propres migrations
--   copiées depuis la référence code_permis_benin.

create table if not exists public.activations (
  device_id text primary key,
  partner_code text,
  amount integer not null default 0,
  premium boolean not null default false,
  payment_id text,
  status text not null default 'paid',
  updated_at timestamptz not null default now(),
  premium_until timestamptz,
  device_token text
);

-- comfort index, aligné sur la référence (recréé idempotente par payment_hardening)
create index if not exists activations_device_id_idx
  on public.activations (device_id);