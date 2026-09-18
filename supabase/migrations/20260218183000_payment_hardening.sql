-- Payment hardening: idempotent processing + premium expiry support

create table if not exists payment_events (
  payment_id text primary key,
  device_id text not null,
  partner_code text,
  amount integer not null default 0,
  status text not null default 'paid',
  premium_until timestamptz,
  raw_payload jsonb not null default '{}'::jsonb,
  processed_at timestamptz not null default now()
);

create index if not exists payment_events_device_id_idx
  on payment_events(device_id);

create index if not exists payment_events_processed_at_idx
  on payment_events(processed_at desc);

create index if not exists activations_premium_until_idx
  on activations(premium_until);

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'activations'
      and column_name = 'updated_at'
      and data_type = 'timestamp without time zone'
  ) then
    alter table activations
      alter column updated_at type timestamptz
      using updated_at at time zone 'UTC';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'activations'
      and column_name = 'premium_until'
      and data_type = 'timestamp without time zone'
  ) then
    alter table activations
      alter column premium_until type timestamptz
      using premium_until at time zone 'UTC';
  end if;
end $$;

alter table if exists payment_events enable row level security;

create or replace function public.apply_paid_payment(
  p_payment_id text,
  p_device_id text,
  p_partner_code text default null,
  p_amount integer default 0,
  p_premium_until timestamptz default null,
  p_raw_payload jsonb default '{}'::jsonb
)
returns table (
  processed_once boolean,
  premium_until timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment_id text := nullif(btrim(p_payment_id), '');
  v_device_id text := nullif(btrim(p_device_id), '');
  v_partner_code text := nullif(btrim(p_partner_code), '');
  v_existing_device text;
  v_row_count integer := 0;
  v_processed_once boolean := false;
  v_premium_until timestamptz;
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
    payment_id,
    device_id,
    partner_code,
    amount,
    status,
    premium_until,
    raw_payload
  )
  values (
    v_payment_id,
    v_device_id,
    v_partner_code,
    coalesce(p_amount, 0),
    'paid',
    p_premium_until,
    coalesce(p_raw_payload, '{}'::jsonb)
  )
  on conflict (payment_id) do nothing;

  get diagnostics v_row_count = row_count;
  v_processed_once := v_row_count > 0;

  if v_processed_once then
    insert into activations (
      device_id,
      partner_code,
      amount,
      premium,
      payment_id,
      status,
      updated_at,
      premium_until
    )
    values (
      v_device_id,
      v_partner_code,
      coalesce(p_amount, 0),
      true,
      v_payment_id,
      'paid',
      now(),
      p_premium_until
    )
    on conflict (device_id) do update
      set partner_code = excluded.partner_code,
          amount = excluded.amount,
          premium = excluded.premium,
          payment_id = excluded.payment_id,
          status = excluded.status,
          updated_at = excluded.updated_at,
          premium_until = excluded.premium_until;

    if v_partner_code is not null then
      update partners
      set balance = coalesce(balance, 0) + greatest(
        0,
        floor(
          (coalesce(p_amount, 0)::numeric * coalesce(commission, 0)::numeric) /
            100
        )::integer
      )
      where code = v_partner_code
        and active = true;
    end if;

    v_premium_until := p_premium_until;
  else
    select a.premium_until
    into v_premium_until
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
  select v_processed_once, v_premium_until;
end;
$$;

revoke all on function public.apply_paid_payment(
  text,
  text,
  text,
  integer,
  timestamptz,
  jsonb
)
from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.apply_paid_payment(
      text,
      text,
      text,
      integer,
      timestamptz,
      jsonb
    ) to service_role;
  end if;
end $$;

