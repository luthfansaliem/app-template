-- Kunci `organization_id` dan `user_id` di `members` agar tidak bisa diubah lewat UPDATE.
--
-- Policy members_update (0002) hanya memeriksa role. Tanpa pengunci ini, admin yang
-- juga admin di organisasi lain bisa memindahkan baris anggota antar organisasi, atau
-- mengganti `user_id` sebuah baris. Untuk memindahkan anggota: hapus lalu insert baru.
--
-- Berlaku untuk semua peran (termasuk service role); ubah role tetap diizinkan.

create function public.members_lock_identity()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.organization_id is distinct from old.organization_id
     or new.user_id is distinct from old.user_id then
    raise exception 'members.organization_id and members.user_id are immutable'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger members_lock_identity
  before update of organization_id, user_id on public.members
  for each row execute function public.members_lock_identity();
