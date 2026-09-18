-- Device token binding: add server-issued token to activations for phase 2
-- Phase 1: column + generation; Phase 2: client presents token in check_premium

alter table activations
  add column if not exists device_token text;

create index if not exists activations_device_token_idx
  on activations (device_token);

-- Backfill existing activations with a device token
update activations
set device_token = encode(gen_random_bytes(32), 'hex')
where device_token is null;

-- Add device_token generation to apply_paid_payment
-- Only re-create if the function signature or body needs to change.
-- The existing function already handles the INSERT/UPDATE on activations;
-- we just need to add the device_token column set.

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

  v_device_token := encode(gen_random_bytes(32), 'hex');

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

-- verify
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'activations'
      and column_name = 'device_token'
  ) then
    raise exception 'device_token column was not created';
  end if;
end $$;
