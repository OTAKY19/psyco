create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  product_sku text not null references public.catalog_products(sku),
  name text not null,
  description text,
  discount_type text not null check (discount_type in ('percentage', 'fixed_amount')),
  discount_value integer not null check (discount_value > 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  is_active boolean default true,
  max_uses integer check (max_uses is null or max_uses > 0),
  current_uses integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_promotions_active_period
  on public.promotions (is_active, starts_at, ends_at);

create index if not exists idx_promotions_product_sku
  on public.promotions (product_sku);

alter table public.promotions enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'promotions' and policyname = 'service_role insert promotions') then
    create policy "service_role insert promotions"
      on public.promotions for insert
      to service_role
      with check (true);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'promotions' and policyname = 'service_role update promotions') then
    create policy "service_role update promotions"
      on public.promotions for update
      to service_role
      using (true)
      with check (true);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'promotions' and policyname = 'service_role delete promotions') then
    create policy "service_role delete promotions"
      on public.promotions for delete
      to service_role
      using (true);
  end if;
end;
$$;

create or replace function public.promotion_used()
returns trigger
language plpgsql
as $$
begin
  update public.promotions
  set current_uses = current_uses + 1,
      updated_at = now()
  where id = new.promotion_id
    and (max_uses is null or current_uses < max_uses);
  return new;
end;
$$;
