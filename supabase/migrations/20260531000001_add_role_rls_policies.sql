-- RLS bypass policies for custom DB roles (premium_checker, payments_processor).
-- Ces rôles sont utilisés par les edge functions via createRoleClient().
-- Les clés API custom avec secret_jwt_template nécessitent Pro plan,
-- on prépare les policies maintenant pour quand le projet upgrade.

create policy "premium_checker can select activations"
  on public.activations for select
  to premium_checker
  using (true);

create policy "premium_checker can select user_access_grants"
  on public.user_access_grants for select
  to premium_checker
  using (true);

create policy "payments_processor can manage payment_intents"
  on public.payment_intents for all
  to payments_processor
  using (true)
  with check (true);

create policy "payments_processor can select user_access_grants"
  on public.user_access_grants for select
  to payments_processor
  using (true);

create policy "payments_processor can select partners"
  on public.partners for select
  to payments_processor
  using (true);
