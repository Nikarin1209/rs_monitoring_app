-- Adds in-app chat and notifications for doctor-patient communication.

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 4000),
  read_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create index if not exists chat_messages_pair_created_idx
on public.chat_messages(sender_id, receiver_id, created_at);

create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  type text not null check (
    type in ('treatment_assigned', 'treatment_updated', 'visit_scheduled')
  ),
  title text not null,
  body text not null,
  treatment_plan_id uuid references public.treatment_plans(id) on delete set null,
  read_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create index if not exists app_notifications_user_created_idx
on public.app_notifications(user_id, created_at desc);

alter table public.chat_messages enable row level security;
alter table public.app_notifications enable row level security;

-- A valid care pair is either:
-- - patient writes to their selected doctor
-- - doctor writes to their assigned patient
create or replace function public.is_care_pair(left_user uuid, right_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where (
      p.id = left_user
      and p.role = 'patient'
      and p.doctor_id = right_user
    ) or (
      p.id = right_user
      and p.role = 'patient'
      and p.doctor_id = left_user
    )
  );
$$;

drop policy if exists "Care pairs can select chat messages" on public.chat_messages;
create policy "Care pairs can select chat messages"
on public.chat_messages for select
to authenticated
using (
  (sender_id = auth.uid() or receiver_id = auth.uid())
  and public.is_care_pair(sender_id, receiver_id)
);

drop policy if exists "Care pairs can insert chat messages" on public.chat_messages;
create policy "Care pairs can insert chat messages"
on public.chat_messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_care_pair(sender_id, receiver_id)
);

drop policy if exists "Receivers can mark chat messages read" on public.chat_messages;
create policy "Receivers can mark chat messages read"
on public.chat_messages for update
to authenticated
using (receiver_id = auth.uid())
with check (receiver_id = auth.uid());

drop policy if exists "Users can select own app notifications" on public.app_notifications;
create policy "Users can select own app notifications"
on public.app_notifications for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can update own app notifications" on public.app_notifications;
create policy "Users can update own app notifications"
on public.app_notifications for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Doctors can insert patient app notifications" on public.app_notifications;
create policy "Doctors can insert patient app notifications"
on public.app_notifications for insert
to authenticated
with check (
  actor_id = auth.uid()
  and public.is_care_pair(actor_id, user_id)
);

grant select, insert, update on public.chat_messages to authenticated;
grant select, insert, update on public.app_notifications to authenticated;
