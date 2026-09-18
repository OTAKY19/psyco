-- Create promotion_skus junction table for many-to-many SKU → promotion
create table if not exists public.promotion_skus (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  product_sku text not null,
  primary key (promotion_id, product_sku)
);

-- Migrate existing data from promotions.product_sku
insert into public.promotion_skus (promotion_id, product_sku)
select id, product_sku from public.promotions
on conflict do nothing;

-- Index for promo lookups
create index if not exists idx_promotion_skus_promotion_id
  on public.promotion_skus (promotion_id);

-- Index for SKU lookups (used by config endpoint)
create index if not exists idx_promotion_skus_product_sku
  on public.promotion_skus (product_sku);

-- Make product_sku nullable (still kept for backward compat, will be removed later)
alter table public.promotions alter column product_sku drop not null;

-- RLS for promotion_skus
alter table public.promotion_skus enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'promotion_skus' and policyname = 'service_role all promotion_skus') then
    create policy "service_role all promotion_skus"
      on public.promotion_skus for all
      to service_role
      using (true)
      with check (true);
  end if;
end;
$$;
