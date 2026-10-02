-- =====================================================================
-- SCL student attendance: server-side rules (run ONCE in Supabase > SQL Editor)
-- Safe to re-run. It does not delete any data.
--
-- What it enforces (even if someone bypasses the website):
--   * Must be signed in.
--   * Attendance can only be saved for TODAY (Lagos time). No backdating.
--   * Secondary (JSS/SSS): only the subject teacher on the timetable for that
--     class + period + day. Opens 15 minutes before the period, stays open
--     the rest of the day. Administrators and other teachers are blocked.
--   * Primary / early years: only the class teacher (from the teacher's
--     registration) or staff approved in the Approvals tab.
--       - Morning register (period 0): opens 8:00 AM
--       - Afternoon register (period 7): opens 12:00 noon, Monday-Thursday only
--   * Status must be present / absent / late.
-- =====================================================================

-- 1) Tables -----------------------------------------------------------
create table if not exists public.student_attendance (
  id bigserial primary key,
  attendance_date date not null,
  class_name text not null,
  period int not null default 0,          -- 1-6 secondary, 0 = primary morning, 7 = primary afternoon
  subject text,
  teacher_name text,
  student_id text not null,
  student_name text,
  status text not null,
  created_at timestamptz not null default now()
);
alter table public.student_attendance add column if not exists taken_by uuid;
alter table public.student_attendance add column if not exists taken_by_email text;
alter table public.student_attendance add column if not exists updated_at timestamptz default now();

-- one row per child per register (lets a teacher correct and re-save)
create unique index if not exists student_attendance_one_per_session
  on public.student_attendance (attendance_date, class_name, period, student_id);

create table if not exists public.scl_app_data (
  k text primary key,
  v jsonb,
  updated_at timestamptz default now()
);

-- 2) Row level security ----------------------------------------------
alter table public.student_attendance enable row level security;

drop policy if exists scl_att_read on public.student_attendance;
create policy scl_att_read on public.student_attendance
  for select to authenticated using (true);

drop policy if exists scl_att_insert on public.student_attendance;
create policy scl_att_insert on public.student_attendance
  for insert to authenticated with check (true);   -- the trigger below does the real check

drop policy if exists scl_att_update on public.student_attendance;
create policy scl_att_update on public.student_attendance
  for update to authenticated using (true) with check (true);

-- no delete policy on purpose: nobody can delete attendance from the app

-- 3) Helpers ----------------------------------------------------------
create or replace function public.scl_norm_class(c text) returns text
language sql immutable as $$
  select regexp_replace(lower(regexp_replace(coalesce(c,''), '\s+', '', 'g')), '^sss', 'ss')
$$;

create or replace function public.scl_norm_name(n text) returns text
language sql immutable as $$
  select btrim(regexp_replace(lower(coalesce(n,'')), '[^a-z]+', ' ', 'g'))
$$;

-- 4) The rule ---------------------------------------------------------
create or replace function public.scl_check_student_attendance() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_now   timestamp := (now() at time zone 'Africa/Lagos');
  v_today date := (now() at time zone 'Africa/Lagos')::date;
  v_min   int  := extract(hour from (now() at time zone 'Africa/Lagos'))::int * 60
                + extract(minute from (now() at time zone 'Africa/Lagos'))::int;
  v_dow   int  := extract(dow from (now() at time zone 'Africa/Lagos'))::int;
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_name  text := public.scl_norm_name(coalesce(auth.jwt() -> 'user_metadata' ->> 'full_name',
                                                auth.jwt() -> 'user_metadata' ->> 'name', ''));
  v_cls   text := public.scl_norm_class(new.class_name);
  v_sec   boolean := new.class_name ~* '^\s*(jss|sss)';
  v_key   text;
  v_day   text;
  v_slot  text;
  v_start int;
  v_ok    boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Sign in to take attendance.';
  end if;
  if new.status not in ('present','absent','late') then
    raise exception 'Invalid attendance status.';
  end if;
  if new.attendance_date <> v_today then
    raise exception 'Attendance can only be taken for today (%).', v_today;
  end if;
  if tg_op = 'UPDATE' and old.attendance_date <> v_today then
    raise exception 'Past attendance cannot be changed.';
  end if;
  if v_dow in (0, 6) then
    raise exception 'No attendance is taken at weekends.';
  end if;

  if v_sec then
    -- ---------------- SECONDARY: subject teacher only ----------------
    if new.period not between 1 and 6 then
      raise exception 'Invalid period.';
    end if;
    v_key  := case when v_dow = 5 then 'FRI' else 'A' end;
    v_day  := (array['sun','mon','tue','wed','thu','fri','sat'])[v_dow + 1];
    v_slot := 'p' || new.period;
    v_start := case v_key || v_slot
      when 'Ap1' then 510 when 'Ap2' then 565 when 'Ap3' then 620
      when 'Ap4' then 690 when 'Ap5' then 785 when 'Ap6' then 840
      when 'FRIp1' then 510 when 'FRIp2' then 560 when 'FRIp3' then 610 when 'FRIp4' then 660
      else null end;
    if v_start is null then
      raise exception 'There is no such period on today''s timetable.';
    end if;
    if v_min < v_start - 15 then
      raise exception 'This period has not opened yet (opens 15 minutes before it starts).';
    end if;

    select exists (
      select 1
      from public.scl_app_data d,
           jsonb_array_elements(case when jsonb_typeof(d.v) = 'array' then d.v else '[]'::jsonb end) e
      where d.k = 'sclTTAssign'
        and e ->> 'id' = v_cls || '|' || v_key || '|' || v_day || '|' || v_slot
        and coalesce(e ->> 'del', '0') not in ('1', 'true')
        and ( (v_email <> '' and lower(coalesce(e ->> 'email', '')) = v_email)
           or (v_name  <> '' and public.scl_norm_name(e ->> 'teacher') = v_name) )
    ) into v_ok;

    if not v_ok then
      raise exception 'Only the subject teacher on the timetable for this class and period can take this register.';
    end if;

  else
    -- ---------------- PRIMARY: class teacher or approved staff ----------------
    if new.period not in (0, 7) then
      raise exception 'Invalid primary register.';
    end if;
    if new.period = 7 and v_dow = 5 then
      raise exception 'There is no afternoon register on Fridays.';
    end if;
    if v_min < case when new.period = 0 then 480 else 720 end then
      raise exception 'This register has not opened yet (morning 8:00 AM, afternoon 12:00 noon).';
    end if;

    select exists (
      select 1
      from public.scl_app_data d,
           jsonb_array_elements(case when jsonb_typeof(d.v) = 'array' then d.v else '[]'::jsonb end) e
      where d.k in ('sclTTAssign', 'sclAttApproved')
        and (d.k = 'sclAttApproved' or coalesce(e ->> 'primary', '0') in ('1', 'true'))
        and public.scl_norm_class(e ->> 'cls') = v_cls
        and coalesce(e ->> 'del', '0') not in ('1', 'true')
        and ( (v_email <> '' and lower(coalesce(e ->> 'email', '')) = v_email)
           or (v_name  <> '' and public.scl_norm_name(e ->> 'teacher') = v_name) )
    ) into v_ok;

    if not v_ok then
      raise exception 'Only the class teacher, or staff approved for this class, can take this register.';
    end if;
  end if;

  new.taken_by := auth.uid();
  new.taken_by_email := v_email;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists scl_student_attendance_guard on public.student_attendance;
create trigger scl_student_attendance_guard
  before insert or update on public.student_attendance
  for each row execute function public.scl_check_student_attendance();

-- 5) Term attendance -> extra marks (same bands as the website) --------
-- 90-100% = 10 | 70-89% = 8 | 50-69% = 6 | 40-49% = 4 | 30-39% = 3 | 10-29% = 2 | 1-9% = 1 | 0% = 0
-- Usage: select * from scl_attendance_marks('STUDENT-ID', '2026-09-01', '2026-12-31');
create or replace function public.scl_attendance_marks(p_student text, p_from date, p_to date)
returns table (sessions int, present int, pct int, extra_marks int)
language sql stable as $$
  with t as (
    select count(*)::int as sessions,
           count(*) filter (where status <> 'absent')::int as present
    from public.student_attendance
    where student_id = p_student and attendance_date between p_from and p_to
  )
  select sessions, present,
         case when sessions = 0 then null else round(present * 100.0 / sessions)::int end,
         case when sessions = 0 then 0 else
           case
             when round(present * 100.0 / sessions) >= 90 then 10
             when round(present * 100.0 / sessions) >= 70 then 8
             when round(present * 100.0 / sessions) >= 50 then 6
             when round(present * 100.0 / sessions) >= 40 then 4
             when round(present * 100.0 / sessions) >= 30 then 3
             when round(present * 100.0 / sessions) >= 10 then 2
             when round(present * 100.0 / sessions) >= 1  then 1
             else 0 end
         end
  from t
$$;
