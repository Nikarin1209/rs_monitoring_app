-- Adds doctor profiles, patient-doctor assignment, and treatment plans.

alter table public.profiles
  add column if not exists role text not null default 'patient',
  add column if not exists doctor_id uuid references public.profiles(id) on delete set null,
  add column if not exists doctor_specialty text not null default '';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_role_check'
  ) then
    alter table public.profiles
      add constraint profiles_role_check check (role in ('patient', 'doctor'));
  end if;
end;
$$;

create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists profiles_doctor_id_idx on public.profiles(doctor_id);

create table if not exists public.treatment_plans (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null default 'План лечения',
  medication text not null default '',
  dosage text not null default '',
  recommendations text not null default '',
  contact_note text not null default '',
  next_visit_at date,
  active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists treatment_plans_doctor_patient_idx
on public.treatment_plans(doctor_id, patient_id, active, created_at desc);

drop trigger if exists set_treatment_plans_updated_at on public.treatment_plans;
create trigger set_treatment_plans_updated_at
before update on public.treatment_plans
for each row execute function public.set_updated_at();

alter table public.treatment_plans enable row level security;

-- Keep Auth metadata and public profiles aligned for new sign-ups.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    name,
    email,
    role,
    observation_start_date,
    phone,
    doctor_specialty,
    clinic_name
  )
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), split_part(new.email, '@', 1), 'User'),
    coalesce(new.email, ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'role', ''), 'patient'),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'observation_start_date', '')::timestamp with time zone,
      now()
    ),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'doctor_specialty', ''),
    coalesce(new.raw_user_meta_data ->> 'clinic_name', '')
  )
  on conflict (id) do update set
    name = excluded.name,
    email = excluded.email,
    role = excluded.role,
    observation_start_date = excluded.observation_start_date,
    phone = excluded.phone,
    doctor_specialty = excluded.doctor_specialty,
    clinic_name = excluded.clinic_name;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Profiles: own profile, registered doctors for patient selection, and
-- assigned patient profiles for the treating doctor.
drop policy if exists "Users can select own profile" on public.profiles;
create policy "Users can select own profile"
on public.profiles for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Authenticated users can select doctors" on public.profiles;
create policy "Authenticated users can select doctors"
on public.profiles for select
to authenticated
using (role = 'doctor');

drop policy if exists "Doctors can select assigned patients" on public.profiles;
create policy "Doctors can select assigned patients"
on public.profiles for select
to authenticated
using (role = 'patient' and doctor_id = auth.uid());

drop policy if exists "Doctors can select assigned diary entries" on public.diary_entries;
create policy "Doctors can select assigned diary entries"
on public.diary_entries for select
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = diary_entries.user_id
      and p.doctor_id = auth.uid()
  )
);

drop policy if exists "Doctors can select assigned test results" on public.test_results;
create policy "Doctors can select assigned test results"
on public.test_results for select
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = test_results.user_id
      and p.doctor_id = auth.uid()
  )
);

drop policy if exists "Doctors and patients can select treatment plans" on public.treatment_plans;
create policy "Doctors and patients can select treatment plans"
on public.treatment_plans for select
to authenticated
using (doctor_id = auth.uid() or patient_id = auth.uid());

drop policy if exists "Doctors can insert treatment plans" on public.treatment_plans;
create policy "Doctors can insert treatment plans"
on public.treatment_plans for insert
to authenticated
with check (
  doctor_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = treatment_plans.patient_id
      and p.doctor_id = auth.uid()
  )
);

drop policy if exists "Doctors can update treatment plans" on public.treatment_plans;
create policy "Doctors can update treatment plans"
on public.treatment_plans for update
to authenticated
using (doctor_id = auth.uid())
with check (
  doctor_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = treatment_plans.patient_id
      and p.doctor_id = auth.uid()
  )
);

drop policy if exists "Doctors can delete treatment plans" on public.treatment_plans;
create policy "Doctors can delete treatment plans"
on public.treatment_plans for delete
to authenticated
using (doctor_id = auth.uid());

grant select, insert, update, delete on public.treatment_plans to authenticated;
