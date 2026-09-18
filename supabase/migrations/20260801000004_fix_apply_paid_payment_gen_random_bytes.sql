-- Fix: qualify gen_random_bytes with extensions schema
-- Migration 20260707000003_device_token_binding.sql used unqualified gen_random_bytes(32)
-- which does not exist in the public search_path.
-- The correct qualified form is extensions.gen_random_bytes() (from pgcrypto).
-- This mirrors the fix applied in 20260424200000_qualify_pgcrypto_functions.sql.

drop function if exists public.apply_paid_payment(
  text, text, integer, timestamp with time zone, jsonb
);

create or replace function public.apply_paid_payment(
  p_payment_id text,
  p_device_id text,
  p_amount integer default 0,
  p_premium_until timestamptz default null::timestamptz,
  p_raw_payload jsonb default '{}'::jsonb
)
returns table(processed boolean, premium_until timestamptz, device_token text)
language plpgsql security definer
set search_path = public
as $$
declare
  v_payment_id text := nullif(btrim(p_payment_id), '');
  v_device_id text := nullif(btrim(p_device_id), '');
  v_existing_device text;
  v_row_count integer := 0;
  v_processed_once boolean := false;
  v_premium_until timestamptz;
  v_device_token text;
begin
  if v_payment_id is null then
    raise exception 'payment_id is required';
  end if;
  if v_device_id is null then
    raise exception 'device_id is required';
  end if;
  if p_premium_until is null then
    raise exception 'premium_until is required';
  end if;

  select a.device_id
  into v_existing_device
  from activations a
  where a.payment_id = v_payment_id
  limit 1;

  if v_existing_device is not null and v_existing_device <> v_device_id then
    raise exception 'payment_id already linked to another device';
  end if;

  insert into payment_events (
    payment_id, device_id, amount, status, premium_until, raw_payload
  )
  values (
    v_payment_id, v_device_id,
    coalesce(p_amount, 0), 'paid', p_premium_until,
    coalesce(p_raw_payload, '{}'::jsonb)
  )
  on conflict (payment_id) do nothing;

  get diagnostics v_row_count = row_count;
  v_processed_once := v_row_count > 0;

  -- FIX: use extensions.gen_random_bytes (pgcrypto) — unqualified form not in search_path
  v_device_token := encode(extensions.gen_random_bytes(32), 'hex');

  if v_processed_once then
    insert into activations (
      device_id, amount, premium, payment_id, status, updated_at, premium_until,
      device_token
    )
    values (
      v_device_id, coalesce(p_amount, 0), true,
      v_payment_id, 'paid', now(), p_premium_until,
      v_device_token
    )
    on conflict (device_id) do update
      set amount = excluded.amount,
          premium = excluded.premium,
          payment_id = excluded.payment_id,
          status = excluded.status,
          updated_at = excluded.updated_at,
          premium_until = excluded.premium_until,
          device_token = coalesce(excluded.device_token, activations.device_token);

    v_premium_until := p_premium_until;
  else
    select a.premium_until, a.device_token
    into v_premium_until, v_device_token
    from activations a
    where a.payment_id = v_payment_id
    limit 1;

    if v_premium_until is null then
      select e.premium_until
      into v_premium_until
      from payment_events e
      where e.payment_id = v_payment_id
      limit 1;
    end if;
  end if;

  return query
  select v_processed_once, v_premium_until, v_device_token;
end;
$$;

grant execute on function public.apply_paid_payment(
  text, text, integer, timestamp with time zone, jsonb
) to service_role;
