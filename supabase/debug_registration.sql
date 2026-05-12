-- Run this in Supabase SQL Editor when sign-up fails with:
-- {"code":"unexpected_failure","message":"Database error saving new user"}

-- 1. Check custom triggers attached to auth.users.
select
  trigger_schema,
  trigger_name,
  event_manipulation,
  action_statement
from information_schema.triggers
where event_object_schema = 'auth'
  and event_object_table = 'users'
order by trigger_name;

-- 2. Find functions that mention profiles or auth.users.
select
  n.nspname as function_schema,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'auth')
  and p.prokind = 'f'
  and (
    pg_get_functiondef(p.oid) ilike '%profiles%' or
    pg_get_functiondef(p.oid) ilike '%auth.users%'
  )
order by n.nspname, p.proname;

-- 3. Check whether profiles still has stricter columns than the trigger expects.
select
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
order by ordinal_position;
