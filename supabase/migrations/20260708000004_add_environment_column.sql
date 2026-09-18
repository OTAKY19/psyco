-- Add environment column to all transactional data tables
-- Isolates sandbox (test) data from live (production) data.
-- All existing rows are production data, so DEFAULT 'live' is correct.
-- Indexes support filtered queries by the active environment.

ALTER TABLE public.payment_intents ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.payment_provider_events ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.activations ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.user_access_grants ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.partners ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.partner_applications ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.activation_codes ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.activation_code_batches ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.activation_code_redemptions ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));
ALTER TABLE public.payment_events ADD COLUMN environment TEXT NOT NULL DEFAULT 'live' CHECK (environment IN ('sandbox', 'live'));

CREATE INDEX IF NOT EXISTS idx_payment_intents_environment ON public.payment_intents(environment);
CREATE INDEX IF NOT EXISTS idx_activations_environment ON public.activations(environment);
CREATE INDEX IF NOT EXISTS idx_user_access_grants_environment ON public.user_access_grants(environment);
CREATE INDEX IF NOT EXISTS idx_partners_environment ON public.partners(environment);
CREATE INDEX IF NOT EXISTS idx_partner_applications_environment ON public.partner_applications(environment);
CREATE INDEX IF NOT EXISTS idx_activation_codes_environment ON public.activation_codes(environment);
CREATE INDEX IF NOT EXISTS idx_activation_code_batches_environment ON public.activation_code_batches(environment);
CREATE INDEX IF NOT EXISTS idx_activation_code_redemptions_environment ON public.activation_code_redemptions(environment);
CREATE INDEX IF NOT EXISTS idx_payment_provider_events_environment ON public.payment_provider_events(environment);
