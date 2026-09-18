create table if not exists public.promotion_redemptions (
  id uuid primary key default gen_random_uuid(),
  promotion_id uuid not null references public.promotions(id),
  payment_intent_id uuid not null references public.payment_intents(id) unique,
  sku text not null,
  buyer_type text not null check (buyer_type in ('partner', 'student')),
  buyer_id text,
  redeemed_at timestamptz not null default now()
);

create index if not exists idx_promotion_redemptions_promo
  on public.promotion_redemptions(promotion_id);

create index if not exists idx_promotion_redemptions_date
  on public.promotion_redemptions(redeemed_at);

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_promotion_used' and tgrelid = 'public.promotion_redemptions'::regclass) then
    create trigger trg_promotion_used
      after insert on public.promotion_redemptions
      for each row execute function public.promotion_used();
  end if;
end;
$$;
