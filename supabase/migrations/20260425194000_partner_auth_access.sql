-- Link partner access to Supabase Auth instead of a partner code entry.

alter table if exists partners
  add column if not exists auth_user_id uuid;

create unique index if not exists partners_auth_user_id_key
  on partners (auth_user_id)
  where auth_user_id is not null;

create index if not exists partners_auth_user_id_idx
  on partners (auth_user_id);

create or replace function public.register_partner_submission(
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
  p_auth_user_id uuid default null,
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
    or (
      p.auth_user_id is not null and p.auth_user_id = p_auth_user_id
    )
  order by p.created_at asc
  limit 1;

  if v_partner.id is not null then
    if v_partner.auth_user_id is not null and p_auth_user_id is not null and v_partner.auth_user_id <> p_auth_user_id then
      raise exception 'partner account is already linked to another user';
    end if;

    v_is_approved := lower(coalesce(v_partner.status, '')) = 'approved'
      and coalesce(v_partner.active, false);

    update partners
    set
      name = coalesce(v_partner.name, v_name),
      email = coalesce(v_partner.email, v_email),
      auth_user_id = coalesce(v_partner.auth_user_id, p_auth_user_id),
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
    auth_user_id,
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
    p_auth_user_id,
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

revoke all on function public.register_partner_submission(
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
  uuid,
  text,
  jsonb
) from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.register_partner_submission(
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
      uuid,
      text,
      jsonb
    ) to service_role;
  end if;
end $$;

