-- ============================================================
-- Fix timesheets RLS — use auth.uid() instead of auth.role()
-- Run on BOTH dev and prod Supabase projects
-- ============================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view timesheets" ON public.timesheets;
DROP POLICY IF EXISTS "Authenticated users can insert timesheets" ON public.timesheets;
DROP POLICY IF EXISTS "Users can update timesheets" ON public.timesheets;
DROP POLICY IF EXISTS "Users can delete own timesheets" ON public.timesheets;

-- SELECT: any logged-in user can see all timesheets
CREATE POLICY "Anyone can view timesheets" ON public.timesheets
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- INSERT: any logged-in user can create timesheets
CREATE POLICY "Anyone can insert timesheets" ON public.timesheets
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: own timesheets or master/admin
CREATE POLICY "Users can update timesheets" ON public.timesheets
  FOR UPDATE USING (
    submitted_by = auth.uid()
    OR public.get_user_role() IN ('master', 'admin')
  );

-- DELETE: own timesheets or master/admin
CREATE POLICY "Users can delete timesheets" ON public.timesheets
  FOR DELETE USING (
    submitted_by = auth.uid()
    OR public.get_user_role() IN ('master', 'admin')
  );
