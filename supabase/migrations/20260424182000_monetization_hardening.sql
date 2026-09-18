-- Monetization hardening: partner onboarding fields, batch payment linkage,
-- explicit deny-by-default RLS policies, and safe idempotent RPCs.

create extension if not exists pgcrypto;

alter table if exists partners
  add column if not exists school_name text,
  add column if not exists license_number text,
  add column if not exists city text,
  add column if not exists address text,
  add column if not exists manager_name text,
  add column if not exists estimated_students text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by text,
  add column if not exists review_source text,
  add column if not exists review_reason text;

alter table if exists partner_applications
  add column if not exists school_name text,
  add column if not exists license_number text,
  add column if not exists city text,
  add column if not exists address text,
  add column if not exists manager_name text,
  add column if not exists estimated_students text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists review_source text,
  add column if not exists review_reason text,
  add column if not exists request_fingerprint text;

alter table if exists activation_code_batches
  add column if not exists payment_id text,
  add column if not exists payment_status text,
  add column if not exists payment_verified_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'activation_code_batches_payment_id_fkey'
  ) then
    alter table activation_code_batches
      add constraint activation_code_batches_payment_id_fkey
      foreign key (payment_id)
      references payment_events(payment_id)
      on delete set null;
  end if;
end $$;

alter table if exists activations
  add column if not exists payment_id text;

create unique index if not exists activation_code_batches_payment_id_key
  on activation_code_batches (payment_id)
  where payment_id is not null;

create unique index if not exists activations_payment_id_key
  on activations (payment_id)
  where payment_id is not null;

create unique index if not exists activation_code_redemptions_code_id_key
  on activation_code_redemptions (activation_code_id)
  where activation_code_id is not null;

create unique index if not exists partner_applications_request_fingerprint_key
  on partner_applications (request_fingerprint)
  where request_fingerprint is not null;

create index if not exists partner_applications_request_fingerprint_idx
  on partner_applications (request_fingerprint);

update partners
set
  status = case
    when lower(coalesce(status, '')) in ('approved', 'active') then 'approved'
    when lower(coalesce(status, '')) = 'rejected' then 'rejected'
    else 'pending'
  end,
  active = case
    when lower(coalesce(status, '')) in ('approved', 'active') then true
    else false
  end
where true;

update partner_applications
set
  status = case
    when lower(coalesce(status, '')) in ('approved', 'active') then 'approved'
    when lower(coalesce(status, '')) = 'rejected' then 'rejected'
    else 'pending'
  end
where true;

update activation_code_batches
set
  status = case
    when lower(coalesce(status, '')) in ('draft', 'paid', 'generated', 'expired', 'revoked', 'cancelled') then lower(status)
    else 'draft'
  end
where true;

update activation_codes
set
  status = case
    when lower(coalesce(status, '')) in ('available', 'redeemed', 'expired', 'revoked') then lower(status)
    else 'available'
  end
where true;

update activation_code_redemptions
set
  status = case
    when lower(coalesce(status, '')) in ('redeemed', 'expired', 'revoked', 'not_found', 'invalid') then lower(status)
    else 'redeemed'
  end
where true;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'partners_status_allowed_check'
  ) then
    alter table partners
      add constraint partners_status_allowed_check
      check (lower(status) in ('pending', 'approved', 'rejected'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'partner_applications_status_allowed_check'
  ) then
    alter table partner_applications
      add constraint partner_applications_status_allowed_check
      check (lower(status) in ('pending', 'approved', 'rejected'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'activation_code_batches_status_allowed_check'
  ) then
    alter table activation_code_batches
      add constraint activation_code_batches_status_allowed_check
      check (lower(status) in ('draft', 'paid', 'generated', 'expired', 'revoked', 'cancelled'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'activation_codes_status_allowed_check'
  ) then
    alter table activation_codes
      add constraint activation_codes_status_allowed_check
      check (lower(status) in ('available', 'redeemed', 'expired', 'revoked'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'activation_code_redemptions_status_allowed_check'
  ) then
    alter table activation_code_redemptions
      add constraint activation_code_redemptions_status_allowed_check
      check (lower(status) in ('redeemed', 'expired', 'revoked', 'not_found', 'invalid'));
  end if;
end $$;

alter table if exists partners enable row level security;
alter table if exists partner_applications enable row level security;
alter table if exists payment_events enable row level security;
alter table if exists activation_code_batches enable row level security;
alter table if exists activation_codes enable row level security;
alter table if exists activation_code_redemptions enable row level security;
alter table if exists activations enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'partners'
      and policyname = 'partners_deny_all'
  ) then
    create policy partners_deny_all
      on partners
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'partner_applications'
      and policyname = 'partner_applications_deny_all'
  ) then
    create policy partner_applications_deny_all
      on partner_applications
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'payment_events'
      and policyname = 'payment_events_deny_all'
  ) then
    create policy payment_events_deny_all
      on payment_events
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'activation_code_batches'
      and policyname = 'activation_code_batches_deny_all'
  ) then
    create policy activation_code_batches_deny_all
      on activation_code_batches
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'activation_codes'
      and policyname = 'activation_codes_deny_all'
  ) then
    create policy activation_codes_deny_all
      on activation_codes
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'activation_code_redemptions'
      and policyname = 'activation_code_redemptions_deny_all'
  ) then
    create policy activation_code_redemptions_deny_all
      on activation_code_redemptions
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'activations'
      and policyname = 'activations_deny_all'
  ) then
    create policy activations_deny_all
      on activations
      for all
      using (false)
      with check (false);
  end if;
end $$;

create or replace function public.register_partner(
  p_name text,
  p_phone text,
  p_email text default null,
  p_business_name text default null,
  p_payout_phone text default null,
  p_school_name text default null,
  p_license_number text default null,
  p_city text default null,
  p_address text default null,
  p_manager_name text default null,
  p_estimated_students text default null,
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
  v_school_name text := nullif(btrim(p_school_name), '');
  v_license_number text := nullif(btrim(p_license_number), '');
  v_city text := nullif(btrim(p_city), '');
  v_address text := nullif(btrim(p_address), '');
  v_manager_name text := nullif(btrim(p_manager_name), '');
  v_estimated_students text := nullif(btrim(p_estimated_students), '');
  v_source text := coalesce(nullif(btrim(p_source), ''), 'mobile_app');
  v_partner partners%rowtype;
  v_new_code text;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_fingerprint text;
  v_lock_key bigint;
  v_is_approved boolean := false;
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

  v_fingerprint := md5(
    concat_ws(
      '|',
      v_phone,
      coalesce(v_email, ''),
      v_name,
      coalesce(v_business_name, ''),
      coalesce(v_payout_phone, ''),
      v_source,
      coalesce(jsonb_strip_nulls(v_metadata)::text, '{}')
    )
  );

  v_lock_key := hashtextextended(
    concat_ws('|', v_phone, coalesce(v_email, ''), v_source),
    0
  );
  perform pg_advisory_xact_lock(v_lock_key);

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
    v_is_approved := lower(coalesce(v_partner.status, '')) = 'approved'
      and coalesce(v_partner.active, false);

    update partners
    set
      name = coalesce(v_partner.name, v_name),
      email = coalesce(v_partner.email, v_email),
      business_name = coalesce(v_partner.business_name, v_business_name),
      payout_phone = coalesce(v_partner.payout_phone, v_payout_phone),
      school_name = coalesce(nullif(btrim(v_partner.school_name), ''), v_school_name),
      license_number = coalesce(nullif(btrim(v_partner.license_number), ''), v_license_number),
      city = coalesce(nullif(btrim(v_partner.city), ''), v_city),
      address = coalesce(nullif(btrim(v_partner.address), ''), v_address),
      manager_name = coalesce(nullif(btrim(v_partner.manager_name), ''), v_manager_name),
      estimated_students = coalesce(nullif(btrim(v_partner.estimated_students), ''), v_estimated_students),
      active = v_is_approved,
      status = case when v_is_approved then 'approved' else 'pending' end
    where id = v_partner.id
    returning * into v_partner;

    insert into partner_applications (
      partner_id,
      full_name,
      phone,
      email,
      business_name,
      payout_phone,
      school_name,
      license_number,
      city,
      address,
      manager_name,
      estimated_students,
      source,
      status,
      generated_code,
      metadata,
      request_fingerprint
    )
    select
      v_partner.id,
      v_name,
      v_phone,
      v_email,
      v_business_name,
      v_payout_phone,
      v_school_name,
      v_license_number,
      v_city,
      v_address,
      v_manager_name,
      v_estimated_students,
      v_source,
      case when v_is_approved then 'approved' else 'pending' end,
      v_partner.code,
      v_metadata,
      v_fingerprint
    where not exists (
      select 1
      from partner_applications pa
      where pa.request_fingerprint = v_fingerprint
    );

    return query
    select
      v_partner.id,
      upper(v_partner.code),
      v_partner.name,
      coalesce(v_partner.commission, 10),
      coalesce(v_partner.active, false),
      coalesce(nullif(v_partner.status, ''), 'pending'),
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
    school_name,
    license_number,
    city,
    address,
    manager_name,
    estimated_students,
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
    v_school_name,
    v_license_number,
    v_city,
    v_address,
    v_manager_name,
    v_estimated_students,
    10,
    0,
    0,
    0,
    'pending',
    false
  )
  returning * into v_partner;

  insert into partner_applications (
    partner_id,
    full_name,
    phone,
    email,
    business_name,
    payout_phone,
    school_name,
    license_number,
    city,
    address,
    manager_name,
    estimated_students,
    source,
    status,
    generated_code,
    metadata,
    request_fingerprint
  )
  values (
    v_partner.id,
    v_name,
    v_phone,
    v_email,
    v_business_name,
    v_payout_phone,
    v_school_name,
    v_license_number,
    v_city,
    v_address,
    v_manager_name,
    v_estimated_students,
    v_source,
    'pending',
    v_partner.code,
    v_metadata,
    v_fingerprint
  );

  return query
  select
    v_partner.id,
    upper(v_partner.code),
    v_partner.name,
    coalesce(v_partner.commission, 10),
    coalesce(v_partner.active, false),
    coalesce(nullif(v_partner.status, ''), 'pending'),
    true;
end;
$$;

create or replace function public.approve_partner_registration(
  p_partner_code text,
  p_source text default 'manual_validation'
)
returns table (
  partner_id uuid,
  partner_code text,
  partner_name text,
  active boolean,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := public.normalize_partner_code(p_partner_code);
  v_partner partners%rowtype;
begin
  if v_code is null then
    raise exception 'partner_code is required';
  end if;

  select *
  into v_partner
  from partners
  where public.normalize_partner_code(code) = v_code
  limit 1;

  if v_partner.id is null then
    raise exception 'partner not found';
  end if;

  update partners
  set
    active = true,
    status = 'approved',
    reviewed_at = now(),
    reviewed_by = coalesce(nullif(btrim(p_source), ''), 'manual_validation'),
    review_source = coalesce(nullif(btrim(p_source), ''), 'manual_validation'),
    review_reason = null
  where id = v_partner.id
  returning * into v_partner;

  update partner_applications
  set
    status = 'approved',
    reviewed_at = now(),
    review_source = coalesce(nullif(btrim(p_source), ''), 'manual_validation'),
    review_reason = null
  where partner_id = v_partner.id;

  return query
  select
    v_partner.id,
    upper(v_partner.code),
    v_partner.name,
    v_partner.active,
    v_partner.status;
end;
$$;

create or replace function public.reject_partner_registration(
  p_partner_code text,
  p_reason text default null,
  p_source text default 'manual_validation'
)
returns table (
  partner_id uuid,
  partner_code text,
  partner_name text,
  active boolean,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := public.normalize_partner_code(p_partner_code);
  v_partner partners%rowtype;
  v_reason text := nullif(btrim(p_reason), '');
begin
  if v_code is null then
    raise exception 'partner_code is required';
  end if;

  select *
  into v_partner
  from partners
  where public.normalize_partner_code(code) = v_code
  limit 1;

  if v_partner.id is null then
    raise exception 'partner not found';
  end if;

  update partners
  set
    active = false,
    status = 'rejected',
    reviewed_at = now(),
    reviewed_by = coalesce(nullif(btrim(p_source), ''), 'manual_validation'),
    review_source = coalesce(nullif(btrim(p_source), ''), 'manual_validation'),
    review_reason = v_reason
  where id = v_partner.id
  returning * into v_partner;

  update partner_applications
  set
    status = 'rejected',
    reviewed_at = now(),
    review_source = coalesce(nullif(btrim(p_source), ''), 'manual_validation'),
    review_reason = v_reason
  where partner_id = v_partner.id;

  return query
  select
    v_partner.id,
    upper(v_partner.code),
    v_partner.name,
    v_partner.active,
    v_partner.status;
end;
$$;

create or replace function public.create_activation_batch(
  p_partner_id uuid,
  p_package_name text,
  p_quantity integer,
  p_unit_price integer default 0,
  p_premium_duration_days integer default 30,
  p_payment_id text default null,
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
  v_payment_status text;
  v_existing_batch activation_code_batches%rowtype;
  v_payment_id text := nullif(btrim(p_payment_id), '');
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
  if v_payment_id is null then
    raise exception 'payment_id is required';
  end if;

  select *
  into v_existing_batch
  from activation_code_batches
  where payment_id = v_payment_id
  limit 1;

  if v_existing_batch.id is not null then
    return query
    select
      v_existing_batch.id,
      v_existing_batch.package_name,
      v_existing_batch.quantity,
      v_existing_batch.unit_price,
      v_existing_batch.total_price,
      v_existing_batch.premium_duration_days,
      v_existing_batch.status;
    return;
  end if;

  select status
  into v_payment_status
  from payment_events
  where payment_id = v_payment_id
  limit 1;

  if v_payment_status is null then
    raise exception 'payment not found';
  end if;

  if lower(coalesce(v_payment_status, '')) not in ('paid', 'completed', 'success') then
    raise exception 'payment not verified';
  end if;

  insert into activation_code_batches (
    partner_id,
    package_name,
    quantity,
    unit_price,
    total_price,
    premium_duration_days,
    status,
    payment_id,
    payment_status,
    payment_verified_at,
    paid_at,
    code_prefix
  )
  values (
    p_partner_id,
    btrim(p_package_name),
    p_quantity,
    greatest(0, coalesce(p_unit_price, 0)),
    greatest(0, coalesce(p_unit_price, 0)) * p_quantity,
    greatest(1, coalesce(p_premium_duration_days, 30)),
    'paid',
    v_payment_id,
    v_payment_status,
    now(),
    now(),
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

  if lower(coalesce(v_batch.status, '')) not in ('paid', 'generated') then
    raise exception 'batch must be paid before generation';
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

    return query
    select false, 'redeemed', v_row.premium_until, v_row.code, v_row.batch_id, v_row.partner_id;
    return;
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

revoke all on function public.register_partner(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  jsonb
) from public;

revoke all on function public.approve_partner_registration(text, text) from public;
revoke all on function public.reject_partner_registration(text, text, text) from public;
revoke all on function public.create_activation_batch(
  uuid,
  text,
  integer,
  integer,
  integer,
  text,
  text
) from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.register_partner(
      text,
      text,
      text,
      text,
      text,
      text,
      text,
      text,
      text,
      text,
      text,
      text,
      jsonb
    ) to service_role;
    grant execute on function public.approve_partner_registration(text, text)
      to service_role;
    grant execute on function public.reject_partner_registration(
      text,
      text,
      text
    ) to service_role;
    grant execute on function public.create_activation_batch(
      uuid,
      text,
      integer,
      integer,
      integer,
      text,
      text
    ) to service_role;
    grant execute on function public.generate_activation_codes(uuid)
      to service_role;
    grant execute on function public.redeem_activation_code(
      text,
      text,
      text,
      jsonb
    ) to service_role;
  end if;
end $$;

