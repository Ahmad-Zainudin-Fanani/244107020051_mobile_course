# Verifikasi Review AI vs Keputusan Final — Minggu 8

**Nama:** Ahmad Zainudin Fanani  
**NIM:** 244107020051  
**PR yang direview:** [#2 feat(notes): validasi judul kosong terpusat + test](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/pull/2)  
**Konteks arsitektur:** feature-first Clean Architecture (`presentation -> domain <- data`), Riverpod, GoRouter, SQLite + Dio.

> AI berperan sebagai reviewer awal. Keputusan akhir, pembuktian, dan alasan penolakan tetap milik penulis. Dokumen ini menyimpan prompt, ringkasan output awal, bukti verifikasi, dan keputusan final.

---

## 1. Prompt yang Diajukan

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.

PR: feat(notes): validasi judul kosong terpusat + test
File yang berubah:
- lib/core/validation.dart (baru)
- lib/features/notes/domain/usecases/add_note.dart
- lib/features/notes/presentation/pages/notes_page.dart
- test/validate_note_test.dart (baru)

Aturan bisnis: judul catatan tidak boleh kosong. Quick-add dan modal
sama-sama menambahkan catatan. Domain tidak boleh mengimpor Flutter.
```

---

## 2. Ringkasan Output Awal AI

Output awal AI (sebelum verifikasi) memuat enam temuan:

```text
A1 [blocker] Validasi judul terduplikasi di domain dan presentation.
   Usul: jadikan satu fungsi murni dan pakai di kedua tempat.

A2 [blocker] Quick-add melakukan return tanpa pesan saat input kosong.
   Usul: tampilkan SnackBar dari hasil validasi.

A3 [saran] Hapus validasi dari domain, cukup pakai TextFormField.validator
   di UI supaya lebih ringkas dan memanfaatkan Form.

A4 [saran] Tambahkan package form_builder (atau intl) untuk validasi form
   yang lebih standar dan mudah dikembangkan.

A5 [test] Belum ada test untuk judul berisi spasi, tab, dan newline.
   Usul: tambah test kasus batas.

A6 [saran] build() NotesPage terlalu panjang; pecah menjadi beberapa widget.
```

---

## 3. Checklist Verifikasi

Sesuai checklist codelab, sebelum saran diterapkan:

- [x] **Apakah temuan benar-benar ada?** Dibuktikan dengan pencarian kode, reproduksi manual, dan test.
- [x] **Apakah usulan melanggar dependency rule?** Diperiksa: domain/core harus 0 impor Flutter/SQLite/Dio.
- [x] **Apakah AI hanya nitpick style?** Temuan style diabaikan karena sudah ditangani `dart format` + CI.
- [x] **Minimal 2 temuan AI terbukti benar dengan bukti:** A1, A2, dan A5.
- [x] **Minimal 1 temuan ditolak dengan alasan tertulis:** A3, A4, dan A6.
- [x] **Keputusan final dan alasan teknis dicatat:** tabel bagian 4.

---

## 4. Tabel Usulan AI vs Keputusan Final

| ID | Level | Usulan AI | Keputusan | Alasan teknis & bukti |
| :---: | :---: | :--- | :---: | :--- |
| A1 | Blocker | Ekstrak validasi judul ke satu fungsi murni | **Diterima** | Terbukti literal pesan ada di `add_note.dart:17` dan `notes_page.dart:340`. Setelah perbaikan hanya tersisa di `lib/core/validation.dart:8`. |
| A2 | Blocker | Tampilkan SnackBar saat quick-add kosong | **Diterima** | Reproduksi manual: menekan tombol kirim pada input kosong tidak memberi umpan balik. Setelah perbaikan muncul SnackBar (lihat `screenshots/app_validation.png`). |
| A3 | Saran | Hapus validasi domain; cukup `TextFormField.validator` | **Ditolak** | Quick-add bukan `Form`; memindahkan aturan ke UI membuat aturan bisnis hilang dari domain dan tidak dapat diuji tanpa widget. Dependency rule: domain harus tetap menjadi pemilik aturan. |
| A4 | Saran | Tambah `form_builder`/`intl` | **Ditolak** | `validateNoteTitle` hanya 8 baris dan sudah diuji. Dependensi baru menambah waktu build serta permukaan perawatan tanpa manfaat untuk satu aturan. |
| A5 | Test | Tambah test whitespace, tab, dan newline | **Diterima** | `test/validate_note_test.dart` berisi 4 test; `flutter test` lulus 10 test. |
| A6 | Saran | Pecah `build()` NotesPage menjadi widget kecil | **Ditunda** | Valid secara keterbacaan, tetapi di luar ruang lingkup PR validasi dan akan membuat diff melebar. Dicatat sebagai kandidat refactor berikutnya, bukan dipaksakan sekarang. |

**Keputusan akhir PR:** **Approve** setelah A1, A2, dan A5 diterapkan; A3, A4, dan A6 ditolak/ditunda dengan alasan di atas.

---

## 5. Bukti Penerimaan (A1, A2, A5)

### 5.1 Bukti A1 — duplikasi sebelum dan sesudah

Sebelum (project Minggu 7):

```text
07-week-7-clean-architecture/lib/features/notes/domain/usecases/add_note.dart:17:
  failure: const LocalFailure('Judul catatan tidak boleh kosong.'),
07-week-7-clean-architecture/lib/features/notes/presentation/pages/notes_page.dart:340:
  content: Text('Judul catatan tidak boleh kosong.'),
```

Sesudah (project Minggu 8):

```text
08-week-8-mid-project-review/lib/core/validation.dart:8:
  const String emptyNoteTitleMessage = 'Judul catatan tidak boleh kosong.';
```

`AddNote` dan `NotesPage` sekarang memanggil `validateNoteTitle`; tidak ada lagi literal pesan di layer presentasi.

### 5.2 Bukti A2 — umpan balik quick-add

Perilaku yang diuji:

1. Buka halaman Catatan.
2. Biarkan kolom quick-add kosong.
3. Tekan tombol kirim.

Hasil: SnackBar merah **“Judul catatan tidak boleh kosong.”** tampil, dan tidak ada catatan kosong yang tersimpan. Bukti visual: `screenshots/app_validation.png`.

### 5.3 Bukti A5 — test kasus batas

```text
flutter test
00:00 +10: All tests passed!
```

Empat test baru: judul kosong, judul berisi spasi/tab/newline, judul valid, dan judul dengan spasi di awal/akhir.

### 5.4 Bukti kepatuhan dependency rule

```powershell
Get-ChildItem -Recurse -Filter *.dart lib\features\notes\domain, lib\core |
  Select-String -Pattern "package:flutter|package:sqflite|package:dio"
# Hasil: 0 temuan
```

Fungsi validasi berada di `lib/core/validation.dart` dan hanya memakai Dart murni, sehingga tetap dapat diuji cepat tanpa emulator.

---

## 6. Saran AI yang Tidak Dipakai

### 6.1 Mengapa `TextFormField.validator` saja ditolak?

`TextFormField.validator` hanya berjalan di dalam `Form` dan membutuhkan `BuildContext`. Quick-add pada halaman catatan bukan form, sehingga aturan akan terlewat pada jalur tersebut. Jika aturan hanya hidup di UI:

- `AddNote` kehilangan validasi saat dipanggil dari tempat lain (misalnya sinkronisasi atau test domain).
- Aturan tidak dapat diuji sebagai fungsi murni.
- Lapisan domain tidak lagi menjadi penjaga kebenaran data.

Karena itu validasi tetap di domain, sedangkan UI memakai fungsi murni yang sama untuk umpan balik lebih awal.

### 6.2 Mengapa menambah `form_builder`/`intl` ditolak?

Untuk satu aturan “judul tidak boleh kosong”, dependensi baru tidak sebanding dengan manfaatnya. `dart format` dan CI sudah menangani konsistensi gaya, sedangkan pesan validasi cukup berupa konstanta di `core/validation.dart`.

### 6.3 Mengapa pemecahan `build()` ditunda?

Saran tersebut benar secara keterbacaan, tetapi tidak berhubungan dengan bug validasi. Menambahkannya ke PR ini akan memperbesar diff dan memperlambat review. Saran dicatat sebagai issue refactor berikutnya agar tetap terlacak.

---

## 7. Refleksi

Review AI paling berguna ketika diminta **membuktikan** temuan, bukan sekadar memberi opini. Dari enam temuan, tiga terbukti nyata dan langsung memperbaiki perilaku; tiga lainnya harus ditolak atau ditunda karena melanggar dependency rule, menambah dependensi tanpa manfaat, atau melebarkan ruang lingkup PR.

Pelajaran utamanya: saran AI yang paling berbahaya justru yang terlihat rapi dan masuk akal — seperti “pindahkan validasi ke form” — karena dapat merusak batas arsitektur yang sudah dibangun pada Minggu 7. Verifikasi dengan pencarian kode, test, dan reproduksi manual adalah harga yang wajib dibayar sebelum menerima saran.
