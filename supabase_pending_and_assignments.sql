-- ============================================================
-- ElectricalPM - Pending Role + Project Assignments
-- Paste this into Supabase > SQL Editor > New Query > Run
-- Run this on BOTH dev and prod Supabase projects
-- ============================================================

-- 1. Update role constraint to allow 'pending'
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('master', 'admin', 'viewer', 'pending'));

-- 2. Change default role for new signups to 'pending'
-- Update the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    'pending'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Add assigned_users JSONB column to projects table
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS assigned_users JSONB DEFAULT '[]'::jsonb;

-- 4. Allow master to DELETE profiles (for denying pending users)
DROP POLICY IF EXISTS "Master can delete profiles" ON public.profiles;
CREATE POLICY "Master can delete profiles" ON public.profiles
  FOR DELETE USING (public.get_user_role() = 'master');
