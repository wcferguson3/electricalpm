-- ============================================================
-- ElectricalPM - Auth & Profiles Setup
-- Paste this into Supabase > SQL Editor > New Query > Run
-- Run this on BOTH dev and prod Supabase projects
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


-- HELPER: get current user's role
create or replace function public.get_user_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;


-- TRIGGER: auto-create profile on signup (defaults to 'viewer')
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


-- RLS POLICIES for profiles
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Master can view all profiles" on public.profiles;
drop policy if exists "Master can update all profiles" on public.profiles;

create policy "Users can view own profile" on public.profiles
  for select using (id = auth.uid());
create policy "Master can view all profiles" on public.profiles
  for select using (public.get_user_role() = 'master');
create policy "Master can update all profiles" on public.profiles
  for update using (public.get_user_role() = 'master');
