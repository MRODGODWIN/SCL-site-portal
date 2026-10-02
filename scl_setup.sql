-- ===================================================================
-- SCL one-time setup — run the WHOLE file in the Supabase SQL editor.
-- Gives you: (1) cloud sync for CBT/assignments/lesson notes/staff,
-- (2) student attendance table, (3) your binary-style User ID numbering.
-- Read the notes marked  >>> CHECK <<<  before running STEP 4.
-- ===================================================================

-- STEP 1: cloud sync store (CBT, assignments, submissions, lessons, staff list)
create table if not exists public.scl_app_data (
  k text primary key,
  v jsonb not null default '[]'::jsonb,
  updated_at timestamptz default now()
);
alter table public.scl_app_data enable row level security;
drop policy if exists "scl_app_data read" on public.scl_app_data;
drop policy if exists "scl_app_data write" on public.scl_app_data;
create policy "scl_app_data read"  on public.scl_app_data for select to authenticated using (true);
create policy "scl_app_data write" on public.scl_app_data for all    to authenticated using (true) with check (true);
-- Tighten to teacher/admin roles later (user_roles table) if students must not edit CBT answers.

-- STEP 2: student attendance (one row per student per register/period)
create table if not exists public.student_attendance (
  id bigserial primary key,
  attendance_date date not null,
  class_name text not null,
  period int not null default 0,          -- 0 = primary class-teacher register, 1-6 = secondary periods
  subject text, teacher_name text,
  student_id text not null, student_name text,
  status text not null check (status in ('present','absent','late','excused')),
  created_at timestamptz default now()
);
alter table public.student_attendance enable row level security;
drop policy if exists "staff insert attendance" on public.student_attendance;
drop policy if exists "staff read attendance" on public.student_attendance;
create policy "staff insert attendance" on public.student_attendance for insert to authenticated with check (true);
create policy "staff read attendance"   on public.student_attendance for select to authenticated using (true);

-- STEP 3: the binary-style number (0000..1111, 2000,2001,2010,2011,2100..2111, 2002..2222, 3000...)
create or replace function public.scl_binary_number(p_n int) returns text
language plpgsql immutable as $$
declare n int := p_n; L int; i int; a int; b int; c int; t text; bins text[]; rest text[]; cnt int;
begin
  if n < 16 then return lpad((n::bit(4))::text, 4, '0'); end if;
  n := n - 16;
  for L in 2..9 loop
    bins := '{}'; rest := '{}';
    for i in 0..((L+1)*(L+1)*(L+1)-1) loop
      a := i / ((L+1)*(L+1)); b := (i / (L+1)) % (L+1); c := i % (L+1);
      t := a::text || b::text || c::text;
      if t ~ '^[01]{3}$' then bins := bins || t; else rest := rest || t; end if;
    end loop;
    bins := bins || rest; cnt := array_length(bins, 1);
    if n < cnt then return L::text || bins[n+1]; end if;
    n := n - cnt;
  end loop;
  return (10000 + n)::text;
end $$;

-- A single school-wide counter: first come, first served — teachers, staff, admin, students alike.
create table if not exists public.scl_id_sequence (
  id int primary key default 1 check (id = 1),
  next_n int not null default 0
);
insert into public.scl_id_sequence(id,next_n) values (1,0) on conflict (id) do nothing;

create or replace function public.scl_next_school_id(p_full_name text) returns text
language plpgsql security definer set search_path = public as $$
declare n int; ini text;
begin
  update public.scl_id_sequence set next_n = next_n + 1 where id = 1 returning next_n - 1 into n;
  select string_agg(upper(left(w,1)), '') into ini
  from regexp_split_to_table(regexp_replace(coalesce(p_full_name,''), '[^A-Za-z ]', '', 'g'), '\s+') as w
  where w <> '';
  return 'SCL' || coalesce(nullif(left(ini,4),''),'XX') || public.scl_binary_number(n);   -- e.g. SCLJDP0000
end $$;

-- STEP 4 >>> CHECK <<<  Make new registrations use the numbering above.
-- The website's own function scl_register_or_join_identity already assigns school_id_number; I could not see its code.
-- This trigger overrides the number at insert time. Column names (platform_school_memberships.school_id_number,
-- platform_people.full_name) come from the website code — confirm them in Table Editor first.
create or replace function public.scl_membership_id_trigger() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.school_id_number := public.scl_next_school_id((select full_name from public.platform_people where id = new.person_id));
  return new;
end $$;
drop trigger if exists scl_membership_id on public.platform_school_memberships;
create trigger scl_membership_id before insert on public.platform_school_memberships
  for each row execute function public.scl_membership_id_trigger();

-- STEP 5 (technical admin = the FIRST number, 0000): run ONCE, with your own sign-in email.
-- update public.platform_school_memberships m
--    set school_id_number = 'SCL' || 'YOURINITIALS' || '0000'
--  where m.person_id = (select id from public.platform_people
--                        where auth_user_id = (select id from auth.users where email = 'YOUR_EMAIL_HERE'));
-- update public.scl_id_sequence set next_n = 1 where id = 1;   -- next person gets 0001
