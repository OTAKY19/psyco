-- Fix 1: Rewrite approve_partner_registration to link auth_user_id
-- Accept optional p_auth_user_id; if null, auto-resolve from partner email

drop function if exists public.approve_partner_registration(text, text);

create or replace function public.approve_partner_registration(
  p_partner_code text,
  p_source text default 'manual_validation',
  p_auth_user_id uuid default null
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
  v_auth_user_id uuid;
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

  -- Resolve auth_user_id: explicit param > existing value > lookup by email
  v_auth_user_id := coalesce(
    p_auth_user_id,
    v_partner.auth_user_id,
    (select id from auth.users where email = v_partner.email limit 1)
  );

  update partners
  set
    active = true,
    status = 'approved',
    auth_user_id = coalesce(v_auth_user_id, v_partner.auth_user_id),
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

grant execute on function public.approve_partner_registration(text, text, uuid) to service_role;

-- Fix 2: Backfill auth_user_id for existing partners where email matches an auth user

update partners
set auth_user_id = au.id
from auth.users au
where partners.auth_user_id is null
  and partners.email is not null
  and au.email = partners.email;

-- Fix 3: Drop orphan 13-param register_partner_submission overload
-- The 14-param version (with auth_user_id) is now used by all callers

drop function if exists public.register_partner_submission(text,text,text,text,text,text,text,text,text,text,text,text,jsonb);
