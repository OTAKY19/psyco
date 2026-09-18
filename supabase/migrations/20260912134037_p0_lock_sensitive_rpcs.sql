-- P0 — Verrouillage des RPC sensibles (audit sécurité).
--
-- psyco : seules les fonctions existantes dans le scope ET sont couvertes
-- (apply_paid_payment). cleanup_environment, batch_approve_partners,
-- get_admin_dashboard, get_admin_revenue, get_admin_overview_kpis n'existent
-- pas dans la chaîne ET psychoTest+ et seraient rejetés par les REVOKE.
-- La structure doctrine est conservée telle quelle pour faciliter les merges.

-- ============ 1. REVOKE PUBLIC / anon / authenticated ============

revoke all on function public.apply_paid_payment(
  text, text, integer, timestamp with time zone, jsonb
)
  from public, anon, authenticated;

-- ============ 2. Grants explicites aux rôles légitimes ============

grant execute on function public.apply_paid_payment(
  text, text, integer, timestamp with time zone, jsonb
) to service_role, payments_processor;

-- ============ 3. Auto-vérification bloquante ============

do $$
declare
  v_bad text;
begin
  select string_agg(p.oid::regprocedure::text, ', ' order by p.oid::regprocedure::text)
    into v_bad
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'apply_paid_payment'
    )
    and (
      p.proacl is null
      or exists (
        select 1
        from aclexplode(p.proacl) a
        where a.grantee = 0
          and a.privilege_type = 'EXECUTE'
      )
    );

  if v_bad is not null then
    raise exception 'P0 KEEP-OUT : PUBLIC garde EXECUTE sur : %', v_bad;
  end if;
end;
$$;