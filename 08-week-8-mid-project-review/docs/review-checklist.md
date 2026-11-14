# Checklist Review & Kesiapan Mid Project — Minggu 8

**Nama:** Ahmad Zainudin Fanani  
**NIM:** 244107020051  
**Proyek:** `week5_offline_notes` (Clean Architecture Minggu 7)  
**Branch kerja:** `feature/1-notes-validation` → `develop`  
**PR:** [#2](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/pull/2) (fitur) dan [#4](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/pull/4) (perbaikan lanjutan)

---

## 1. Audit Riwayat Git

Perintah yang dijalankan pada repository portfolio sebelum pekerjaan Minggu 8:

```bash
git log --oneline -15
git branch -a
git status
```

### 1.1 Hasil `git log --oneline -15` (kondisi awal)

```text
a92a420 docs: update week 7 status to completed in README
4deca26 feat: add clean architecture notes app with dark mode and sync settings
69d3a1a feat(ui): update notes app design and complete all before-after documentation screenshots
24d8716 fix(build): disable kotlin incremental compilation to resolve multi-drive root error on windows
c1bf6a3 docs(week7): add verification screenshots and AI challenge report
1376c29 feat(week7): implement presentation layer, Riverpod DI wiring, and clean routing (praktikum 3)
977d78c feat(week7): implement domain, data layers, and unit tests for notes feature
545646c chore: snapshot before clean architecture
78d66b0 docs: update portfolio progress for weeks 4, 5, and 6 to completed
063921b style(docs): optimize and compact screenshot display sizes in README
a8e8c49 feat(week-6): complete authentication, security, FCM, unit tests, and documentation
8922cb9 Delete Pertemuan06/ANN directory
7850c6b Praktikum5
d2db220 Delete Pertemuan06/ANN directory
33a817b Praktikum 2
```

### 1.2 Temuan Audit

| Masalah | Bukti | Tindakan |
| :--- | :--- | :--- |
| Commit tanpa tipe/scope | `Praktikum 2`, `Praktikum5` | Ditulis ulang pada tabel 2.1 dan tidak diulang pada commit baru |
| Pesan commit tidak menjelaskan isi | `Delete Pertemuan06/ANN directory` (muncul dua kali) | Ditulis ulang pada tabel 2.1; commit baru selalu menyebut apa + di mana |
| Snapshot tanpa alasan yang dapat direview | `chore: snapshot before clean architecture` | Dipertahankan sebagai titik revert, tetapi diberi konteks di laporan Minggu 7 |
| Branch hanya `main` | `git branch -a` hanya menampilkan `main` | Dibuat `develop` dan `feature/1-notes-validation` |
| Perubahan belum ter-commit | `git status` menunjukkan 3 berkas termodifikasi di Minggu 2, 3, 5 | Distash sebelum pekerjaan Minggu 8 agar PR tetap fokus; tidak dicampur ke PR #2 |

### 1.3 Hasil `git branch -a` setelah perbaikan

```text
* feature/1-notes-validation
  develop
  main
  remotes/origin/HEAD -> origin/main
  remotes/origin/develop
  remotes/origin/main
```

> Snapshot diambil saat audit. Temuan `origin/HEAD -> origin/main` langsung ditindaklanjuti: default branch diubah ke `develop`, sehingga kondisi akhirnya `origin/HEAD -> origin/develop` (diverifikasi dengan `git remote set-head origin -a`).

---

## 2. Perbaikan Pesan Commit Lama

Tiga pesan commit lama ditulis ulang ke format `tipe(scope): deskripsi`. Tabel ini disimpan sebagai bukti perbaikan, bukan dengan menulis ulang history `main` (agar riwayat yang sudah di-push tidak rusak).

| Sebelum | Sesudah | Alasan |
| :--- | :--- | :--- |
| `Praktikum 5` | `feat(notes): tambah penyimpanan lokal SQLite dan sinkronisasi offline-first` | Menyebut tipe perubahan, modul, dan hasil yang dicapai |
| `Praktikum 2` | `feat(layout): bangun dashboard responsif dengan LayoutBuilder dan MediaQuery` | Menjelaskan fitur dan teknik yang dipakai, bukan sekadar nomor pertemuan |
| `Delete Pertemuan06/ANN directory` | `chore(repo): hapus folder Pertemuan06/ANN yang tidak terpakai` | Menyebut alasan penghapusan sehingga aman di-revert/dipertanyakan |

**Prinsip yang dipakai:** satu commit = satu perubahan logis; judul menjelaskan *apa* dan *di mana*; alasan teknis ada di body PR, bukan di pesan “fix bug”.

---

## 3. Disiplin Branch & PR

- [x] `develop` dibuat sekali dari `main`, di-push, dan dijadikan default branch.
- [x] Branch fitur `feature/1-notes-validation` dibuat dari `develop`, berumur < 3 hari.
- [x] Setiap commit dapat direvert tanpa membawa perubahan fitur lain.
- [x] PR #2 menargetkan `develop`, bukan `main`; `main` tidak menerima commit langsung.
- [x] Judul PR satu fitur: `feat(notes): validasi judul kosong terpusat + test`.
- [x] Isi PR memuat masalah → solusi → cara uji → bukti screenshot.
- [x] Ukuran perubahan fitur < 300 baris (4 berkas, ±60 baris efektif); salinan baseline dipisah pada commit `chore`.
- [x] `flutter analyze`, `dart format`, dan `flutter test` hijau sebelum meminta review.
- [x] PR ditutup dengan `Closes #1`, lalu di-merge (merge commit) dan branch fitur dihapus.
- [x] Perbaikan lanjutan mengikuti alur yang sama: Issue #3 -> `fix/3-weekly-cleanup` -> PR #4 (24 baris) -> merge commit `c47a996` -> branch dihapus.
- [x] `git stash list` kosong; tidak ada perubahan lokal yang menggantung.

---

## 4. Peer Review 15 Menit (Self-Review Terstruktur)

Repositori ini individu, sehingga checklist peer review dijalankan oleh penulis sendiri dengan standar yang sama: minimal 2 temuan kebenaran, 1 temuan arsitektur, 1 temuan test, dan 1 saran keterbacaan. Setiap komentar memakai pola **observasi → dampak → usulan konkret**.

| ID | Kategori | Observasi | Dampak | Usulan konkret | Status |
| :---: | :--- | :--- | :--- | :--- | :---: |
| R1 | Kebenaran | `_handleQuickAdd` melakukan `if (text.isEmpty) return;` | Pengguna menekan kirim tetapi tidak terjadi apa-apa dan tidak tahu penyebabnya | Tampilkan SnackBar dari validator yang sama | **Selesai** |
| R2 | Kebenaran | Literal `'Judul catatan tidak boleh kosong.'` ada di `add_note.dart:17` dan `notes_page.dart:340` | Pesan dapat berbeda saat salah satu diubah; aturan tidak konsisten | Ekstrak ke `lib/core/validation.dart` | **Selesai** |
| R3 | Arsitektur | Validasi hanya dijaga `TextFormField.validator` pada usulan AI | Quick-add tidak memakai form; aturan bisnis hilang dari domain dan tidak dapat diuji tanpa widget | Pertahankan validasi domain, UI memakai fungsi murni yang sama | **Dipertahankan + diuji** |
| R4 | Test | Belum ada kasus judul berisi spasi, tab, dan newline | Regresi validasi tidak terdeteksi | Tambah `test/validate_note_test.dart` dengan 4 kasus | **Selesai** |
| R5 | Keterbacaan | Pesan error hardcoded di dua tempat | Sulit dicari dan diubah | Konstanta `emptyNoteTitleMessage` di `validation.dart` | **Selesai** |

**Keputusan akhir:** **Approve** setelah R1, R2, R4, dan R5 diperbaiki; R3 dipertahankan sebagai keputusan arsitektur dengan bukti.

### 4.1 Verifikasi Sterilitas Layer

```powershell
# Presentation tidak boleh mengakses infrastruktur langsung
Get-ChildItem -Recurse -Filter *.dart lib\features\notes\presentation, lib\pages |
  Select-String -Pattern "openDatabase|Dio\(|SharedPreferences\.getInstance|jsonDecode"
# Hasil: 0 temuan

# Domain dan core tidak boleh mengimpor framework
Get-ChildItem -Recurse -Filter *.dart lib\features\notes\domain, lib\core |
  Select-String -Pattern "package:flutter|package:sqflite|package:dio"
# Hasil: 0 temuan
```

> Catatan: `rg` tidak tersedia di lingkungan Windows ini, sehingga pemeriksaan memakai `Select-String` dengan pola yang setara.

---

## 5. Quality Gate Mesin

Dijalankan di `08-week-8-mid-project-review/sourceCode`:

| Perintah | Hasil | Bukti |
| :--- | :--- | :--- |
| `flutter analyze` | `No issues found!` | `Screenshots/verif_flutter_analyze.png` |
| `dart format --output=none --set-exit-if-changed .` | `Formatted 29 files (0 changed)` | `Screenshots/verif_dart_format.png` |
| `flutter test` | `All tests passed!` — 10 test | `Screenshots/verif_flutter_test.png` |
| GitHub Actions `ci` | Semua langkah hijau | `Screenshots/verif_ci.png` |

---

## 6. Checklist Kesiapan Tengah Semester

- [x] Struktur feature-first terbukti: `domain`, `data`, `presentation` terpisah pada `features/notes/`.
- [x] Tiga pemeriksaan mesin hijau (`analyze`, `format`, `test`).
- [x] CI menolak PR kotor sebelum dibaca manusia.
- [x] Minimal 1 issue + 1 PR kecil di-merge melalui review (Issue #1 → PR #2).
- [x] Commit jelas dan PR kecil; salinan baseline dipisah dari commit fitur.
- [x] README memuat status paruh semester, peta issue/PR, fitur, stack, cara menjalankan, dan hasil.
- [x] Screenshot aplikasi dan bukti mesin tersedia di `Screenshots/`.
- [x] Semua komentar review (R1–R5) ditindaklanjuti atau dijawab dengan alasan.
- [x] Dokumentasi prompt AI, output awal, tabel usulan-vs-keputusan, dan bukti penerimaan/penolakan tersedia di `docs/ai-review-vs-keputusan.md`.
- [x] Aplikasi berjalan identik dengan akhir Minggu 7 (hanya perilaku validasi quick-add yang diperbaiki).

---

## 7. Tindak Lanjut dan Merge

1. Author memperbaiki R1, R2, R4, R5 dan meminta re-review.
2. Re-review: `flutter analyze`, `dart format`, `flutter test`, dan uji manual quick-add kosong.
3. Merge memakai **merge commit** agar history commit baseline, fitur, CI, dan dokumentasi tetap dapat ditelusuri; squash hanya dipakai bila commit perantara berantakan.
4. PR memakai `Closes #1`; issue tertutup otomatis setelah merge.
5. Branch `feature/1-notes-validation` dihapus setelah merge agar daftar branch tetap pendek.
6. Saran AI A6 (memecah `build()` `NotesPage`) dicatat sebagai kandidat issue refactor berikutnya, bukan dipaksakan ke PR ini; R3 (validasi tetap milik domain) dipertahankan sebagai keputusan arsitektur.

---

## 8. Bukti Tambahan

| Bukti | Lokasi |
| :--- | :--- |
| Issue awal | `Screenshots/verif_issue.png` |
| Pull Request + review | `Screenshots/verif_pr.png` |
| Workflow CI | `Screenshots/verif_ci.png` |
| Aplikasi berjalan | `Screenshots/app_home.png` |
| Validasi judul kosong | `Screenshots/app_validation.png` |
| Analyze project Minggu 5 setelah perbaikan | `Screenshots/verif_fix_week5.png` |
| Issue lanjutan | https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/issues/3 |
| Pull Request lanjutan | https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/pull/4 |
