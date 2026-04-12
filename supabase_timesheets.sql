-- ============================================================
-- ElectricalPM - Timesheets Table
-- Paste this into Supabase > SQL Editor > New Query > Run
-- Run this on BOTH dev and prod Supabase projects
-- ============================================================

-- Timesheets table
CREATE TABLE IF NOT EXISTS public.timesheets (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  email TEXT NOT NULL DEFAULT '',
  full_name TEXT NOT NULL DEFAULT '',
  week_start DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved')),
  entries JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.timesheets ENABLE ROW LEVEL SECURITY;

-- Unique constraint: one timesheet per user per week
ALTER TABLE public.timesheets ADD CONSTRAINT timesheets_user_week_unique UNIQUE (user_id, week_start);

-- RLS Policies
-- All authenticated users can view all timesheets (office needs to see everyone's)
DROP POLICY IF EXISTS "Authenticated users can view timesheets" ON public.timesheets;
CREATE POLICY "Authenticated users can view timesheets" ON public.timesheets
  FOR SELECT USING (auth.role() = 'authenticated');

-- Users can insert their own timesheets
DROP POLICY IF EXISTS "Users can insert own timesheets" ON public.timesheets;
CREATE POLICY "Users can insert own timesheets" ON public.timesheets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own draft/submitted timesheets, master/admin can update any
DROP POLICY IF EXISTS "Users can update timesheets" ON public.timesheets;
CREATE POLICY "Users can update timesheets" ON public.timesheets
  FOR UPDATE USING (
    auth.uid() = user_id
    OR public.get_user_role() IN ('master', 'admin')
  );
