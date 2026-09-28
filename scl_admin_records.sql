create extension if not exists pgcrypto;
create table if not exists public.scl_admin_records (
 id uuid primary key default gen_random_uuid(), module text not null, record_key text not null,
 data jsonb not null default '{}'::jsonb, status text not null default 'active', updated_by uuid null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(module,record_key)
);
create index if not exists scl_admin_records_module_idx on public.scl_admin_records(module);
create index if not exists scl_admin_records_status_idx on public.scl_admin_records(status);
create index if not exists scl_admin_records_updated_idx on public.scl_admin_records(updated_at desc);
alter table public.scl_admin_records enable row level security;
drop policy if exists scl_admin_records_select on public.scl_admin_records;
drop policy if exists scl_admin_records_insert on public.scl_admin_records;
drop policy if exists scl_admin_records_update on public.scl_admin_records;
drop policy if exists scl_admin_records_delete on public.scl_admin_records;
create policy scl_admin_records_select on public.scl_admin_records for select to authenticated using (coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ?| array['developer','technical_admin','management_admin','affairs_admin']);
create policy scl_admin_records_insert on public.scl_admin_records for insert to authenticated with check (coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ?| array['developer','technical_admin','management_admin','affairs_admin']);
create policy scl_admin_records_update on public.scl_admin_records for update to authenticated using (coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ?| array['developer','technical_admin','management_admin','affairs_admin']) with check (coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ?| array['developer','technical_admin','management_admin','affairs_admin']);
create policy scl_admin_records_delete on public.scl_admin_records for delete to authenticated using (coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ?| array['developer','technical_admin','management_admin','affairs_admin']);
create or replace function public.scl_admin_records_touch() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists scl_admin_records_touch on public.scl_admin_records;
create trigger scl_admin_records_touch before update on public.scl_admin_records for each row execute function public.scl_admin_records_touch();
alter table public.scl_admin_records replica identity full;
do $$ begin alter publication supabase_realtime add table public.scl_admin_records; exception when duplicate_object then null; end $$;
