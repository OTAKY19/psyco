-- C2: Fix 3 SECURITY DEFINER functions missing search_path
-- See: docs/audit-2026-06-18.md — "6 fonctions sans search_path fixé"
-- Schema injection prevention: SET search_path TO '' (empty) recommended
-- Table references must be schema-qualified when search_path is empty.

create or replace function public.create_activation_batch(
  p_partner_id uuid,
  p_package_name text,
  p_quantity integer,
  p_unit_price integer,
  p_premium_duration_days integer,
  p_code_prefix text
)
returns table(batch_id uuid, package_name text, quantity integer, unit_price integer, total_price integer, premium_duration_days integer, status text)
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_batch public.activation_code_batches%rowtype;
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

  insert into public.activation_code_batches (
    partner_id, package_name, quantity, unit_price, total_price,
    premium_duration_days, status, code_prefix
  )
  values (
    p_partner_id, btrim(p_package_name), p_quantity,
    greatest(0, coalesce(p_unit_price, 0)),
    greatest(0, coalesce(p_unit_price, 0)) * p_quantity,
    greatest(1, coalesce(p_premium_duration_days, 30)),
    'draft', nullif(btrim(p_code_prefix), '')
  )
  returning * into v_batch;

  return query
  select v_batch.id, v_batch.package_name, v_batch.quantity,
         v_batch.unit_price, v_batch.total_price,
         v_batch.premium_duration_days, v_batch.status;
end;
$function$;

create or replace function public.create_activation_batch(
  p_partner_id uuid,
  p_package_name text,
  p_quantity integer,
  p_unit_price integer,
  p_premium_duration_days integer,
  p_payment_id text,
  p_code_prefix text
)
returns table(batch_id uuid, batch_status text)
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_payment_id text := nullif(btrim(coalesce(p_payment_id, '')), '');
  v_batch_id uuid;
  v_payment_status text;
  v_code_prefix text := nullif(btrim(coalesce(p_code_prefix, '')), '');
  v_unit_price int := coalesce(nullif(p_unit_price, 0), 0);
begin
  if p_partner_id is null then
    raise exception 'partner_id is required';
  end if;
  if nullif(btrim(coalesce(p_package_name, '')), '') is null then
    raise exception 'package_name is required';
  end if;
  if p_quantity is null or p_quantity < 1 then
    raise exception 'quantity must be at least 1';
  end if;
  if p_premium_duration_days is null or p_premium_duration_days < 1 then
    raise exception 'premium_duration_days must be at least 1';
  end if;

  if v_payment_id is not null then
    select public.payment_events.status
    into v_payment_status
    from public.payment_events
    where payment_id = v_payment_id
    limit 1;

    if v_payment_status is null then
      raise exception 'payment_id % not found', v_payment_id;
    end if;
  end if;

  insert into public.activation_code_batches (
    partner_id, package_name, quantity, unit_price, total_price,
    premium_duration_days, status, code_prefix, payment_id
  )
  values (
    p_partner_id, btrim(p_package_name), p_quantity, v_unit_price,
    v_unit_price * p_quantity, p_premium_duration_days,
    coalesce(v_payment_status, 'paid'), v_code_prefix, v_payment_id
  )
  returning id into v_batch_id;

  return query select v_batch_id, coalesce(v_payment_status, 'paid');
end;
$function$;

create or replace function public.update_payment_intent_status_if(
  p_payment_intent_id uuid,
  p_expected_status text,
  p_new_status text,
  p_payload jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_updated boolean;
begin
  update public.payment_intents
  set
    status = p_new_status,
    provider_payload = p_payload,
    updated_at = now(),
    paid_at = case when p_new_status = 'completed' then now() else paid_at end
  where
    id = p_payment_intent_id
    and (status = p_expected_status or p_expected_status is null);
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$function$;
