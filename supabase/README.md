# Supabase setup

This project expects these public tables:

- `profiles`
- `diary_entries`
- `test_results`
- `app_settings`
- `treatment_plans`
- `chat_messages`
- `app_notifications`

Apply the schema from `supabase/migrations/20260511000000_initial_schema.sql`.

## SQL Editor

1. Open your Supabase project.
2. Go to **SQL Editor**.
3. Paste the migration SQL.
4. Run it once.

## Supabase CLI

```sh
supabase link --project-ref adexqoztgljywbsedsth
supabase db push
```

The schema enables Row Level Security, so every authenticated user can only read
and write rows where `auth.uid()` matches their own `id` or `user_id`.
Doctor accounts can additionally read only the patient profiles, diary entries,
test results, and treatment plans for patients that selected that doctor in
their profile.
Chat messages and app notifications are also limited to that same doctor-patient
care pair.

When adding the extended patient profile fields to an existing project, run
`supabase/migrations/20260512000000_add_profile_medical_fields.sql` in SQL
Editor before saving the profile form in the app.

When adding doctor accounts and treatment assignments to an existing project,
run `supabase/migrations/20260512010000_add_doctor_profiles.sql` after the
medical fields migration.

For in-app chat and treatment/visit notifications, also run
`supabase/migrations/20260512020000_add_chat_notifications.sql`.

Note: the current app creates `profiles` from the client right after sign-up.
If email confirmation is enabled in Supabase Auth, the client may not have an
authenticated session immediately after sign-up. In that case, either disable
email confirmation during testing or adjust the sign-up flow to create the
profile after the user confirms email and signs in.

## Debugging registration

If registration fails in the app:

1. Run the app from terminal with `flutter run`.
2. Try to create the account again.
3. Look for `Sign-up failed:` in the Flutter console.
4. Open Supabase Dashboard -> Logs -> Auth for the same timestamp.

Common causes:

- `Signups not allowed` or `signup disabled`: enable signups in Auth settings.
- `Email provider disabled`: enable the Email provider in Auth settings.
- `row-level security`: check the `profiles` insert policy.
- `foreign key`: Auth user/session was not ready when the profile insert ran.
- `email rate limit` or `too many requests`: wait or adjust Auth rate limits.
- `Database error saving new user` plus a Postgres log like
  `null value in column "name" of relation "profiles"`: remove the old
  `on_auth_user_created` trigger with `supabase/fix_auth_user_trigger.sql`.
- If profile insert is rejected by RLS right after sign-up, keep RLS enabled and
  use `supabase/fix_profile_creation_trigger.sql`. It creates `profiles` on the
  server from Auth metadata, before the client needs to write profile data.
- `record "new" has no field "updated_at"`: run
  `supabase/fix_profiles_updated_at.sql` to add the missing timestamp columns
  expected by the update trigger.
