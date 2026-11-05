---
description: Kerjakan satu GitHub Issue sampai menjadi Pull Request
---

Kerjakan issue #$ARGUMENTS.

Langkah:
1. Baca issue (`gh issue view`), `CLAUDE.md`, dan `docs/SPEC.md`.
2. Buat branch `issue-$ARGUMENTS-<slug-singkat>` dari `main`.
3. Implementasikan hanya yang diminta issue. Jangan menambah fitur lain.
4. Tulis atau perbarui test. Jalankan lint, typecheck, dan test sampai lulus. Jangan menonaktifkan test untuk meloloskan hasil.
5. Setiap tabel baru wajib RLS berbasis organisasi, dan tulis test yang membuktikan organisasi A tidak bisa membaca data organisasi B.
6. Commit dengan pesan jelas, push, lalu buka PR dengan `gh pr create`. Isi PR dengan: ringkasan dalam bahasa Indonesia sederhana (3-5 kalimat), cara mencoba hasilnya, hal yang belum selesai atau perlu keputusan pengguna, dan "Closes #$ARGUMENTS".

Aturan keras:
- Jangan merge PR sendiri dan jangan push ke `main`.
- Jangan membaca, mencetak, atau commit isi `.env*`, kunci Supabase, atau token apa pun.
- Kalau ada keputusan yang tidak jelas, tulis di PR sebagai pertanyaan dan pilih opsi paling umum. Jangan berhenti hanya karena ragu.
- Kalau terhenti lebih dari 3 kali di masalah yang sama, hentikan dan laporkan.
