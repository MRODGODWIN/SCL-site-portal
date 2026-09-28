-- SCL V210 — administrator identity / provisioning foundation
-- Run after reviewing the role-table names used by the existing project.
create table if not exists public.scl_admin_accounts (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('management_admin','affairs_admin')),
  email text not null,
  full_name text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','DISABLED')),
  auth_user_id uuid,
  provisioned_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_password_change_at timestamptz
);
create unique index if not exists scl_admin_accounts_one_active_role
  on public.scl_admin_accounts(role) where status='ACTIVE';
create unique index if not exists scl_admin_accounts_email_unique
  on public.scl_admin_accounts(lower(email));

alter table public.scl_admin_accounts enable row level security;

-- The browser must not create or modify privileged admin records directly.
-- Provisioning and password-state changes are performed by the Edge Function using service-role credentials.
drop policy if exists "scl_admin_accounts_no_client_write" on public.scl_admin_accounts;

-- Admins may read the provisioning roster; write operations stay server-side.
drop policy if exists "scl_admin_accounts_admin_read" on public.scl_admin_accounts;
create policy "scl_admin_accounts_admin_read"
on public.scl_admin_accounts for select to authenticated
using (
  coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ? 'developer'
  or coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ? 'technical_admin'
  or coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ? 'management_admin'
  or coalesce(auth.jwt()->'app_metadata'->'roles','[]'::jsonb) ? 'affairs_admin'
);

-- Optional helper view for the technical admin control panel.
create or replace view public.scl_admin_account_status as
select role,email,full_name,status,auth_user_id,provisioned_by,created_at,updated_at,last_password_change_at
from public.scl_admin_accounts;
