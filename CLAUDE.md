# CLAUDE.md

Template aplikasi web multi-tenant: Next.js (App Router) + TypeScript + Tailwind CSS + Supabase (cloud).

## Perintah

Package manager: **pnpm** (versi dipin lewat `packageManager` di `package.json`). Node 22.

```bash
pnpm install          # pasang dependensi
pnpm dev              # dev server di http://localhost:3000
pnpm lint             # ESLint
pnpm typecheck        # tsc --noEmit
pnpm test             # Vitest, sekali jalan (dipakai CI)
pnpm test:watch       # Vitest mode watch
pnpm build            # build produksi (output: standalone)
```

Sebelum menganggap pekerjaan selesai, `pnpm lint && pnpm typecheck && pnpm test` harus lolos. CI (`.github/workflows/ci.yml`) menjalankan ketiganya pada push/PR ke `main`.

Menjalankan satu test: `pnpm vitest run tests/slug.test.ts` atau `pnpm vitest run -t "nama test"`.

Jika Node belum terpasang di mesin, jalankan lewat Docker, misalnya:
`docker run --rm -v "$PWD":/app -w /app node:22-alpine sh -c "corepack enable && pnpm test"`.

## Setup lokal

1. `cp .env.example .env.local`, isi `NEXT_PUBLIC_SUPABASE_URL` dan `NEXT_PUBLIC_SUPABASE_ANON_KEY` dari Supabase Cloud (Project Settings → API).
2. Jalankan `supabase/migrations/0001_init_multitenant.sql` di SQL Editor Supabase Cloud (atau `supabase db push` bila CLI terpasang dan project sudah di-link).
3. Di Supabase: Authentication → URL Configuration, tambahkan `http://localhost:3000/auth/callback` ke Redirect URLs. Untuk uji coba cepat, konfirmasi email boleh dimatikan.

## Arsitektur

- **Tenant lewat path**: `/[orgSlug]/...` (bukan subdomain). `src/app/[orgSlug]/layout.tsx` memuat organisasi berdasarkan slug; karena RLS, organisasi yang bukan milik user tidak ditemukan dan menghasilkan 404.
- **Rute**: `/` (redirect ke org pertama atau `/onboarding`), `/login` (email + password, login & daftar), `/auth/callback` (konfirmasi email), `/onboarding` (buat organisasi), `/[orgSlug]/dashboard` (kosong).
- **Auth**: `@supabase/ssr` dengan sesi di cookie. `src/proxy.ts` (konvensi Next 16, pengganti `middleware.ts`) me-refresh sesi dan me-redirect user yang belum login ke `/login`. Logika keputusan redirect ada di `resolveRedirect` (`src/lib/supabase/proxy.ts`) agar bisa di-test.
- **Klien Supabase**: `src/lib/supabase/server.ts` (Server Components/Actions), `client.ts` (browser), `proxy.ts` (proxy).
- **Database** (`supabase/migrations/`): `profiles` (1:1 dengan `auth.users`, dibuat otomatis oleh trigger), `organizations`, `members` (`role`: owner | admin | member). Organisasi dibuat lewat RPC `create_organization(p_name, p_slug)` yang sekaligus menjadikan pembuatnya `owner`.
- **Tipe DB** ditulis manual di `src/lib/types/database.ts`. Perbarui bersamaan dengan migrasi (atau ganti dengan hasil `supabase gen types`).

## Aturan proyek

- TypeScript strict; jangan pakai `any` atau `@ts-ignore` tanpa alasan tertulis.
- Setiap tabel baru yang berisi data tenant **wajib** punya kolom `organization_id`, RLS aktif, dan policy berbasis `is_org_member` / `has_org_role`. Jangan pernah membuat tabel tenant tanpa RLS.
- Isolasi tenant bergantung pada RLS, bukan filter di kode aplikasi. Jangan memakai service-role key di kode yang berjalan di browser, dan hindari memakainya di server kecuali benar-benar perlu.
- Di server, gunakan `supabase.auth.getUser()` (memvalidasi token), bukan `getSession()`, untuk keputusan otorisasi.
- Slug organisasi: huruf kecil/angka/tanda hubung, 3–40 karakter, dan bukan kata yang dicadangkan (`login`, `auth`, `onboarding`, `api`, `dashboard`, `_next`). Daftar ini ada di `src/lib/slug.ts` dan di constraint migrasi; ubah keduanya bersamaan saat menambah rute top-level baru.
- Perubahan skema = file migrasi baru bernomor (`0002_...sql`). Jangan mengedit migrasi yang sudah diterapkan.
- Komponen default Server Component; pakai `"use client"` hanya bila perlu. Mutasi lewat Server Actions.
- Next.js 16: `params` adalah `Promise` (gunakan `await`). Dokumentasi versi terpasang ada di `node_modules/next/dist/docs/`.
- Jangan commit `.env*` (kecuali `.env.example`).

## Test

- Lokasi: `tests/**/*.test.{ts,tsx}`; Vitest + jsdom + Testing Library; alias `@/` → `src/`.
- Test yang ada mencakup helper murni (slug, validasi kredensial, keputusan redirect proxy) dan render form login (Server Actions di-mock).
- Policy RLS **belum** punya test otomatis dan tidak dijalankan di CI. Verifikasi manual terhadap project Supabase: login sebagai dua user di organisasi berbeda dan pastikan tidak saling melihat data.

## Deploy (Docker)

```bash
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx \
  -t app-template .
docker run -p 3000:3000 app-template
```

`NEXT_PUBLIC_*` di-inline saat build, jadi harus diberikan sebagai build arg. Nilainya publik, bukan secret. Image memakai build standalone dan berjalan sebagai user non-root.
