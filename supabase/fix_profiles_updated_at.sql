-- Fix for profile save error:
-- record "new" has no field "updated_at"
--
-- Cause:
-- public.profiles has an update trigger that writes NEW.updated_at, but the
-- existing table was created before the updated_at column existed.

alter table public.profiles
  add column if not exists updated_at timestamp with time zone not null default now();

alter table public.profiles
  add column if not exists created_at timestamp with time zone not null default now();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

