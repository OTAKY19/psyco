-- PsycoTest+ — Clefs d'application psyco.
--   payment_scheme : schéma de deep-link utilisé par la webhook pour le
--     redirect de paiement (getAppScheme() le relit en runtime, fail-open).
--   fedapay_mode : confirmé "live" pour l'environnement d'activation legacy.
-- Les clefs existantes de la référence (minimum_build, kill_switch_enabled…)
-- restent inchangées.

insert into public.app_config (key, value) values
  ('payment_scheme', 'psyco://app/payment/callback'),
  ('fedapay_mode', 'live')
on conflict (key) do update
  set value = excluded.value;