-- SCL V208: live admin-editable CMS layer
-- Run in Supabase SQL editor. Adjust role-table policy only if your project uses a different authoritative role table.
create table if not exists public.scl_site_content (
  key text primary key,
  label text not null default '',
  section text not null default 'Homepage',
  value text not null default '',
  content_type text not null default 'text',
  updated_at timestamptz not null default now(),
  updated_by uuid null references auth.users(id) on delete set null
);
create index if not exists scl_site_content_section_idx on public.scl_site_content(section);
alter table public.scl_site_content enable row level security;

-- Public read is needed so the homepage can consume published CMS values.
drop policy if exists scl_site_content_public_read on public.scl_site_content;
create policy scl_site_content_public_read on public.scl_site_content for select using (true);

-- Admin write policy. This checks JWT app_metadata first. If your project uses a different authoritative role table, replace this policy with that table's role check.
drop policy if exists scl_site_content_admin_insert on public.scl_site_content;
drop policy if exists scl_site_content_admin_update on public.scl_site_content;
drop policy if exists scl_site_content_admin_delete on public.scl_site_content;
create policy scl_site_content_admin_insert on public.scl_site_content for insert with check (coalesce(auth.jwt()->'app_metadata'->>'role','') in ('developer','technical_admin','management_admin','affairs_admin'));
create policy scl_site_content_admin_update on public.scl_site_content for update using (coalesce(auth.jwt()->'app_metadata'->>'role','') in ('developer','technical_admin','management_admin','affairs_admin')) with check (coalesce(auth.jwt()->'app_metadata'->>'role','') in ('developer','technical_admin','management_admin','affairs_admin'));
create policy scl_site_content_admin_delete on public.scl_site_content for delete using (coalesce(auth.jwt()->'app_metadata'->>'role','') in ('developer','technical_admin','management_admin','affairs_admin'));

-- Optional trigger to stamp editor identity safely.
create or replace function public.scl_site_content_set_editor() returns trigger language plpgsql as $$ begin new.updated_at=now(); new.updated_by=auth.uid(); return new; end; $$;
drop trigger if exists scl_site_content_set_editor on public.scl_site_content;
create trigger scl_site_content_set_editor before insert or update on public.scl_site_content for each row execute function public.scl_site_content_set_editor();

-- Example seed records (edit/delete these examples after confirming your real fee/account data).
-- insert into public.scl_site_content(key,label,section,value) values ('fee:account-name','Payment account name','Fees',''),('fee:account-number','Payment account number','Fees','');
