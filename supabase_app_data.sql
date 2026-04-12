-- App Data table: shared key-value store for non-project data
-- Keys: employees, vehicles, tools, bids, cash_flow
CREATE TABLE IF NOT EXISTS app_data (
  key text PRIMARY KEY,
  data jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at timestamptz DEFAULT now()
);

-- RLS: all authenticated users can read, all can write
ALTER TABLE app_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view app_data"
  ON app_data FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert app_data"
  ON app_data FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update app_data"
  ON app_data FOR UPDATE
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete app_data"
  ON app_data FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- Seed empty rows so upsert works cleanly
INSERT INTO app_data (key, data) VALUES
  ('employees', '[]'::jsonb),
  ('vehicles', '[]'::jsonb),
  ('tools', '[]'::jsonb),
  ('bids', '[]'::jsonb),
  ('cash_flow', '{}'::jsonb)
ON CONFLICT (key) DO NOTHING;
