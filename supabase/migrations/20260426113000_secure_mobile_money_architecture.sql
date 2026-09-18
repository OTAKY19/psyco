-- JWT-backed Mobile Money purchases, payment intents, and entitlement fulfillment.

create table if not exists public.catalog_products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  kind text not null check (kind in ('license_access', 'activation_pack')),
  name text not null,
  amount_xof integer not null check (amount_xof > 0),
  currency text not null default 'XOF' check (currency = 'XOF'),
  premium_duration_days integer check (premium_duration_days is null or premium_duration_days > 0),
  activation_code_quantity integer,
  package_name text,
  code_prefix text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalog_products_kind_payload_check check (
    (kind = 'license_access' and activation_code_quantity is null)
    or
    (kind = 'activation_pack' and activation_code_quantity is not null and activation_code_quantity > 0)
  )
);

create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  partner_id uuid references public.partners(id) on delete set null,
  product_id uuid not null references public.catalog_products(id),
  provider text not null check (lower(provider) in ('mtn', 'moov', 'celtiis')),
  client_nonce uuid not null default gen_random_uuid(),
  provider_payment_ref text unique,
  payment_gateway text not null default 'fedapay',
  phone_e164 text not null check (phone_e164 ~ '^[+]?[1-9][0-9]{7,14}$'),
  customer_email text,
  customer_first_name text,
  customer_last_name text,
  amount_xof integer not null check (amount_xof > 0),
  currency text not null default 'XOF' check (currency = 'XOF'),
  status text not null default 'created' check (
    lower(status) in ('created', 'pending', 'processing', 'approved', 'completed', 'failed', 'expired', 'cancelled')
  ),
  fulfillment_status text not null default 'pending' check (
    lower(fulfillment_status) in ('pending', 'fulfilled', 'failed')
  ),
  provider_payload jsonb not null default '{}'::jsonb,
  raw_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz,
  paid_at timestamptz,
  fulfilled_at timestamptz
);

create table if not exists public.payment_provider_events (
  id uuid primary key default gen_random_uuid(),
  payment_intent_id uuid not null references public.payment_intents(id) on delete cascade,
  provider_event_id text not null unique,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now()
);

create table if not exists public.user_access_grants (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  payment_intent_id uuid not null unique references public.payment_intents(id) on delete cascade,
  product_id uuid not null references public.catalog_products(id),
  status text not null default 'active' check (lower(status) in ('active', 'expired', 'revoked')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  granted_at timestamptz not null default now()
);

alter table if exists public.activation_code_batches
  add column if not exists payment_intent_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'activation_code_batches_payment_intent_id_fkey'
  ) then
    alter table public.activation_code_batches
      add constraint activation_code_batches_payment_intent_id_fkey
      foreign key (payment_intent_id)
      references public.payment_intents(id)
      on delete set null;
  end if;
end $$;

create unique index if not exists payment_intents_client_nonce_key
  on public.payment_intents (client_nonce);

create index if not exists payment_intents_auth_user_id_idx
  on public.payment_intents (auth_user_id, created_at desc);

create index if not exists payment_intents_status_idx
  on public.payment_intents (status, updated_at desc);

create index if not exists user_access_grants_auth_user_id_idx
  on public.user_access_grants (auth_user_id, granted_at desc);

create unique index if not exists activation_code_batches_payment_intent_id_key
  on public.activation_code_batches (payment_intent_id)
  where payment_intent_id is not null;

do $$
begin
  if exists (
    select 1
    from pg_proc
    where proname = 'set_updated_at'
  ) then
    if not exists (
      select 1 from pg_trigger where tgname = 'catalog_products_set_updated_at'
    ) then
      create trigger catalog_products_set_updated_at
      before update on public.catalog_products
      for each row execute function public.set_updated_at();
    end if;

    if not exists (
      select 1 from pg_trigger where tgname = 'payment_intents_set_updated_at'
    ) then
      create trigger payment_intents_set_updated_at
      before update on public.payment_intents
      for each row execute function public.set_updated_at();
    end if;
  end if;
end $$;

insert into public.catalog_products (
  sku,
  kind,
  name,
  amount_xof,
  currency,
  premium_duration_days,
  activation_code_quantity,
  package_name,
  code_prefix,
  is_active,
  metadata
)
values
  (
    'premium_lifetime',
    'license_access',
    'Acces Premium a vie',
    3000,
    'XOF',
    null,
    null,
    null,
    null,
    true,
    jsonb_build_object('feature', 'premium_access', 'lifetime', 'true')
  ),
  (
    'partner_starter_20',
    'activation_pack',
    'Pack Starter',
    5000,
    'XOF',
    30,
    20,
    'Pack Starter',
    'PSY',
    true,
    jsonb_build_object('pack_id', 'starter')
  ),
  (
    'partner_academy_50',
    'activation_pack',
    'Pack Academie',
    11000,
    'XOF',
    30,
    50,
    'Pack Academie',
    'PSY',
    true,
    jsonb_build_object('pack_id', 'academy')
  ),
  (
    'partner_enterprise_100',
    'activation_pack',
    'Pack Ecole',
    18000,
    'XOF',
    30,
    100,
    'Pack Ecole',
    'PSY',
    true,
    jsonb_build_object('pack_id', 'enterprise')
  )
on conflict (sku) do update
set
  kind = excluded.kind,
  name = excluded.name,
  amount_xof = excluded.amount_xof,
  currency = excluded.currency,
  premium_duration_days = excluded.premium_duration_days,
  activation_code_quantity = excluded.activation_code_quantity,
  package_name = excluded.package_name,
  code_prefix = excluded.code_prefix,
  is_active = excluded.is_active,
  metadata = excluded.metadata,
  updated_at = now();

alter table if exists public.catalog_products enable row level security;
alter table if exists public.payment_intents enable row level security;
alter table if exists public.payment_provider_events enable row level security;
alter table if exists public.user_access_grants enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'catalog_products'
      and policyname = 'catalog_products_select_active'
  ) then
    create policy catalog_products_select_active
      on public.catalog_products
      for select
      to authenticated
      using (is_active = true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'payment_intents'
      and policyname = 'payment_intents_select_own'
  ) then
    create policy payment_intents_select_own
      on public.payment_intents
      for select
      to authenticated
      using (auth.uid() = auth_user_id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'payment_provider_events'
      and policyname = 'payment_provider_events_deny_all'
  ) then
    create policy payment_provider_events_deny_all
      on public.payment_provider_events
      for all
      using (false)
      with check (false);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_access_grants'
      and policyname = 'user_access_grants_select_own'
  ) then
    create policy user_access_grants_select_own
      on public.user_access_grants
      for select
      to authenticated
      using (auth.uid() = auth_user_id);
  end if;
end $$;

create or replace function public.current_partner_id_for_auth_user()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.partners p
  where p.auth_user_id = auth.uid()
    and p.active = true
    and lower(coalesce(p.status, '')) = 'approved'
  limit 1;
$$;

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
      on conflict (payment_intent_id) do update
      set
        status = 'active',
        starts_at = excluded.starts_at,
        ends_at = excluded.ends_at,
        granted_at = excluded.granted_at
      returning * into v_grant;
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
        coalesce(nullif(v_product.code_prefix, ''), 'PSY'),
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

revoke all on function public.current_partner_id_for_auth_user() from public;
revoke all on function public.fulfill_payment_intent(uuid) from public;
revoke all on function public.create_activation_batch(uuid, text, integer, integer, integer, text, text) from public;
revoke all on function public.generate_activation_codes(uuid) from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.current_partner_id_for_auth_user() to service_role;
    grant execute on function public.fulfill_payment_intent(uuid) to service_role;
    grant execute on function public.create_activation_batch(uuid, text, integer, integer, integer, text, text) to service_role;
    grant execute on function public.generate_activation_codes(uuid) to service_role;
  end if;
end $$;

