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
  v_window_start timestamptz;
  v_count integer;
begin
  -- Choose truncation granularity based on window size
  if p_window_seconds <= 60 then
    v_window_start := date_trunc('minute', now());
  elsif p_window_seconds <= 3600 then
    v_window_start := date_trunc('hour', now());
  else
    v_window_start := date_trunc('day', now());
  end if;

  -- Cleanup old entries
  delete from public.rate_limits
  where bucket = p_bucket
    and created_at < now() - (p_window_seconds || ' seconds')::interval;

  -- Upsert counter
  insert into public.rate_limits (bucket, key, window_start, count)
  values (p_bucket, p_key, v_window_start, 1)
  on conflict (bucket, key, window_start)
  do update set count = public.rate_limits.count + 1, updated_at = now()
  returning count into v_count;

  return v_count <= p_max_attempts;
end;
$$;
