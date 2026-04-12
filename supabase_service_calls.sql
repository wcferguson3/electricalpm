-- Add service_calls key to app_data table
INSERT INTO app_data (key, data) VALUES
  ('service_calls', '[]'::jsonb)
ON CONFLICT (key) DO NOTHING;
