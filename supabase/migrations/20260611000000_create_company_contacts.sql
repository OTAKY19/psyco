create table if not exists public.company_contacts (
  key text primary key,
  value text not null,
  label text not null default '',
  updated_at timestamptz not null default now()
);

insert into public.company_contacts (key, value, label) values
  ('company_name', 'PSYCOTEST PLUS SARL', 'Nom de l''entreprise'),
  ('company_address', 'Cotonou, République du Bénin', 'Adresse'),
  ('support_email', 'support@psycotestplus.com', 'Email support'),
  ('support_phone', '+229 56 26 26 26', 'Téléphone support'),
  ('whatsapp_link', 'https://wa.me/22956262626', 'Lien WhatsApp'),
  ('support_url', 'https://psycotestplus.com/support', 'URL support'),
  ('legal_email', 'legal@psycotestplus.com', 'Email juridique'),
  ('privacy_email', 'privacy@psycotestplus.com', 'Email données personnelles'),
  ('commercial_email', 'commercial@psycotestplus.com', 'Email commercial'),
  ('billing_email', 'facturation@psycotestplus.com', 'Email facturation'),
  ('refund_email', 'remboursement@psycotestplus.com', 'Email remboursement'),
  ('dpo_phone', '+229 21 32 57 88', 'Téléphone APDP/DPO')
on conflict (key) do nothing;