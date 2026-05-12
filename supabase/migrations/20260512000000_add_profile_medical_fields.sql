-- Adds optional patient profile fields used by the settings screen.

alter table public.profiles
  add column if not exists birth_date date,
  add column if not exists sex text not null default '',
  add column if not exists phone text not null default '',
  add column if not exists ms_type text not null default '',
  add column if not exists diagnosis_date date,
  add column if not exists current_therapy text not null default '',
  add column if not exists doctor_name text not null default '',
  add column if not exists clinic_name text not null default '',
  add column if not exists emergency_contact_name text not null default '',
  add column if not exists emergency_contact_phone text not null default '';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_sex_check'
  ) then
    alter table public.profiles
      add constraint profiles_sex_check
      check (sex in ('', 'female', 'male', 'other'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_ms_type_check'
  ) then
    alter table public.profiles
      add constraint profiles_ms_type_check
      check (ms_type in ('', 'rrms', 'spms', 'ppms', 'cis', 'unknown'));
  end if;
end;
$$;
