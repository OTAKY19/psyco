-- PsycoTest+ — Redemption de code liée à un utilisateur (POST /payments/redeem).
-- RPC v2 : remplace l'ancien flux device-based par un flux JWT :
--   redeem_activation_code_for_user(p_code, p_auth_user_id)
-- L'accès octroyé est "à vie" (premium_until NULL) sur le SKU premium_lifetime.
-- Idempotent : un code déjà utilisé pour le même utilisateur ressort le grant existant.

-- user_access_grants.payment_intent_id doit devenir nullable : un grant de
-- redemption n'a pas d'intent de paiement associé.
alter table if exists public.user_access_grants
  alter column payment_intent_id drop not null;

alter table if exists public.user_access_grants
  add column if not exists activation_code_id uuid
  references public.activation_codes(id) on delete set null;

create unique index if not exists user_access_grants_activation_code_key
  on public.user_access_grants (activation_code_id)
  where activation_code_id is not null;

create or replace function public.redeem_activation_code_for_user(
  p_code text,
  p_auth_user_id uuid
)
returns table (
  activation_code_id uuid,
  product_sku text,
  status text,
  premium_until timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := public.normalize_activation_code(p_code);
  v_row activation_codes%rowtype;
  v_product_id uuid;
  v_grant_id uuid;
  v_premium_until timestamptz;
begin
  if v_code is null then
    raise exception 'code is required';
  end if;
  if p_auth_user_id is null then
    raise exception 'auth_user_id is required';
  end if;

  select *
  into v_row
  from activation_codes
  where normalize_activation_code(code) = v_code
  for update;

  if v_row.id is null then
    return query select null::uuid, v_code, 'not_found', null::timestamptz;
    return;
  end if;

  if v_row.status = 'revoked' then
    return query select v_row.id, 'premium_lifetime', 'revoked', null::timestamptz;
    return;
  end if;

  if v_row.status = 'expired' or (v_row.expires_at is not null and v_row.expires_at <= now()) then
    update activation_codes
    set status = 'expired'
    where id = v_row.id;
    return query select v_row.id, 'premium_lifetime', 'expired', null::timestamptz;
    return;
  end if;

  -- Code déjà utilisé : idempotence pour le MÊME utilisateur uniquement.
  -- Un autre utilisateur verra 'already_used' (aucun grant divulgué).
  if v_row.status = 'redeemed' then
    select g.id, g.ends_at
    into v_grant_id, v_premium_until
    from user_access_grants g
    where g.activation_code_id = v_row.id
      and g.auth_user_id = p_auth_user_id
    limit 1;

    if v_grant_id is null then
      return query select v_row.id, 'premium_lifetime', 'already_used', null::timestamptz;
      return;
    end if;

    return query select v_row.id, 'premium_lifetime', 'redeemed', v_premium_until;
    return;
  end if;

  -- psyco : tous les codes octroient le SKU "Accès à vie".
  select id
  into v_product_id
  from catalog_products
  where sku = 'premium_lifetime'
    and is_active = true
  limit 1;

  if v_product_id is null then
    raise exception 'catalog product premium_lifetime is not available';
  end if;

  update activation_codes
  set
    status = 'redeemed',
    premium_until = null,
    redeemed_at = now(),
    updated_at = now()
  where id = v_row.id;

  insert into activation_code_redemptions (
    activation_code_id,
    batch_id,
    partner_id,
    code,
    device_id,
    student_email,
    status
  )
  values (
    v_row.id,
    v_row.batch_id,
    v_row.partner_id,
    v_row.code,
    p_auth_user_id::text,
    null,
    'redeemed'
  );

  update activation_code_batches
  set redeemed_count = coalesce(redeemed_count, 0) + 1
  where id = v_row.batch_id;

  v_premium_until := null;

  insert into user_access_grants (
    auth_user_id,
    payment_intent_id,
    product_id,
    status,
    starts_at,
    ends_at,
    granted_at,
    activation_code_id,
    environment
  )
  values (
    p_auth_user_id,
    null,
    v_product_id,
    'active',
    now(),
    v_premium_until,
    now(),
    v_row.id,
    v_row.environment
  )
  on conflict (activation_code_id) where activation_code_id is not null
  do update
    set
      status = 'active',
      ends_at = excluded.ends_at,
      granted_at = now()
  returning id into v_grant_id;

  return query
  select v_row.id, 'premium_lifetime', 'redeemed', v_premium_until;
end;
$$;

revoke all on function public.redeem_activation_code_for_user(text, uuid)
  from public, anon, authenticated;

grant execute on function public.redeem_activation_code_for_user(text, uuid)
  to service_role;
grant execute on function public.redeem_activation_code_for_user(text, uuid)
  to payments_processor;