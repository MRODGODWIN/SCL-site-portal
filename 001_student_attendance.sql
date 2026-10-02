-- SCL student attendance: staff/admin only. Run in Supabase SQL editor.
create or replace function public.scl_is_staff() returns boolean language sql stable as $$
  -- ADAPT: matches roles stored in the JWT app_metadata. If your roles live in a table, query it here instead.
  select coalesce((auth.jwt()->'app_metadata'->'roles') ?| array['teacher','staff','developer','technical_admin','management_admin','affairs_admin'], false)
$$;
create or replace function public.scl_is_admin() returns boolean language sql stable as $$
  select coalesce((auth.jwt()->'app_metadata'->'roles') ?| array['developer','technical_admin','management_admin','affairs_admin'], false)
$$;
create table if not exists public.student_attendance(
  att_key text primary key, att_date date not null, class_name text not null, period text not null default '0',
  subject text default '', teacher_name text default '', marks jsonb not null default '{}',
  saved_by uuid default auth.uid(), saved_at timestamptz not null default now());
create index if not exists sa_date_idx on public.student_attendance(att_date, class_name);
alter table public.student_attendance enable row level security;
-- staff and admin only. No policy for students, parents or visitors, so they see nothing.
create policy sa_read on public.student_attendance for select using (public.scl_is_staff());
create policy sa_insert on public.student_attendance for insert with check (public.scl_is_staff());
create policy sa_update on public.student_attendance for update using (public.scl_is_staff() and (saved_by = auth.uid() or public.scl_is_admin()));
-- Parent notices: a parent only sees notices about their own child.
create table if not exists public.student_attendance_notices(
  id bigserial primary key, att_key text references public.student_attendance(att_key) on delete cascade,
  student_id text not null, parent_email text not null, att_date date not null, status text not null,
  message text, created_at timestamptz default now(), sent_at timestamptz, unique(att_key, student_id));
alter table public.student_attendance_notices enable row level security;
create policy san_parent on public.student_attendance_notices for select using (lower(parent_email) = lower(auth.jwt()->>'email'));
create policy san_staff on public.student_attendance_notices for select using (public.scl_is_admin());
