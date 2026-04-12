-- Add site_photos key to app_data table
INSERT INTO app_data (key, data) VALUES
  ('site_photos', '[]'::jsonb)
ON CONFLICT (key) DO NOTHING;
