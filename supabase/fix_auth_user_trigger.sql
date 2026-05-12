-- Fix for Supabase Auth sign-up error:
-- {"code":"unexpected_failure","message":"Database error saving new user"}
--
-- Cause in this project:
-- auth.users has a trigger named on_auth_user_created that runs
-- handle_new_user(). That trigger inserts into public.profiles before the app
-- can provide the required profile fields, so profiles.name becomes null.
--
-- This app already creates/upserts public.profiles from Flutter after sign-up,
-- so the safest fix is to remove the old auth trigger.

drop trigger if exists on_auth_user_created on auth.users;

-- Optional cleanup: remove the old trigger function if nothing else uses it.
-- Leave this commented if you are not sure.
-- drop function if exists public.handle_new_user();

