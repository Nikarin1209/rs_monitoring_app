-- Adds editable display scale and unit labels for the settings screen.

alter table public.app_settings
add column if not exists symptom_scale_max integer not null default 10
check (symptom_scale_max in (5, 10, 100)),
add column if not exists symptom_scale_unit text not null default 'баллов',
add column if not exists sleep_unit text not null default 'ч',
add column if not exists tapping_unit text not null default 'уд/с';
