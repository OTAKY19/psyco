CREATE TABLE IF NOT EXISTS app_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

INSERT INTO app_config (key, value) VALUES
  ('minimum_build',      '1'),
  ('blocked_builds',     ''),
  ('store_url_android',  ''),
  ('store_url_ios',      ''),
  ('blocking_message',   '⚠️ Cette version n''est plus supportée. Téléchargez la dernière version depuis le store officiel.'),
  ('soft_banner',        '📱 Version de test — l''application officielle sera bientôt disponible sur les stores.'),
  ('force_block',        'false'),
  ('kill_switch_enabled', 'true'),
  ('block_deadline',      '')
ON CONFLICT DO NOTHING;

do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'app_config' and policyname = 'app_config_selectable_by_all') then
    CREATE POLICY "app_config_selectable_by_all" ON app_config FOR SELECT USING (true);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'app_config' and policyname = 'app_config_writable_by_service_role') then
    CREATE POLICY "app_config_writable_by_service_role" ON app_config FOR ALL USING (true);
  end if;
end;
$$;
