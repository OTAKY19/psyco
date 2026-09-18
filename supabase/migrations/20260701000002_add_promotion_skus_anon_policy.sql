-- Allow anon/public to read promotion_skus (needed by config endpoint)
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'promotion_skus' and policyname = 'Anyone can read promotion_skus') then
    create policy "Anyone can read promotion_skus"
      on public.promotion_skus for select
      to public
      using (true);
  end if;
end;
$$;
