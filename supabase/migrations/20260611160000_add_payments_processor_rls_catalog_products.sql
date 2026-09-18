do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'catalog_products' and policyname = 'payments_processor can select catalog_products') then
    create policy "payments_processor can select catalog_products"
      on public.catalog_products
      for select
      to payments_processor
      using (is_active = true);
  end if;
end;
$$;
