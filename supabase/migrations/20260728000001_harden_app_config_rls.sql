-- Harden app_config: enable RLS and lock writes to service_role only.
-- Live state (verified): relrowsecurity=false, no policies -> anon could read/write.
-- Read stays public (config is non-sensitive and consumed by the /config endpoint);
-- writes are restricted to service_role to prevent anon tampering with kill-switch,
-- force_block, fedapay_mode, welcome_codes_enabled, etc.

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_config_selectable_by_all" ON public.app_config;
CREATE POLICY "app_config_selectable_by_all"
  ON public.app_config
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "app_config_writable_by_service_role" ON public.app_config;
CREATE POLICY "app_config_writable_by_service_role"
  ON public.app_config
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
