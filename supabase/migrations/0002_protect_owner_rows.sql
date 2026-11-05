-- USULAN (belum diterapkan): lindungi baris owner dan owner terakhir di `members`.
-- Setelah disetujui, pindahkan ke supabase/migrations/.
--
-- Masalah di 0001:
--  1. members_update / members_delete hanya memeriksa role *pemanggil*, bukan role
--     baris *target*. Admin bisa menurunkan role atau menghapus baris owner.
--  2. members_delete mengizinkan `user_id = auth.uid()` tanpa syarat, sehingga owner
--     terakhir bisa keluar (organisasi tanpa owner). Menurunkan diri sendiri lewat
--     UPDATE juga lolos.

-- True bila organisasi punya owner selain `excluded_user`.
-- SECURITY DEFINER agar tidak rekursif ke RLS `members`.
create function public.org_has_owner_besides(org uuid, excluded_user uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.organization_id = org
      and m.role = 'owner'
      and m.user_id <> excluded_user
  );
$$;

revoke all on function public.org_has_owner_besides(uuid, uuid) from public, anon;
grant execute on function public.org_has_owner_besides(uuid, uuid) to authenticated;

drop policy members_update on public.members;
drop policy members_delete on public.members;

-- UPDATE: pemanggil owner/admin; baris target (USING) dan hasil (WITH CHECK) yang
-- berole owner hanya boleh disentuh owner; setelah update, organisasi tetap punya owner.
create policy members_update on public.members for update to authenticated
  using (
    public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[])
    and (role <> 'owner' or public.has_org_role(organization_id, array['owner']::public.member_role[]))
  )
  with check (
    public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[])
    and (role <> 'owner' or public.has_org_role(organization_id, array['owner']::public.member_role[]))
    and (role = 'owner' or public.org_has_owner_besides(organization_id, user_id))
  );

-- DELETE: satu ekspresi tunggal (policy PERMISSIVE digabung dengan OR, jadi syarat
-- "bukan owner terakhir" harus berlaku untuk kedua jalur sekaligus).
create policy members_delete on public.members for delete to authenticated
  using (
    (role <> 'owner' or public.org_has_owner_besides(organization_id, user_id))
    and (
      user_id = (select auth.uid())
      or (
        public.has_org_role(organization_id, array['owner', 'admin']::public.member_role[])
        and (role <> 'owner' or public.has_org_role(organization_id, array['owner']::public.member_role[]))
      )
    )
  );
