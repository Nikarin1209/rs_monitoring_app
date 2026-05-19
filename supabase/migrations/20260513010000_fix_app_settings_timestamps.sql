-- Fix existing app_settings tables that have the updated_at trigger
-- but were created before the updated_at column existed.

alter table public.app_settings
add column if not exists created_at timestamp with time zone not null default now(),
add column if not exists updated_at timestamp with time zone not null default now();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_app_settings_updated_at on public.app_settings;
create trigger set_app_settings_updated_at
before update on public.app_settings
for each row execute function public.set_updated_at();
