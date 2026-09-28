create table if not exists public.scl_activity_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  actor_user_id uuid null,
  actor_name text null,
  actor_email text null,
  actor_role text null,
  action text not null,
  entity_type text null,
  entity_id text null,
  status text not null default 'RECORDED',
  details jsonb not null default '{}'::jsonb
);
create index if not exists scl_activity_log_created_at_idx on public.scl_activity_log(created_at desc);
create index if not exists scl_activity_log_actor_idx on public.scl_activity_log(actor_user_id);

alter table public.scl_activity_log enable row level security;

-- Replace this role expression with the authoritative role source used by your SCL project.
create policy "admins can read activity log"
on public.scl_activity_log for select
to authenticated
using (
  coalesce((auth.jwt()->'app_metadata'->>'role'),'') in ('developer','technical_admin','management_admin','affairs_admin')
  or exists (
    select 1 from public.scl_staff s
    where s.auth_user_id = auth.uid()
      and lower(coalesce(s.role,'')) in ('developer','technical_admin','management_admin','affairs_admin')
  )
);

-- Enable Realtime for the live admin table.
alter table public.scl_activity_log replica identity full;
alter publication supabase_realtime add table public.scl_activity_log;
