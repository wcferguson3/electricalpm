-- ============================================================
-- ElectricalPM - Allow all authenticated users to view profiles
-- Needed so field workers can see employee list for timesheets
-- Run on BOTH dev and prod Supabase projects
-- ============================================================

-- Replace the two separate SELECT policies with one that covers everyone
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Master can view all profiles" ON public.profiles;

CREATE POLICY "Authenticated users can view all profiles" ON public.profiles
  FOR SELECT USING (auth.role() = 'authenticated');
