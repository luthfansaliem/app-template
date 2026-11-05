-- Uji RLS tabel `members`: perlindungan baris owner & owner terakhir.
-- Dijalankan oleh supabase/tests/run.sh pada Postgres sekali pakai (bukan project Supabase).
-- Seluruh skrip berada dalam transaksi dan di-rollback di akhir.
\set ON_ERROR_STOP on
begin;

create temp table results (name text, ok boolean, detail text);

-- Menjalankan `stmt` sebagai user `authenticated` dengan auth.uid() = uid.
-- Mengembalikan 'ok (n baris)' atau 'error: ...'. Role selalu dikembalikan.
create function pg_temp.try_as(uid uuid, stmt text) returns text
language plpgsql as $$
declare n bigint;
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  set local role authenticated;
  begin
    execute stmt;
    get diagnostics n = row_count;
    reset role;
    return format('ok (%s baris)', n);
  exception when others then
    reset role;
    return 'error: ' || sqlerrm;
  end;
end $$;

create function pg_temp.check(p_name text, p_ok boolean, p_detail text default null)
returns void language sql as $$
  insert into results values (p_name, coalesce(p_ok, false), p_detail);
$$;

-- ------------------------------------------------------------ fixture
-- Org A: owner1, owner2 (owner), admin1, member1.  Org B: solo, Org C: solo2 (masing-masing owner tunggal).
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'owner1@test'),
  ('00000000-0000-0000-0000-0000000000a2', 'owner2@test'),
  ('00000000-0000-0000-0000-0000000000a3', 'admin1@test'),
  ('00000000-0000-0000-0000-0000000000a4', 'member1@test'),
  ('00000000-0000-0000-0000-0000000000b1', 'solo@test'),
  ('00000000-0000-0000-0000-0000000000c1', 'solo2@test'),
  ('00000000-0000-0000-0000-0000000000a5', 'member2@test'),
  ('00000000-0000-0000-0000-0000000000a6', 'member3@test');

insert into public.organizations (id, name, slug, created_by) values
  ('00000000-0000-0000-0000-00000000000a', 'Org A', 'org-a', null),
  ('00000000-0000-0000-0000-00000000000b', 'Org B', 'org-b', null),
  ('00000000-0000-0000-0000-00000000000c', 'Org C', 'org-c', null);

insert into public.members (organization_id, user_id, role) values
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a1', 'owner'),
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a2', 'owner'),
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a3', 'admin'),
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a4', 'member'),
  ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-0000000000b1', 'owner'),
  ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-0000000000c1', 'owner'),
  -- member2 di Org A; admin1 juga admin di Org B (agar pemindahan baris lolos RLS tanpa trigger)
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a5', 'member'),
  ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-0000000000a3', 'admin'),
  ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a6', 'member');

-- ---------------------------------------------- 1. admin vs baris owner
select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ update public.members set role = 'member'
      where user_id = '00000000-0000-0000-0000-0000000000a2' $q$) as hasil \gset
select pg_temp.check('1a. admin TIDAK bisa menurunkan role owner',
  (select role from public.members where user_id = '00000000-0000-0000-0000-0000000000a2') = 'owner',
  :'hasil');

select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ delete from public.members
      where user_id = '00000000-0000-0000-0000-0000000000a2' $q$) as hasil \gset
select pg_temp.check('1b. admin TIDAK bisa menghapus baris owner',
  exists (select 1 from public.members where user_id = '00000000-0000-0000-0000-0000000000a2'),
  :'hasil');

-- kontrol: admin tetap boleh mengelola member biasa
select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ update public.members set role = 'admin'
      where user_id = '00000000-0000-0000-0000-0000000000a4' $q$) as hasil \gset
select pg_temp.check('1c. (kontrol) admin masih bisa mengubah role member',
  (select role from public.members where user_id = '00000000-0000-0000-0000-0000000000a4') = 'admin',
  :'hasil');
select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ delete from public.members
      where user_id = '00000000-0000-0000-0000-0000000000a4' $q$) as hasil \gset
select pg_temp.check('1d. (kontrol) admin masih bisa menghapus member',
  not exists (select 1 from public.members where user_id = '00000000-0000-0000-0000-0000000000a4'),
  :'hasil');

-- ------------------------------------------------ 2. owner terakhir
select pg_temp.try_as('00000000-0000-0000-0000-0000000000b1',
  $q$ delete from public.members
      where user_id = '00000000-0000-0000-0000-0000000000b1' $q$) as hasil \gset
select pg_temp.check('2a. owner terakhir TIDAK bisa keluar sendiri',
  exists (select 1 from public.members where user_id = '00000000-0000-0000-0000-0000000000b1'),
  :'hasil');

select pg_temp.try_as('00000000-0000-0000-0000-0000000000c1',
  $q$ update public.members set role = 'member'
      where user_id = '00000000-0000-0000-0000-0000000000c1' $q$) as hasil \gset
select pg_temp.check('2b. owner terakhir TIDAK bisa menurunkan diri sendiri',
  (select role from public.members where user_id = '00000000-0000-0000-0000-0000000000c1') = 'owner',
  :'hasil');

-- kontrol: owner boleh keluar bila masih ada owner lain
select pg_temp.try_as('00000000-0000-0000-0000-0000000000a1',
  $q$ delete from public.members
      where user_id = '00000000-0000-0000-0000-0000000000a1' $q$) as hasil \gset
select pg_temp.check('2c. (kontrol) owner boleh keluar bila ada owner lain',
  not exists (select 1 from public.members where user_id = '00000000-0000-0000-0000-0000000000a1'),
  :'hasil');

-- ------------------------------------- 3. organization_id / user_id terkunci
-- (butuh migrasi 0003; admin1 adalah admin di Org A dan Org B)
select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ update public.members
      set organization_id = '00000000-0000-0000-0000-00000000000b'
      where user_id = '00000000-0000-0000-0000-0000000000a5' $q$) as hasil \gset
select pg_temp.check('3a. organization_id TIDAK bisa diubah (pindah org)',
  exists (select 1 from public.members
          where user_id = '00000000-0000-0000-0000-0000000000a5'
            and organization_id = '00000000-0000-0000-0000-00000000000a'),
  :'hasil');

select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ update public.members
      set user_id = '00000000-0000-0000-0000-0000000000c1'
      where user_id = '00000000-0000-0000-0000-0000000000a6'
        and organization_id = '00000000-0000-0000-0000-00000000000a' $q$) as hasil \gset
select pg_temp.check('3b. user_id TIDAK bisa diubah',
  exists (select 1 from public.members
          where user_id = '00000000-0000-0000-0000-0000000000a6'
            and organization_id = '00000000-0000-0000-0000-00000000000a'),
  :'hasil');

-- trigger berlaku untuk semua peran, termasuk superuser/service role
do $$
declare msg text := 'tidak ada error';
begin
  begin
    update public.members set user_id = '00000000-0000-0000-0000-0000000000c1'
      where user_id = '00000000-0000-0000-0000-0000000000a6'
        and organization_id = '00000000-0000-0000-0000-00000000000a';
  exception when others then
    msg := sqlerrm;
  end;
  insert into results values ('3c. superuser pun TIDAK bisa mengubah user_id',
    msg like '%immutable%', msg);
end $$;

-- kontrol: mengubah role tetap boleh (1c menguji jalur RLS; ini memastikan trigger tidak
-- ikut memblokir UPDATE yang tidak menyentuh kolom terkunci)
select pg_temp.try_as('00000000-0000-0000-0000-0000000000a3',
  $q$ update public.members set role = 'admin'
      where user_id = '00000000-0000-0000-0000-0000000000a5' $q$) as hasil \gset
select pg_temp.check('3d. (kontrol) ubah role tetap jalan setelah trigger',
  (select role from public.members where user_id = '00000000-0000-0000-0000-0000000000a5') = 'admin',
  :'hasil');

-- ------------------------------------------------------------ laporan
select case when ok then 'PASS' else 'FAIL' end as status, name, detail from results order by name;

do $$
begin
  if exists (select 1 from results where not ok) then
    raise exception '% test gagal', (select count(*) from results where not ok);
  end if;
end $$;

rollback;
