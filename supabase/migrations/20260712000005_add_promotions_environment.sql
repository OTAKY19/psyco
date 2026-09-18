-- Add environment column to promotions (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'promotions' AND column_name = 'environment'
  ) THEN
    ALTER TABLE public.promotions ADD COLUMN environment TEXT
      NOT NULL DEFAULT 'live'
      CHECK (environment IN ('sandbox', 'live'));
  END IF;
END $$;

-- Create index on environment column (if not exists)
CREATE INDEX IF NOT EXISTS idx_promotions_environment ON public.promotions (environment);
