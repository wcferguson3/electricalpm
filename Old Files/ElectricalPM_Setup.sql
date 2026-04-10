-- ============================================================
-- ElectricalPM - Supabase Database Setup
-- Paste this entire script into Supabase > SQL Editor > New Query
-- Then click Run
-- ============================================================


-- PROFILES (extends auth.users, stores role)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  full_name text default '',
  role text not null default 'viewer' check (role in ('master', 'admin', 'viewer')),
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;


-- PROJECTS
create table if not exists public.projects (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  client text default '',
  address text default '',
  contract_value numeric default 0,
  status text default 'Active',
  start_date date,
  completion_date date,
  job_number text default '',
  pm text default '',
  notes text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.projects enable row level security;


-- CHANGE ORDERS
create table if not exists public.change_orders (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects on delete cascade not null,
  co_number text default '',
  description text default '',
  amount numeric default 0,
  status text default 'Pending',
  approved_by text default '',
  approval_date date,
  workflow_notes text default '',
  file_name text default '',
  file_type text default '',
  ai_summary text default '',
  created_at timestamptz default now()
);
alter table public.change_orders enable row level security;


-- SUBMITTALS
create table if not exists public.submittals (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects on delete cascade not null,
  sub_number text default '',
  spec_section text default '',
  description text default '',
  submitted_date date,
  returned_date date,
  status text default 'Pending',
  resubmittal_date date,
  resubmittal_returned date,
  notes text default '',
  created_at timestamptz default now()
);
alter table public.submittals enable row level security;


-- MATERIALS (financial - admin/master only)
create table if not exists public.materials (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects on delete cascade not null,
  description text default '',
  budgeted numeric default 0,
  actual numeric default 0,
  notes text default '',
  created_at timestamptz default now()
);
alter table public.materials enable row level security;


-- LABOR (financial - admin/master only)
create table if not exists public.labor (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects on delete cascade not null,
  description text default '',
  budgeted numeric default 0,
  actual numeric default 0,
  notes text default '',
  created_at timestamptz default now()
);
alter table public.labor enable row level security;


-- STARTUP CHECKS
create table if not exists public.startup_checks (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects on delete cascade not null,
  item_id text not null,
  completed boolean default false,
  completed_date date,
  completed_by text default '',
  created_at timestamptz default now(),
  unique(project_id, item_id)
);
alter table public.startup_checks enable row level security;


-- CONTRACTS (financial - admin/master only)
create table if not exists public.contracts (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects on delete cascade not null,
  contract_type text default '',
  contract_number text default '',
  parties text default '',
  value numeric default 0,
  execution_date date,
  start_date date,
  completion_date date,
  scope text default '',
  key_terms text default '',
  created_at timestamptz default now()
);
alter table public.contracts enable row level security;


-- ============================================================
-- HELPER: get current user's role
-- ============================================================
create or replace function public.get_user_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;


-- ============================================================
-- TRIGGER: auto-create profile on signup
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    'viewer'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ============================================================
-- RLS POLICIES
-- ============================================================

-- PROFILES
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Master can view all profiles" on public.profiles;
drop policy if exists "Master can update all profiles" on public.profiles;

create policy "Users can view own profile" on public.profiles
  for select using (id = auth.uid());
create policy "Master can view all profiles" on public.profiles
  for select using (public.get_user_role() = 'master');
create policy "Master can update all profiles" on public.profiles
  for update using (public.get_user_role() = 'master');


-- PROJECTS
drop policy if exists "Authenticated users can view projects" on public.projects;
drop policy if exists "Admin and master can insert projects" on public.projects;
drop policy if exists "Admin and master can update projects" on public.projects;
drop policy if exists "Master can delete projects" on public.projects;

create policy "Authenticated users can view projects" on public.projects
  for select using (auth.role() = 'authenticated');
create policy "Admin and master can insert projects" on public.projects
  for insert with check (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can update projects" on public.projects
  for update using (public.get_user_role() in ('master', 'admin'));
create policy "Master can delete projects" on public.projects
  for delete using (public.get_user_role() = 'master');


-- CHANGE ORDERS
drop policy if exists "Authenticated users can view change orders" on public.change_orders;
drop policy if exists "Admin and master can insert change orders" on public.change_orders;
drop policy if exists "Admin and master can update change orders" on public.change_orders;
drop policy if exists "Master can delete change orders" on public.change_orders;

create policy "Authenticated users can view change orders" on public.change_orders
  for select using (auth.role() = 'authenticated');
create policy "Admin and master can insert change orders" on public.change_orders
  for insert with check (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can update change orders" on public.change_orders
  for update using (public.get_user_role() in ('master', 'admin'));
create policy "Master can delete change orders" on public.change_orders
  for delete using (public.get_user_role() = 'master');


-- SUBMITTALS
drop policy if exists "Authenticated users can view submittals" on public.submittals;
drop policy if exists "Admin and master can insert submittals" on public.submittals;
drop policy if exists "Admin and master can update submittals" on public.submittals;
drop policy if exists "Master can delete submittals" on public.submittals;

create policy "Authenticated users can view submittals" on public.submittals
  for select using (auth.role() = 'authenticated');
create policy "Admin and master can insert submittals" on public.submittals
  for insert with check (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can update submittals" on public.submittals
  for update using (public.get_user_role() in ('master', 'admin'));
create policy "Master can delete submittals" on public.submittals
  for delete using (public.get_user_role() = 'master');


-- STARTUP CHECKS (all roles can read and update)
drop policy if exists "Authenticated users can view startup checks" on public.startup_checks;
drop policy if exists "Authenticated users can insert startup checks" on public.startup_checks;
drop policy if exists "Authenticated users can update startup checks" on public.startup_checks;
drop policy if exists "Master can delete startup checks" on public.startup_checks;

create policy "Authenticated users can view startup checks" on public.startup_checks
  for select using (auth.role() = 'authenticated');
create policy "Authenticated users can insert startup checks" on public.startup_checks
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated users can update startup checks" on public.startup_checks
  for update using (auth.role() = 'authenticated');
create policy "Master can delete startup checks" on public.startup_checks
  for delete using (public.get_user_role() in ('master', 'admin'));


-- MATERIALS (admin/master only)
drop policy if exists "Admin and master can view materials" on public.materials;
drop policy if exists "Admin and master can insert materials" on public.materials;
drop policy if exists "Admin and master can update materials" on public.materials;
drop policy if exists "Master can delete materials" on public.materials;

create policy "Admin and master can view materials" on public.materials
  for select using (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can insert materials" on public.materials
  for insert with check (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can update materials" on public.materials
  for update using (public.get_user_role() in ('master', 'admin'));
create policy "Master can delete materials" on public.materials
  for delete using (public.get_user_role() = 'master');


-- LABOR (admin/master only)
drop policy if exists "Admin and master can view labor" on public.labor;
drop policy if exists "Admin and master can insert labor" on public.labor;
drop policy if exists "Admin and master can update labor" on public.labor;
drop policy if exists "Master can delete labor" on public.labor;

create policy "Admin and master can view labor" on public.labor
  for select using (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can insert labor" on public.labor
  for insert with check (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can update labor" on public.labor
  for update using (public.get_user_role() in ('master', 'admin'));
create policy "Master can delete labor" on public.labor
  for delete using (public.get_user_role() = 'master');


-- CONTRACTS (admin/master only)
drop policy if exists "Admin and master can view contracts" on public.contracts;
drop policy if exists "Admin and master can insert contracts" on public.contracts;
drop policy if exists "Admin and master can update contracts" on public.contracts;
drop policy if exists "Master can delete contracts" on public.contracts;

create policy "Admin and master can view contracts" on public.contracts
  for select using (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can insert contracts" on public.contracts
  for insert with check (public.get_user_role() in ('master', 'admin'));
create policy "Admin and master can update contracts" on public.contracts
  for update using (public.get_user_role() in ('master', 'admin'));
create policy "Master can delete contracts" on public.contracts
  for delete using (public.get_user_role() = 'master');
