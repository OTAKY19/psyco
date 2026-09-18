alter table public.promotions enable row level security;

alter table public.company_contacts enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'promotions' and policyname = 'Anyone can read active promotions') then
    create policy "Anyone can read active promotions"
      on public.promotions
      for select
      using (is_active = true);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'company_contacts' and policyname = 'Anyone can read company contacts') then
    create policy "Anyone can read company contacts"
      on public.company_contacts
      for select
      using (true);
  end if;
end;
$$;
