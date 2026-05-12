-- NeuroLife Supabase schema.
-- Run this in Supabase SQL Editor or with `supabase db push`.

create extension if not exists pgcrypto;

-- Shared Helpers

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Profiles

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  email text not null check (char_length(trim(email)) between 3 and 320),
  observation_start_date timestamp with time zone not null default now(),
  birth_date date,
  sex text not null default '' check (sex in ('', 'female', 'male', 'other')),
  phone text not null default '',
  ms_type text not null default '' check (ms_type in ('', 'rrms', 'spms', 'ppms', 'cis', 'unknown')),
  diagnosis_date date,
  current_therapy text not null default '',
  doctor_name text not null default '',
  clinic_name text not null default '',
  emergency_contact_name text not null default '',
  emergency_contact_phone text not null default '',
  baseline_fatigue smallint not null default 5 check (baseline_fatigue between 0 and 10),
  baseline_pain smallint not null default 3 check (baseline_pain between 0 and 10),
  baseline_sleep numeric(4, 2) not null default 7.0 check (baseline_sleep between 0 and 24),
  pin_enabled boolean not null default false,
  face_id_enabled boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Diary Entries

create table if not exists public.diary_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date_time timestamp with time zone not null default now(),
  fatigue smallint not null check (fatigue between 0 and 10),
  pain smallint not null check (pain between 0 and 10),
  mood smallint not null check (mood between 0 and 10),
  sleep_hours numeric(4, 2) not null check (sleep_hours between 0 and 24),
  note text not null default '',
  flare_flag boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists diary_entries_user_date_idx
on public.diary_entries (user_id, date_time desc);

drop trigger if exists set_diary_entries_updated_at on public.diary_entries;
create trigger set_diary_entries_updated_at
before update on public.diary_entries
for each row execute function public.set_updated_at();

-- Test Results

create table if not exists public.test_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('tapping', 'reaction')),
  date_time timestamp with time zone not null default now(),
  value numeric(10, 3) not null check (value >= 0),
  duration_seconds integer not null check (duration_seconds > 0 and duration_seconds <= 3600),
  hand text check (
    (type = 'tapping' and hand is not null and hand in ('left', 'right')) or
    (type = 'reaction' and hand is null)
  ),
  metadata_json text,
  created_at timestamp with time zone not null default now()
);

create index if not exists test_results_user_date_idx
on public.test_results (user_id, date_time desc);

create index if not exists test_results_user_type_date_idx
on public.test_results (user_id, type, date_time desc);

-- App Settings

create table if not exists public.app_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  diary_reminder_enabled boolean not null default true,
  tapping_reminder_enabled boolean not null default true,
  reaction_reminder_enabled boolean not null default true,
  diary_reminder_time time without time zone not null default '20:00',
  tapping_reminder_time time without time zone not null default '10:00',
  reaction_reminder_time time without time zone not null default '11:00',
  notifications_enabled boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

drop trigger if exists set_app_settings_updated_at on public.app_settings;
create trigger set_app_settings_updated_at
before update on public.app_settings
for each row execute function public.set_updated_at();

-- Row Level Security

alter table public.profiles enable row level security;
alter table public.diary_entries enable row level security;
alter table public.test_results enable row level security;
alter table public.app_settings enable row level security;

drop policy if exists "Users can select own profile" on public.profiles;
create policy "Users can select own profile"
on public.profiles for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile"
on public.profiles for delete
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can select own diary entries" on public.diary_entries;
create policy "Users can select own diary entries"
on public.diary_entries for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own diary entries" on public.diary_entries;
create policy "Users can insert own diary entries"
on public.diary_entries for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own diary entries" on public.diary_entries;
create policy "Users can update own diary entries"
on public.diary_entries for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own diary entries" on public.diary_entries;
create policy "Users can delete own diary entries"
on public.diary_entries for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can select own test results" on public.test_results;
create policy "Users can select own test results"
on public.test_results for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own test results" on public.test_results;
create policy "Users can insert own test results"
on public.test_results for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own test results" on public.test_results;
create policy "Users can update own test results"
on public.test_results for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own test results" on public.test_results;
create policy "Users can delete own test results"
on public.test_results for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can select own app settings" on public.app_settings;
create policy "Users can select own app settings"
on public.app_settings for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own app settings" on public.app_settings;
create policy "Users can insert own app settings"
on public.app_settings for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own app settings" on public.app_settings;
create policy "Users can update own app settings"
on public.app_settings for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own app settings" on public.app_settings;
create policy "Users can delete own app settings"
on public.app_settings for delete
to authenticated
using (auth.uid() = user_id);

-- API Grants

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.diary_entries to authenticated;
grant select, insert, update, delete on public.test_results to authenticated;
grant select, insert, update, delete on public.app_settings to authenticated;
