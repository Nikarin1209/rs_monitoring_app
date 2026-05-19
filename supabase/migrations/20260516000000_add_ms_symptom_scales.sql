-- Add MS-specific daily symptom scales to diary entries.

alter table public.diary_entries
  add column if not exists numbness smallint not null default 0 check (numbness between 0 and 10),
  add column if not exists coordination smallint not null default 0 check (coordination between 0 and 10),
  add column if not exists vision smallint not null default 0 check (vision between 0 and 10),
  add column if not exists weakness smallint not null default 0 check (weakness between 0 and 10),
  add column if not exists stress smallint not null default 0 check (stress between 0 and 10);
