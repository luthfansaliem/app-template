-- Multi-tenant core: profiles, organizations, members + RLS.
-- Apply via Supabase Cloud SQL Editor or `supabase db push`.

create type public.member_role as enum ('owner', 'admin', 'member');

-- ---------------------------------------------------------------- tables
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  email      text,
  full_name  text,
  created_at timestamptz not null default now()
);

create table public.organizations (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 100),
  slug       text not null unique
             check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'
                    and char_length(slug) between 3 and 40
                    and slug not in ('login', 'auth', 'onboarding', 'api', 'dashboard', '_next')),
  created_by uuid references auth.users (id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

create table public.members (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  role            public.member_role not null default 'member',
  created_at      timestamptz not null default now(),
  unique (organization_id, user_id)
);

create index members_user_id_idx on public.members (user_id);

-- --------------------------------------------------------------- helpers
-- SECURITY DEFINER so policies can consult `members` without recursing into its own RLS.
create function public.is_org_member(org uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.organization_id = org and m.user_id = (select auth.uid())
  );
$$;

create function public.has_org_role(org uuid, roles public.member_role[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.organization_id = org
      and m.user_id = (select auth.uid())
      and m.role = any (roles)
  );
$$;

create function public.shares_org_with(other uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.members a
    join public.members b on a.organization_id = b.organization_id
    where a.user_id = (select auth.uid()) and b.user_id = other
  );
$$;

revoke all on function public.is_org_member(uuid) from public, anon;
revoke all on function public.has_org_role(uuid, public.member_role[]) from public, anon;
revoke all on function public.shares_org_with(uuid) from public, anon;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.has_org_role(uuid, public.member_role[]) to authenticated;
grant execute on function public.shares_org_with(uuid) to authenticated;

-- Create a profile row for every new auth user.
create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Create an organization and make the caller its owner, atomically.
create function public.create_organization(p_name text, p_slug text)
returns public.organizations language plpgsql security definer set search_path = '' as $$
declare
  org public.organizations;
begin
  if (select auth.uid()) is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  insert into public.organizations (name, slug, created_by)
  values (p_name, p_slug, (select auth.uid()))
  returning * into org;

  insert into public.members (organization_id, user_id, role)
  values (org.id, (select auth.uid()), 'owner');

  return org;
end;
$$;

revoke all on function public.create_organization(text, text) from public, anon;
grant execute on function public.create_organization(text, text) to authenticated;

-- ------------------------------------------------------------------- RLS
alter table public.profiles      enable row level security;
alter table public.organizations enable row level security;
alter table public.members       enable row level security;

-- profiles: self, or people who share an organization with you
create policy profiles_select on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.shares_org_with(id));
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- organizations: inserts only through create_organization()
create policy organizations_select on public.organizations for select to authenticated
  using (public.is_org_member(id));
create policy organizations_update on public.organizations for update to authenticated
  using (public.has_org_role(id, array['owner', 'admin']::public.member_role[]))
  with check (public.has_org_role(id, array['owner', 'admin']::public.member_role[]));
create policy organizations_delete on public.organizations for delete to authenticated
  using (public.has_org_role(id, array['owner']::public.member_role[]));

-- members: visible to org members; managed by owner/admin; only owners grant 'owner'
create policy members_select on public.members for select to authenticated
  using (public.is_org_member(organization_id));
create policy members_insert on public.members for insert to authenticated
  with check (
    public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[])
    and (role <> 'owner' or public.has_org_role(organization_id, array['owner']::public.member_role[]))
  );
create policy members_update on public.members for update to authenticated
  using (public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[]))
  with check (
    public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[])
    and (role <> 'owner' or public.has_org_role(organization_id, array['owner']::public.member_role[]))
  );
create policy members_delete on public.members for delete to authenticated
  using (
    user_id = (select auth.uid())
    or public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[])
  );
