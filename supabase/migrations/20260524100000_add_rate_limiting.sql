create table if not exists public.rate_limits (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  key text not null,
  window_start timestamptz not null default now(),
  count integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_rate_limits_bucket_key_window
  on public.rate_limits (bucket, key, window_start);

alter table public.rate_limits enable row level security;

drop policy if exists "service_role can manage rate_limits" on public.rate_limits;
create policy "service_role can manage rate_limits"
  on public.rate_limits using (true) with check (true);

create or replace function public.check_rate_limit(
  p_bucket text,
  p_key text,
  p_max_attempts integer default 10,
  p_window_seconds integer default 60
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  delete from public.rate_limits
  where window_start < now() - (p_window_seconds || ' seconds')::interval;

  insert into public.rate_limits (bucket, key, window_start, count)
  values (p_bucket, p_key, date_trunc('minute', now()), 1)
  on conflict (bucket, key, window_start)
  do update set count = public.rate_limits.count + 1, updated_at = now()
  returning count into v_count;

  return v_count <= p_max_attempts;
end;
$$;

grant execute on function public.check_rate_limit to service_role;

