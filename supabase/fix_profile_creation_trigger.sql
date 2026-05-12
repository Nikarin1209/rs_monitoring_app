-- Recommended profile creation flow for this app.
--
-- Use this after removing the broken trigger that inserted profiles without
-- required fields. The Flutter app sends profile fields in auth user metadata;
-- this trigger copies those values into public.profiles.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
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
  on conflict (id) do update
  set
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
