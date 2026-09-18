-- Partner onboarding + partner code generation + partner payout counters

create extension if not exists pgcrypto;

create table if not exists partners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null,
  phone text,
  email text,
  business_name text,
  payout_phone text,
  commission integer not null default 10,
  balance integer not null default 0,
  total_referrals integer not null default 0,
  total_earnings integer not null default 0,
  status text not null default 'active',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists partners
  add column if not exists business_name text,
  add column if not exists payout_phone text,
  add column if not exists total_referrals integer not null default 0,
  add column if not exists total_earnings integer not null default 0,
  add column if not exists status text not null default 'active',
  add column if not exists updated_at timestamptz not null default now();

create index if not exists partners_code_idx
  on partners ((upper(code)));

create index if not exists partners_active_idx
  on partners (active);

create table if not exists partner_applications (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid references partners(id) on delete set null,
  full_name text not null,
  phone text not null,
  email text,
  business_name text,
  payout_phone text,
  source text not null default 'mobile_app',
  status text not null default 'approved',
  generated_code text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists partner_applications_partner_id_idx
  on partner_applications(partner_id);

create index if not exists partner_applications_phone_idx
  on partner_applications(phone);

alter table if exists partner_applications enable row level security;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'partners_set_updated_at'
  ) then
    create trigger partners_set_updated_at
    before update on partners
    for each row
    execute function public.set_updated_at();
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgname = 'partner_applications_set_updated_at'
  ) then
    create trigger partner_applications_set_updated_at
    before update on partner_applications
    for each row
    execute function public.set_updated_at();
  end if;
end $$;

create or replace function public.normalize_partner_code(p_code text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(upper(coalesce(p_code, '')), '[^A-Z0-9]', '', 'g'), '');
$$;

do $$
begin
  if not exists (
    select 1
    from (
      select public.normalize_partner_code(code) as normalized_code
      from partners
      where code is not null
      group by 1
      having count(*) > 1
    ) duplicates
  ) then
    create unique index if not exists partners_code_normalized_key
      on partners ((public.normalize_partner_code(code)));
  end if;
end $$;

create or replace function public.generate_partner_code(p_name text default null)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_letters text := regexp_replace(upper(coalesce(p_name, '')), '[^A-Z]', '', 'g');
  v_prefix text;
  v_code text;
  i integer;
begin
  v_prefix := substr(v_letters, 1, 3);
  if v_prefix is null or length(v_prefix) < 3 then
    v_prefix := 'CPB';
  end if;

  for i in 1..100 loop
    v_code := v_prefix ||
      lpad((floor(random() * 1000))::int::text, 3, '0') ||
      upper(substr(encode(gen_random_bytes(3), 'hex'), 1, 4));

    if not exists (
      select 1
      from partners
      where public.normalize_partner_code(code) = public.normalize_partner_code(v_code)
    ) then
      return v_code;
    end if;
  end loop;

  raise exception 'unable to generate unique partner code';
end;
$$;

create or replace function public.register_partner(
  p_name text,
  p_phone text,
  p_email text default null,
  p_business_name text default null,
  p_payout_phone text default null,
  p_source text default 'mobile_app',
  p_metadata jsonb default '{}'::jsonb
)
returns table (
  partner_id uuid,
  partner_code text,
  partner_name text,
  commission integer,
  active boolean,
  status text,
  is_new boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := nullif(btrim(p_name), '');
  v_phone text := nullif(regexp_replace(coalesce(p_phone, ''), '\D+', '', 'g'), '');
  v_email text := nullif(lower(btrim(coalesce(p_email, ''))), '');
  v_business_name text := nullif(btrim(p_business_name), '');
  v_payout_phone text := nullif(regexp_replace(coalesce(p_payout_phone, ''), '\D+', '', 'g'), '');
  v_source text := coalesce(nullif(btrim(p_source), ''), 'mobile_app');
  v_partner partners%rowtype;
  v_new_code text;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_name is null then
    raise exception 'name is required';
  end if;

  if v_phone is null or length(v_phone) < 8 or length(v_phone) > 15 then
    raise exception 'phone must contain 8 to 15 digits';
  end if;

  if v_email is not null and v_email !~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$' then
    raise exception 'invalid email';
  end if;

  select p.*
  into v_partner
  from partners p
  where
    (p.phone is not null and p.phone = v_phone)
    or (
      v_email is not null and p.email is not null and lower(p.email) = v_email
    )
  order by p.created_at asc
  limit 1;

  if v_partner.id is not null then
    update partners
    set
      name = coalesce(v_partner.name, v_name),
      email = coalesce(v_partner.email, v_email),
      business_name = coalesce(v_partner.business_name, v_business_name),
      payout_phone = coalesce(v_partner.payout_phone, v_payout_phone),
      active = true,
      status = coalesce(nullif(v_partner.status, ''), 'active')
    where id = v_partner.id
    returning * into v_partner;

    insert into partner_applications (
      partner_id,
      full_name,
      phone,
      email,
      business_name,
      payout_phone,
      source,
      status,
      generated_code,
      metadata
    )
    values (
      v_partner.id,
      v_name,
      v_phone,
      v_email,
      v_business_name,
      v_payout_phone,
      v_source,
      'approved',
      v_partner.code,
      v_metadata
    );

    return query
    select
      v_partner.id,
      upper(v_partner.code),
      v_partner.name,
      coalesce(v_partner.commission, 10),
      coalesce(v_partner.active, true),
      coalesce(nullif(v_partner.status, ''), 'active'),
      false;
    return;
  end if;

  v_new_code := public.generate_partner_code(v_name);

  insert into partners (
    name,
    code,
    phone,
    email,
    business_name,
    payout_phone,
    commission,
    balance,
    total_referrals,
    total_earnings,
    status,
    active
  )
  values (
    v_name,
    upper(v_new_code),
    v_phone,
    v_email,
    v_business_name,
    v_payout_phone,
    10,
    0,
    0,
    0,
    'active',
    true
  )
  returning * into v_partner;

  insert into partner_applications (
    partner_id,
    full_name,
    phone,
    email,
    business_name,
    payout_phone,
    source,
    status,
    generated_code,
    metadata
  )
  values (
    v_partner.id,
    v_name,
    v_phone,
    v_email,
    v_business_name,
    v_payout_phone,
    v_source,
    'approved',
    v_partner.code,
    v_metadata
  );

  return query
  select
    v_partner.id,
    upper(v_partner.code),
    v_partner.name,
    coalesce(v_partner.commission, 10),
    coalesce(v_partner.active, true),
    coalesce(nullif(v_partner.status, ''), 'active'),
    true;
end;
$$;

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
  v_partner_code text := public.normalize_partner_code(p_partner_code);
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
      set
        balance = coalesce(balance, 0) + greatest(
          0,
          floor(
            (coalesce(p_amount, 0)::numeric * coalesce(commission, 0)::numeric) /
              100
          )::integer
        ),
        total_earnings = coalesce(total_earnings, 0) + greatest(
          0,
          floor(
            (coalesce(p_amount, 0)::numeric * coalesce(commission, 0)::numeric) /
              100
          )::integer
        ),
        total_referrals = coalesce(total_referrals, 0) + 1
      where public.normalize_partner_code(code) = v_partner_code
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

revoke all on function public.register_partner(
  text,
  text,
  text,
  text,
  text,
  text,
  jsonb
)
from public;

revoke all on function public.generate_partner_code(text)
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

    grant execute on function public.register_partner(
      text,
      text,
      text,
      text,
      text,
      text,
      jsonb
    ) to service_role;

    grant execute on function public.generate_partner_code(text)
      to service_role;
  end if;
end $$;

