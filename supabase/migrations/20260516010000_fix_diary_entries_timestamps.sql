-- Fix existing diary_entries tables that have the updated_at trigger
-- but were created before the created_at/updated_at columns existed.

alter table public.diary_entries
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

drop trigger if exists set_diary_entries_updated_at on public.diary_entries;

create trigger set_diary_entries_updated_at
before update on public.diary_entries
for each row execute function public.set_updated_at();
