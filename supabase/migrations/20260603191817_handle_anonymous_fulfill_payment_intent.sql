-- Skip user_access_grants insert when auth_user_id is NULL (anonymous payment)
-- The anonymous premium is handled by apply_paid_payment RPC -> activations table
create or replace function public.fulfill_payment_intent(
  p_payment_intent_id uuid
)
returns table (
  payment_intent_id uuid,
  product_kind text,
  premium_until timestamptz,
  batch_id uuid,
  grant_id uuid,
  fulfillment_status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_intent public.payment_intents%rowtype;
  v_product public.catalog_products%rowtype;
  v_grant public.user_access_grants%rowtype;
  v_batch public.activation_code_batches%rowtype;
  v_unit_price integer;
  v_premium_until timestamptz;
begin
  if p_payment_intent_id is null then
    raise exception 'payment_intent_id is required';
  end if;

  select *
  into v_intent
  from public.payment_intents
  where id = p_payment_intent_id
  for update;

  if v_intent.id is null then
    raise exception 'payment intent not found';
  end if;

  if lower(coalesce(v_intent.status, '')) not in ('approved', 'completed') then
    raise exception 'payment intent is not paid';
  end if;

  select *
  into v_product
  from public.catalog_products
  where id = v_intent.product_id;

  if v_product.id is null then
    raise exception 'catalog product not found';
  end if;

  select *
  into v_grant
  from public.user_access_grants
  where user_access_grants.payment_intent_id = v_intent.id
  limit 1;

  select *
  into v_batch
  from public.activation_code_batches
  where activation_code_batches.payment_intent_id = v_intent.id
  limit 1;

  if lower(coalesce(v_intent.fulfillment_status, '')) = 'fulfilled' then
    return query
    select
      v_intent.id,
      v_product.kind,
      v_grant.ends_at,
      v_batch.id,
      v_grant.id,
      'fulfilled';
    return;
  end if;

  if v_product.kind = 'license_access' then
    if v_grant.id is null then
      v_premium_until := coalesce(v_intent.paid_at, now()) +
        make_interval(days => v_product.premium_duration_days);

      if v_intent.auth_user_id is not null then
        insert into public.user_access_grants (
          auth_user_id,
          payment_intent_id,
          product_id,
          status,
          starts_at,
          ends_at,
          granted_at
        )
        values (
          v_intent.auth_user_id,
          v_intent.id,
          v_product.id,
          'active',
          coalesce(v_intent.paid_at, now()),
          v_premium_until,
          now()
        )
        on conflict on constraint user_access_grants_payment_intent_id_key do update
        set
          status = 'active',
          starts_at = excluded.starts_at,
          ends_at = excluded.ends_at,
          granted_at = excluded.granted_at
        returning * into v_grant;
      end if;
    end if;
  elsif v_product.kind = 'activation_pack' then
    if v_intent.partner_id is null then
      raise exception 'partner_id is required for activation pack fulfillment';
    end if;

    if v_batch.id is null then
      v_unit_price := greatest(
        0,
        floor(
          v_product.amount_xof::numeric /
          greatest(v_product.activation_code_quantity, 1)::numeric
        )::integer
      );

      insert into public.activation_code_batches (
        partner_id,
        package_name,
        quantity,
        unit_price,
        total_price,
        premium_duration_days,
        status,
        payment_status,
        payment_verified_at,
        paid_at,
        code_prefix,
        payment_intent_id
      )
      values (
        v_intent.partner_id,
        coalesce(nullif(v_product.package_name, ''), v_product.name),
        v_product.activation_code_quantity,
        v_unit_price,
        v_product.amount_xof,
        v_product.premium_duration_days,
        'paid',
        'paid',
        coalesce(v_intent.paid_at, now()),
        coalesce(v_intent.paid_at, now()),
        coalesce(nullif(v_product.code_prefix, ''), 'CPB'),
        v_intent.id
      )
      returning * into v_batch;
    end if;

    perform public.generate_activation_codes(v_batch.id);
  else
    raise exception 'unsupported catalog product kind';
  end if;

  update public.payment_intents
  set
    fulfillment_status = 'fulfilled',
    fulfilled_at = now(),
    updated_at = now()
  where id = v_intent.id;

  if v_grant.id is not null then
    v_premium_until := v_grant.ends_at;
  else
    v_premium_until := null;
  end if;

  return query
  select
    v_intent.id,
    v_product.kind,
    v_premium_until,
    v_batch.id,
    v_grant.id,
    'fulfilled';
end;
$$;

revoke all on function public.fulfill_payment_intent(uuid) from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.fulfill_payment_intent(uuid) to service_role;
  end if;
end $$;
