-- ============================================================
-- ElectricalPM - Projects Table Setup
-- Run this in your DEV Supabase SQL Editor
-- ============================================================

create table if not exists public.projects (
  id text primary key,
  name text not null default '',
  job_number text default '',
  status text default 'Active',
  client text default '',
  address text default '',
  pm text default '',
  contract_value text default '',
  start_date text default '',
  completion_date text default '',
  po_number text default '',
  inspection_phone text default '',
  building_permit text default '',
  electrical_permit text default '',
  notes text default '',
  -- Inspection dates
  date_underground text default '',
  date_inwall text default '',
  date_overhead text default '',
  date_fire_alarm text default '',
  date_final_electrical text default '',
  date_service text default '',
  -- GC contacts
  gc_company text default '',
  gc_senior_pm_name text default '',
  gc_senior_pm_email text default '',
  gc_senior_pm_cell text default '',
  gc_pm_name text default '',
  gc_pm_email text default '',
  gc_pm_cell text default '',
  gc_asst_pm_name text default '',
  gc_asst_pm_email text default '',
  gc_asst_pm_cell text default '',
  gc_super_name text default '',
  gc_super_email text default '',
  gc_super_cell text default '',
  gc_asst_super_name text default '',
  gc_asst_super_email text default '',
  gc_asst_super_cell text default '',
  -- N/A inspections list
  na_inspections jsonb default '[]',
  -- Nested data (will be normalized into separate tables later)
  subcontractors jsonb default '[]',
  change_orders jsonb default '[]',
  submittals jsonb default '[]',
  materials jsonb default '[]',
  labor jsonb default '[]',
  startup_checks jsonb default '{}',
  contracts jsonb default '[]',
  rfis jsonb default '[]',
  daily_logs jsonb default '[]',
  punch_list jsonb default '[]',
  billing jsonb default '{}',
  notification_contacts jsonb default '[]',
  project_files jsonb default '[]',
  budget jsonb default '{}',
  -- Timestamps
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.projects enable row level security;

-- RLS: everyone logged in can view projects
drop policy if exists "Authenticated users can view projects" on public.projects;
create policy "Authenticated users can view projects" on public.projects
  for select using (auth.role() = 'authenticated');

-- RLS: admin and master can create/edit
drop policy if exists "Admin and master can insert projects" on public.projects;
create policy "Admin and master can insert projects" on public.projects
  for insert with check (public.get_user_role() in ('master', 'admin'));

drop policy if exists "Admin and master can update projects" on public.projects;
create policy "Admin and master can update projects" on public.projects
  for update using (public.get_user_role() in ('master', 'admin'));

-- RLS: only master can delete
drop policy if exists "Master can delete projects" on public.projects;
create policy "Master can delete projects" on public.projects
  for delete using (public.get_user_role() = 'master');
