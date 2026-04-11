-- Allow all authenticated users to update projects
-- Needed for field workers to submit RFIs, etc.
-- Run on BOTH dev and prod Supabase SQL Editor

DROP POLICY IF EXISTS "Admin and master can update projects" ON public.projects;
CREATE POLICY "Authenticated users can update projects" ON public.projects
  FOR UPDATE USING (auth.role() = 'authenticated');
