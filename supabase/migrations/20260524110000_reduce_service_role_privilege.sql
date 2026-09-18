-- premium_checker: read-only, user_access_grants only
do $$
begin
  if not exists (select from pg_roles where rolname = 'premium_checker') then
    create role premium_checker noinherit;
  end if;
end $$;
grant usage on schema public to premium_checker;
grant select on public.user_access_grants to premium_checker;

-- payments_processor: payment_intents CRUD + catalog query + specific RPCs
do $$
begin
  if not exists (select from pg_roles where rolname = 'payments_processor') then
    create role payments_processor noinherit;
  end if;
end $$;
grant usage on schema public to payments_processor;
grant select, insert, update on public.payment_intents to payments_processor;
grant select on public.catalog_products to payments_processor;
grant select on public.partners to payments_processor;
grant select on public.user_access_grants to payments_processor;
grant execute on function public.fulfill_payment_intent to payments_processor;
grant execute on function public.current_partner_id_for_auth_user to payments_processor;
grant execute on function public.check_rate_limit to payments_processor;

