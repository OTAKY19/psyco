-- Atomic payment intent status update with precondition check
-- Prevents race conditions when duplicate webhook events arrive
-- Returns true if the status was actually updated, false if the precondition failed
create or replace function update_payment_intent_status_if(
  p_payment_intent_id uuid,
  p_expected_status text,
  p_new_status text,
  p_payload jsonb default '{}'
) returns boolean
language plpgsql
security definer
as $$
declare
  v_updated boolean;
begin
  update payment_intents
  set
    status = p_new_status,
    provider_payload = p_payload,
    updated_at = now(),
    paid_at = case when p_new_status = 'completed' then now() else paid_at end
  where
    id = p_payment_intent_id
    and (
      status = p_expected_status
      or p_expected_status is null
    );
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;
