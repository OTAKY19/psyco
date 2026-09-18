-- PsycoTest+ — Lecture publique minimale + verrouillage RPC.
-- 1) RLS : le parcours de paiement anonyme JWT lit catalog_products et les
--    promotions SANS session utilisateur. Les select policies existantes sont
--    restreintes à `authenticated` (et `payments_processor` => partir de la
--    clé anon). On ajoute des policies SELECT pour le rôle `anon`.
--    (app_config et promotion_skus ont déjà leur policy de lecture publique.)
-- 2) Durcissement : les fonctions SECURITY DEFINER sensibles sont verrouillées
--    (règle P0) — REVOKE FROM PUBLIC puis grants explicites.

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'catalog_products'
      and policyname = 'catalog_products_select_anon'
  ) then
    create policy catalog_products_select_anon
      on public.catalog_products
      for select
      to anon
      using (is_active = true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'promotions'
      and policyname = 'promotions_select_anon'
  ) then
    create policy promotions_select_anon
      on public.promotions
      for select
      to anon
      using (is_active = true);
  end if;
end $$;

-- Verrouillage de l'ancienne RPC de redemption (device-based) :
-- plus jamais exposée à PUBLIC / anon / authenticated.
revoke all on function public.redeem_activation_code(text, text, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.redeem_activation_code(text, text, text, jsonb)
  to service_role;