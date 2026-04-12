-- ============================================================
-- ElectricalPM - Timesheets Table (v2 — per project)
-- Paste this into Supabase > SQL Editor > New Query > Run
-- Run this on BOTH dev and prod Supabase projects
-- ============================================================

-- Drop old table if exists (safe — no production data yet)
DROP TABLE IF EXISTS public.timesheets;

-- Timesheets table — one per project per week per submitter
CREATE TABLE public.timesheets (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  submitted_by UUID REFERENCES auth.users ON DELETE SET NULL,
  submitted_by_name TEXT NOT NULL DEFAULT '',
  week_start DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved')),
  entries JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.timesheets ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Authenticated users can view timesheets" ON public.timesheets
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert timesheets" ON public.timesheets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update timesheets" ON public.timesheets
  FOR UPDATE USING (
    submitted_by = auth.uid()
    OR public.get_user_role() IN ('master', 'admin')
  );

CREATE POLICY "Users can delete own timesheets" ON public.timesheets
  FOR DELETE USING (
    submitted_by = auth.uid()
    OR public.get_user_role() IN ('master', 'admin')
  );
