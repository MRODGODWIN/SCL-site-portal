-- SCL: binary-style user ID numbers + student attendance table
-- Run in the Supabase SQL editor. Sequence: 0000..1111, 2000,2001,2010,2011,2100..2111, 2002..2222, 3000.. (same as the website preview).

create or replace function public.scl_binary_number(n int) returns text
language plpgsql immutable as $$
declare L int; cnt int; r int; a int; b int; c int; t text; k int := 0; i int; bins text[]; rest text[];
begin
  if n < 16 then return lpad((n::bit(4))::text, 4, '0'); end if;  -- 0000..1111
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

-- Example: select 'SCL' || 'JDP' || public.scl_binary_number(0);  -> SCLJDP0000 (Technical Administrator)
-- Wire it into scl_register_or_join_identity: number := scl_binary_number(count of existing memberships)

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
create policy "staff insert attendance" on public.student_attendance for insert to authenticated with check (true);
create policy "staff read attendance" on public.student_attendance for select to authenticated using (true);
-- Tighten these policies to your teacher/admin roles before going live.
