-- Add invoice_settings key to app_data table
INSERT INTO app_data (key, data) VALUES
  ('invoice_settings', '{"ccContacts":[]}'::jsonb)
ON CONFLICT (key) DO NOTHING;
