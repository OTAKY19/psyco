-- Activation codes for partner packs and student redemption

create extension if not exists pgcrypto;

create table if not exists activation_code_batches (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references partners(id) on delete cascade,
  package_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price integer not null default 0,
  total_price integer not null default 0,
  premium_duration_days integer not null default 30 check (premium_duration_days > 0),
  status text not null default 'draft',
  code_prefix text,
  generated_count integer not null default 0,
  redeemed_count integer not null default 0,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists activation_codes (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references activation_code_batches(id) on delete cascade,
  partner_id uuid not null references partners(id) on delete cascade,
  code text not null,
  status text not null default 'available',
  premium_duration_days integer not null default 30,
  premium_until timestamptz,
  redeemed_by_device_id text,
  redeemed_by_email text,
  redeemed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists activation_codes_code_key
  on activation_codes (upper(code));

create index if not exists activation_codes_batch_id_idx
  on activation_codes (batch_id);

create index if not exists activation_codes_partner_id_idx
  on activation_codes (partner_id);

create index if not exists activation_codes_status_idx
  on activation_codes (status);

create table if not exists activation_code_redemptions (
  id uuid primary key default gen_random_uuid(),
  activation_code_id uuid references activation_codes(id) on delete set null,
  batch_id uuid references activation_code_batches(id) on delete set null,
  partner_id uuid references partners(id) on delete set null,
  code text not null,
  device_id text not null,
  student_email text,
  status text not null default 'redeemed',
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists activation_code_redemptions_partner_id_idx
  on activation_code_redemptions (partner_id);

create index if not exists activation_code_redemptions_device_id_idx
  on activation_code_redemptions (device_id);

create index if not exists activation_code_redemptions_code_idx
  on activation_code_redemptions (code);

alter table if exists activation_code_batches enable row level security;
alter table if exists activation_codes enable row level security;
alter table if exists activation_code_redemptions enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'activation_code_batches_set_updated_at'
  ) then
    create trigger activation_code_batches_set_updated_at
    before update on activation_code_batches
    for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'activation_codes_set_updated_at'
  ) then
    create trigger activation_codes_set_updated_at
    before update on activation_codes
    for each row execute function public.set_updated_at();
  end if;
end $$;

create or replace function public.normalize_activation_code(p_code text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(upper(coalesce(p_code, '')), '[^A-Z0-9]', '', 'g'), '');
$$;

create or replace function public.list_partner_activation_codes(
  p_partner_id uuid,
  p_batch_id uuid default null,
  p_status text default null,
  p_limit integer default 100
)
returns table (
  id uuid,
  batch_id uuid,
  code text,
  status text,
  premium_duration_days integer,
  expires_at timestamptz,
  redeemed_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    c.id,
    c.batch_id,
    c.code,
    c.status,
    c.premium_duration_days,
    c.expires_at,
    c.redeemed_at,
    c.created_at
  from activation_codes c
  where c.partner_id = p_partner_id
    and (p_batch_id is null or c.batch_id = p_batch_id)
    and (
      p_status is null
      or p_status = ''
      or lower(c.status) = lower(p_status)
    )
  order by c.created_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 500));
$$;

create or replace function public.generate_activation_code(p_prefix text default null)
returns text
language plpgsql
immutable
as $$
declare
  v_letters text := regexp_replace(upper(coalesce(p_prefix, '')), '[^A-Z]', '', 'g');
  v_prefix text;
begin
  v_prefix := substr(v_letters, 1, 4);
  if v_prefix is null or length(v_prefix) < 3 then
    v_prefix := 'CPB';
  end if;

  return v_prefix || '-' ||
    upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 8)) || '-' ||
    upper(substr(encode(gen_random_bytes(2), 'hex'), 1, 4));
end;
$$;

create or replace function public.create_activation_batch(
  p_partner_id uuid,
  p_package_name text,
  p_quantity integer,
  p_unit_price integer default 0,
  p_premium_duration_days integer default 30,
  p_code_prefix text default null
)
returns table (
  batch_id uuid,
  package_name text,
  quantity integer,
  unit_price integer,
  total_price integer,
  premium_duration_days integer,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch activation_code_batches%rowtype;
begin
  if p_partner_id is null then
    raise exception 'partner_id is required';
  end if;
  if nullif(btrim(p_package_name), '') is null then
    raise exception 'package_name is required';
  end if;
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'quantity must be positive';
  end if;

  insert into activation_code_batches (
    partner_id,
    package_name,
    quantity,
    unit_price,
    total_price,
    premium_duration_days,
    status,
    code_prefix
  )
  values (
    p_partner_id,
    btrim(p_package_name),
    p_quantity,
    greatest(0, coalesce(p_unit_price, 0)),
    greatest(0, coalesce(p_unit_price, 0)) * p_quantity,
    greatest(1, coalesce(p_premium_duration_days, 30)),
    'draft',
    nullif(btrim(p_code_prefix), '')
  )
  returning * into v_batch;

  return query
  select
    v_batch.id,
    v_batch.package_name,
    v_batch.quantity,
    v_batch.unit_price,
    v_batch.total_price,
    v_batch.premium_duration_days,
    v_batch.status;
end;
$$;

create or replace function public.generate_activation_codes(
  p_batch_id uuid
)
returns table (
  activation_code_id uuid,
  code text,
  status text,
  premium_duration_days integer,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch activation_code_batches%rowtype;
  v_partner_code text;
  v_existing_count integer;
  v_target_count integer;
  v_code text;
  v_generated_count integer := 0;
  v_expiry timestamptz;
begin
  select *
  into v_batch
  from activation_code_batches
  where id = p_batch_id
  for update;

  if v_batch.id is null then
    raise exception 'batch not found';
  end if;

  v_target_count := v_batch.quantity;
  v_existing_count := coalesce(v_batch.generated_count, 0);

  if v_existing_count >= v_target_count then
    update activation_code_batches
    set status = 'generated'
    where id = v_batch.id;

    return;
  end if;

  select code into v_partner_code
  from partners
  where id = v_batch.partner_id
  limit 1;

  v_expiry := now() + make_interval(days => v_batch.premium_duration_days);

  while v_existing_count + v_generated_count < v_target_count loop
    v_code := public.generate_activation_code(
      coalesce(v_batch.code_prefix, v_partner_code)
    );

    begin
      insert into activation_codes (
        batch_id,
        partner_id,
        code,
        status,
        premium_duration_days,
        expires_at
      )
      values (
        v_batch.id,
        v_batch.partner_id,
        public.normalize_activation_code(v_code),
        'available',
        v_batch.premium_duration_days,
        v_expiry
      )
      returning id, code, status, premium_duration_days, expires_at
      into activation_code_id, code, status, premium_duration_days, expires_at;

      v_generated_count := v_generated_count + 1;
      return next;
    exception
      when unique_violation then
        continue;
    end;
  end loop;

  update activation_code_batches
  set
    generated_count = v_target_count,
    status = 'generated'
  where id = v_batch.id;
end;
$$;

create or replace function public.redeem_activation_code(
  p_code text,
  p_device_id text,
  p_student_email text default null,
  p_raw_payload jsonb default '{}'::jsonb
)
returns table (
  success boolean,
  status text,
  premium_until timestamptz,
  code text,
  batch_id uuid,
  partner_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := public.normalize_activation_code(p_code);
  v_device_id text := nullif(btrim(p_device_id), '');
  v_email text := nullif(lower(btrim(coalesce(p_student_email, ''))), '');
  v_row activation_codes%rowtype;
  v_partner_code text;
  v_premium_until timestamptz;
begin
  if v_code is null then
    raise exception 'code is required';
  end if;
  if v_device_id is null then
    raise exception 'device_id is required';
  end if;

  select *
  into v_row
  from activation_codes
  where normalize_activation_code(code) = v_code
  for update;

  if v_row.id is null then
    return query select false, 'not_found', null::timestamptz, v_code, null::uuid, null::uuid;
    return;
  end if;

  if v_row.status = 'revoked' then
    return query select false, 'revoked', v_row.premium_until, v_row.code, v_row.batch_id, v_row.partner_id;
    return;
  end if;

  if v_row.status = 'expired' or (v_row.expires_at is not null and v_row.expires_at <= now()) then
    update activation_codes
    set status = 'expired'
    where id = v_row.id;

    return query select false, 'expired', v_row.premium_until, v_row.code, v_row.batch_id, v_row.partner_id;
    return;
  end if;

  if v_row.status = 'redeemed' then
    if v_row.redeemed_by_device_id = v_device_id then
      return query
      select true, 'redeemed', v_row.premium_until, v_row.code, v_row.batch_id, v_row.partner_id;
      return;
    end if;

    raise exception 'code already redeemed';
  end if;

  select code
  into v_partner_code
  from partners
  where id = v_row.partner_id
  limit 1;

  v_premium_until := now() + make_interval(days => v_row.premium_duration_days);

  update activation_codes
  set
    status = 'redeemed',
    premium_until = v_premium_until,
    redeemed_by_device_id = v_device_id,
    redeemed_by_email = v_email,
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
    status,
    raw_payload
  )
  values (
    v_row.id,
    v_row.batch_id,
    v_row.partner_id,
    v_row.code,
    v_device_id,
    v_email,
    'redeemed',
    coalesce(p_raw_payload, '{}'::jsonb)
  );

  update activation_code_batches
  set redeemed_count = coalesce(redeemed_count, 0) + 1
  where id = v_row.batch_id;

  if v_partner_code is not null then
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
      0,
      true,
      'activation_code:' || v_row.code,
      'code_redeemed',
      now(),
      v_premium_until
    )
    on conflict (device_id) do update
      set partner_code = excluded.partner_code,
          amount = excluded.amount,
          premium = excluded.premium,
          payment_id = excluded.payment_id,
          status = excluded.status,
          updated_at = excluded.updated_at,
          premium_until = excluded.premium_until;
  end if;

  return query
  select true, 'redeemed', v_premium_until, v_row.code, v_row.batch_id, v_row.partner_id;
end;
$$;

create or replace function public.get_partner_activation_summary(
  p_partner_id uuid
)
returns table (
  total_batches integer,
  total_codes integer,
  available_codes integer,
  redeemed_codes integer,
  expired_codes integer,
  revoked_codes integer
)
language sql
security definer
set search_path = public
as $$
  select
    coalesce(count(distinct b.id), 0)::integer as total_batches,
    coalesce(count(distinct c.id), 0)::integer as total_codes,
    coalesce(count(distinct c.id) filter (where c.status = 'available'), 0)::integer as available_codes,
    coalesce(count(distinct c.id) filter (where c.status = 'redeemed'), 0)::integer as redeemed_codes,
    coalesce(count(distinct c.id) filter (where c.status = 'expired'), 0)::integer as expired_codes,
    coalesce(count(distinct c.id) filter (where c.status = 'revoked'), 0)::integer as revoked_codes
  from partners p
  left join activation_code_batches b on b.partner_id = p.id
  left join activation_codes c on c.partner_id = p.id
  where p.id = p_partner_id
  group by p.id;
$$;

