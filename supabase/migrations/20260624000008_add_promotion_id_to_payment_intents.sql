alter table public.payment_intents
  add column if not exists promotion_id uuid references public.promotions(id);
