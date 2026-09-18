-- P1: Wrap auth.uid() in subquery for better RLS execution plans.
-- psyco : seules les tables présentes dans la chaîne ET (payment_intents,
-- user_access_grants, partners) sont couvertes. profiles, device_tokens,
-- notifications n'existent pas dans le scope psychoTest+ et seraient rejetés
-- par drop policy ... on public.XXX si elles y figuraient.

drop policy if exists "payment_intents_select_own" on public.payment_intents;
create policy "payment_intents_select_own"
  on public.payment_intents for select
  to authenticated
  using ((select auth.uid()) = auth_user_id);

drop policy if exists "user_access_grants_select_own" on public.user_access_grants;
create policy "user_access_grants_select_own"
  on public.user_access_grants for select
  to authenticated
  using ((select auth.uid()) = auth_user_id);

drop policy if exists "partners_select_own" on public.partners;
create policy "partners_select_own"
  on public.partners for select
  to authenticated
  using ((select auth.uid()) = auth_user_id);