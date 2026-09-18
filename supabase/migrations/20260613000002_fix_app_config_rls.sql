-- S1: Restrict app_config writes to service_role only
-- The previous policy had no TO clause, making it public-writable.
drop policy if exists "app_config_writable_by_service_role" on public.app_config;

create policy "app_config_writable_by_service_role"
  on public.app_config
  for all
  to service_role
  using (true)
  with check (true);
