-- Add permit_files column to projects table
-- Run on BOTH dev and prod Supabase
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS permit_files jsonb default '{}';
