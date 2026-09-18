alter table if exists public.payment_intents
  add column if not exists device_id text;

create index if not exists payment_intents_device_id_idx
  on public.payment_intents(device_id);

create or replace function public.link_activation_to_user(
  p_auth_user_id uuid,
  p_device_id text
)
returns table (
  linked boolean,
  premium_until timestamptz,
  grant_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_activation record;
  v_grant_id uuid;
begin
  if p_auth_user_id is null then
    raise exception 'auth_user_id is required';
  end if;
  if p_device_id is null or btrim(p_device_id) = '' then
    raise exception 'device_id is required';
  end if;

  select a.premium_until, a.payment_id, a.amount
  into v_activation
  from public.activations a
  where a.device_id = btrim(p_device_id)
    and a.premium = true
    and a.status = 'paid'
    and (a.premium_until > now())
  order by a.premium_until desc
  limit 1;

  if v_activation is null then
    return query select false::boolean, null::timestamptz, null::uuid;
    return;
  end if;

  if exists (
    select 1 from public.user_access_grants g
    where g.auth_user_id = p_auth_user_id
      and g.ends_at > now()
      and g.status = 'active'
  ) then
    return query select false::boolean, null::timestamptz, null::uuid;
    return;
  end if;

  insert into public.payment_intents (
    auth_user_id,
    device_id,
    product_id,
    provider,
    client_nonce,
    amount_xof,
    currency,
    status,
    fulfillment_status,
    paid_at
  )
  select
    p_auth_user_id,
    btrim(p_device_id),
    cp.id,
    'mtn',
    gen_random_uuid(),
    coalesce(v_activation.amount, 5000),
    'XOF',
    'completed',
    'fulfilled',
    now()
  from public.catalog_products cp
  where cp.sku = 'premium_90d'
    and cp.is_active = true
  limit 1
  on conflict do nothing;

  insert into public.user_access_grants (
    auth_user_id,
    payment_intent_id,
    product_id,
    status,
    starts_at,
    ends_at,
    granted_at
  )
  select
    p_auth_user_id,
    pi.id,
    pi.product_id,
    'active',
    now(),
    v_activation.premium_until,
    now()
  from public.payment_intents pi
  where pi.auth_user_id = p_auth_user_id
    and pi.fulfillment_status = 'fulfilled'
  order by pi.created_at desc
  limit 1
  returning id into v_grant_id;

  if not found then
    insert into public.user_access_grants (
      auth_user_id,
      product_id,
      status,
      starts_at,
      ends_at,
      granted_at
    )
    values (
      p_auth_user_id,
      (select id from public.catalog_products where sku = 'premium_90d' limit 1),
      'active',
      now(),
      v_activation.premium_until,
      now()
    )
    returning id into v_grant_id;
  end if;

  return query select true::boolean, v_activation.premium_until, v_grant_id;
end;
$$;

grant execute on function public.link_activation_to_user(uuid, text) to service_role;
