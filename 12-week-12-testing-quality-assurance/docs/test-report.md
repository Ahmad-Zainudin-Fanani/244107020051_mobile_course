# Laporan Pengujian dan Jaminan Kualitas

**Proyek:** `week5_offline_notes`
**Basis:** hasil Minggu 11 (`11-week-11-performance-optimization`)
**Perangkat uji integrasi:** `2209116AG` — Android 13 (API 33), serial `5751c2fd0013`
**Flutter / Dart:** 3.47.2 / 3.13.2

Dokumen ini mencatat apa yang diuji, mengapa bagian itu dipilih, apa hasilnya,
dan apa yang belum terselesaikan. Angka cakupan dihitung ulang secara otomatis
oleh [`tools/coverage_summary.py`](tools/coverage_summary.py) menjadi
[`coverage-summary.md`](coverage-summary.md), sehingga tidak bisa "diarang"
saat laporan diperiksa.

---

## 1. Ruang lingkup

Aplikasi catatan punya tiga area besar:

| Area | Dipakai pengguna | Isi |
| :--- | :---: | :--- |
| Fitur catatan | ya | daftar, tambah, rincian, hapus, cari, sinkronisasi |
| Fitur asisten AI | ya | chat Gemini, penyimpanan API key, konteks catatan |
| Fitur Posts + `SyncService` | **tidak** | sisa eksperimen lokal, tidak dirutekan dari `main.dart` |

Prioritas pengujian mengikuti risiko, bukan jumlah baris. Fitur catatan mengatur
data pengguna, jadi kesalahan hapus atau kesalahan klaim "berhasil" berdampak
langsung. Fitur asisten menyentuh jaringan dan kredensial, jadi bagian yang
mudah diuji tanpa jaringan (kontrak, prompt, pengelolaan state) yang diuji.
Kode mati tidak diuji dan tidak dihitung — lihat bagian 9.

---

## 2. Pemilihan jenis pengujian

| Jenis | Yang diperiksa | Contoh di proyek ini | Jumlah |
| :--- | :--- | :--- | ---: |
| Unit | fungsi/objek tanpa UI | `NoteRepositoryImpl` di SQLite in-memory, `AddNote`, `validateNoteTitle`, `buildSystemPrompt` | 57 |
| Widget | tampilan + interaksi | status loading/error/kosong, form tambah, hapus, sinkronisasi | 27 |
| Integrasi | alur utuh di perangkat | tambah → rincian → cari → hapus dengan database asli | 1 |

Pembagiannya disengaja:

- **Unit** dipakai untuk aturan yang harus benar tanpa peduli tampilan. Repository
  diuji terhadap SQLite sungguhan (bukan stub) supaya SQL, urutan, dan tipe
  kolom ikut diperiksa.
- **Widget** dipakai untuk perilaku yang dilihat pengguna: pesan validasi,
  SnackBar kegagalan, keadaan kosong, dan perpindahan halaman.
- **Integrasi** hanya satu, karena biayanya paling mahal. Yang diuji adalah alur
  yang tidak bisa dibuktikan widget test: widget + provider + use case + SQLite
  perangkat bekerja bersama.

---

## 3. Inventaris pengujian

| Berkas | Test | Fokus |
| :--- | ---: | :--- |
| `test/validate_note_test.dart` | 4 | validasi judul: kosong, spasi, batas |
| `test/format_test.dart` | 2 | format tanggal |
| `test/add_note_test.dart` | 3 | use case tambah: sukses, judul kosong, repository gagal |
| `test/get_notes_test.dart` | 2 | use case daftar: sukses, failure diteruskan |
| `test/search_notes_test.dart` | 5 | pencarian: cocok judul/isi, tanpa hasil, kapital |
| `test/search_query_lifecycle_test.dart` | 1 | kata kunci dibuang saat tidak ada pendengar |
| `test/note_repository_impl_test.dart` | 13 | SQLite asli: 7 jalur sukses + 6 jalur gagal |
| `test/note_stats_provider_test.dart` | 4 | statistik total/dirty, tanpa notifikasi palsu |
| `test/notes_page_states_test.dart` | 5 | loading, error + coba lagi, kosong, statistik, pencarian |
| `test/add_note_flow_test.dart` | 6 | form tambah, input cepat, validasi, gagal simpan |
| `test/delete_note_flow_test.dart` | 6 | batal, hapus, gagal hapus, rincian, kembali |
| `test/sync_action_test.dart` | 5 | sukses, tanpa dirty, offline, dua jalur gagal |
| `test/rebuild_count_test.dart` | 1 | penjaga regresi performa Minggu 11 |
| `test/api_key_card_test.dart` | 2 | kartu API key: tampil dan simpan |
| `test/assistant_context_test.dart` | 4 | konteks catatan untuk prompt |
| `test/assistant_empty_view_test.dart` | 1 | keadaan kosong asisten |
| `test/build_system_prompt_test.dart` | 5 | penyusunan prompt sistem |
| `test/chat_controller_test.dart` | 8 | state chat: kirim, gagal, bersihkan, key |
| `test/gemini_stream_test.dart` | 6 | parsing stream Gemini |
| `test/search_empty_view_test.dart` | 1 | tampilan pencarian kosong |
| **Total** | **84** | |

Semua berkas di atas dijalankan oleh `flutter test` biasa; tidak ada test yang
butuh jaringan.

---

## 4. Dependensi yang dipisah agar bisa diuji

### 4.1 `FakeNoteRepository`

`test/support/note_fakes.dart` mengimplementasikan kontrak
`NoteRepository` dengan perilaku yang bisa diatur per test:

```dart
final repository = FakeNoteRepository(
  notes: sampleNotes(),
  deleteFailure: const LocalFailure('Database terkunci'),
);
```

Setiap metode punya *failure* sendiri (`fetchFailure`, `addFailure`,
`deleteFailure`, `countFailure`, `syncFailure`) dan penghitung panggilan
(`addCalls`, `deleteCalls`, `markAllSyncedCalls`, ...). Ini membuat dua hal
mungkin tanpa `Future.delayed`:

- memeriksa bahwa repository **tidak** dipanggil saat validasi gagal;
- mengubah kondisi di tengah test, misalnya gagal dulu lalu berhasil saat
  tombol "Coba Lagi" ditekan.

`fetchGate` (sebuah `Completer`) menahan `fetchNotes` agar indikator loading
dapat diperiksa secara deterministik.

### 4.2 Database sungguhan untuk repository

`test/note_repository_impl_test.dart` tidak memakai fake. Ia menjalankan
`sqflite_common_ffi` dengan database in-memory, lalu memakai
`createNotesSchema()` — fungsi skema yang sama dengan produksi. Jika skema
berubah tanpa migrasi, test repository gagal.

### 4.3 Harness widget

`test/support/notes_test_harness.dart` menyediakan `pumpNotesPage`,
`pumpNotesApp`, `searchFor`, dan `notesScope`. Dua keputusan penting:

- **Retry Riverpod dimatikan.** Riverpod 3 otomatis mengulang provider yang
  gagal. Tanpa `retry: (_, _) => null`, satu kegagalan bisa menjadi 11 kali
  `fetchNotes`, sehingga test menjadi tidak deterministik.
- **Debounce 250 ms dilewati eksplisit** lewat `tester.pump(300 ms)`, bukan
  `pumpAndSettle` tanpa batas.

### 4.4 `Key` untuk kontrol yang sulit dicari

Kontrol diberi `Key` agar test tidak bergantung pada teks yang bisa berubah:

`quick-add-field`, `search-field`, `sync-notes-button`, `add-note-button`,
`add-note-title`, `add-note-body`, `add-note-save`.

---

## 5. Skenario yang diperiksa

| Perilaku | Sukses | Input tidak valid | Error |
| :--- | :--- | :--- | :--- |
| Tambah catatan | tersimpan, muncul di daftar, spasi dibuang | judul kosong ditolak, repository tidak dipanggil | SnackBar, form tidak menampilkan catatan palsu |
| Hapus dari daftar | hilang dari daftar | konfirmasi "Batal" tidak menghapus | SnackBar, catatan tetap ada |
| Hapus dari rincian | kembali ke daftar + pesan sukses | — | tetap di halaman, pesan gagal, tanpa klaim sukses |
| Sinkronisasi | status jadi "Semua tersinkron" | tidak ada catatan dirty → tidak menulis | gagal hitung dan gagal tulis keduanya dilaporkan |
| Daftar catatan | 2 catatan tampil dengan badge | — | pesan + tombol "Coba Lagi" memulihkan |
| Pencarian | menyaring, menghapus filter memulihkan | tidak ada hasil → empty state | — |
| Repository SQLite | simpan/baca/urut/hapus/hitung | id tidak ada → `null` | database gagal dibuka → `Failure`, bukan exception |

---

## 6. Cacat yang ditemukan dan diperbaiki

Empat cacat berikut ditemukan **karena** menulis test, bukan karena dicari
manual. Masing-masing sekarang punya test yang gagal jika perbaikannya
dibatalkan.

### 6.1 Hapus dari daftar gagal secara diam-diam

`NotesList` memanggil `deleteNote(id)` dan langsung `invalidate` tanpa
memeriksa hasil. Jika database gagal, pengguna tidak melihat apa pun dan
mengira catatan terhapus.

**Perbaikan:** hasil `deleteNote` diperiksa; bila `failure != null`, SnackBar
merah ditampilkan dan daftar tidak di-invalidate.
**Penjaga:** `delete_note_flow_test.dart` — "kegagalan hapus dari daftar
memberi umpan balik".

### 6.2 Halaman rincian mengklaim sukses padahal gagal

Tombol hapus di `NoteDetailPage` selalu `context.pop()` lalu menampilkan
"Catatan berhasil dihapus." tanpa melihat hasil repository.

**Perbaikan:** bila gagal, halaman tetap terbuka, pesan error ditampilkan, dan
pengguna bisa mencoba lagi.
**Penjaga:** `delete_note_flow_test.dart` — "kegagalan hapus di halaman rincian
tidak mengklaim sukses".

### 6.3 Gagal menghitung catatan dilaporkan sebagai "semua tersinkron"

`_syncNotes` memakai `countResult.count` tanpa memeriksa `failure`. Saat
database gagal, `count` bernilai 0, sehingga aplikasi menampilkan
"Semua catatan sudah berstatus tersinkron." — klaim yang salah.

**Perbaikan:** failure dari `countDirty()` ditampilkan dan proses dihentikan
sebelum `markAllSynced()`.
**Penjaga:** `sync_action_test.dart` — "kegagalan menghitung catatan tidak
dilaporkan sebagai sukses".

### 6.4 Gagal menandai tersinkron dilaporkan sebagai sukses

Setelah jeda simulasi jaringan, `markAllSynced()` dipanggil tanpa memeriksa
hasil, lalu SnackBar hijau "Berhasil! Seluruh catatan telah disinkronkan."
selalu muncul.

**Perbaikan:** hasil `markAllSynced()` diperiksa; kegagalan menghasilkan
SnackBar error, dan daftar tidak di-invalidate.
**Penjaga:** `sync_action_test.dart` — "kegagalan menandai tersinkron tidak
dilaporkan sebagai sukses".

---

## 7. Pengujian integrasi

Berkas: `integration_test/app_test.dart`.

Alur yang diuji dalam satu test di perangkat:

1. aplikasi dijalankan lewat `app.main()`;
2. tambah catatan dengan judul unik berisi timestamp;
3. buka halaman rincian dan periksa isi;
4. kembali, cari judul tersebut;
5. hapus lewat long press, pastikan hilang dari daftar;
6. `tester.takeException()` harus `null`.

Dua hal yang membuat test ini stabil:

- **Judul unik per run** — tidak bergantung pada isi database perangkat.
- **Pencarian lewat `find.widgetWithText(NoteTile, title)`** — `find.text`
  menemukan dua widget karena kolom pencarian juga memuat teks yang sama. Ini
  ditemukan saat run pertama di perangkat gagal dengan "Found 2 widgets".

Perintah dan hasilnya dicatat di `README.md` bagian 6.2.

**Hasil:** `00:11 +1: All tests passed!` di `2209116AG` (Android 13). Run
pertama gagal karena bug finder di test (bukan di aplikasi), lalu diperbaiki
dan lulus. Percobaan di antaranya sempat terhalang kebijakan instalasi
HyperOS (`INSTALL_FAILED_USER_RESTRICTED`); setelah perangkat di-reboot dan
otorisasi USB diberikan, instalasi dan test berjalan normal.

---

## 8. Cakupan kode

| Ukuran | Sebelum (Minggu 11) | Sesudah |
| :--- | ---: | ---: |
| Test | 44 | **84** |
| Baris tercakup / total | 520/906 | **789/997** |
| Persentase seluruh `lib/` | 57,4% | **79,1%** |
| Persentase kode yang dijangkau aplikasi | — | **88,1%** (787/893) |
| Fitur catatan | — | **94,3%** (496/526) |

Rincian per berkas ada di [`coverage-summary.md`](coverage-summary.md).

Cakupan naik paling banyak di lapisan yang sebelumnya nol: repository
implementasi, model, provider, dan halaman. Kenaikan itu bukan tujuan, tetapi
efek samping dari menguji perilaku yang penting.

Angka 79,1% tidak dinaikkan dengan menguji kode mati. Enam berkas sisa fitur
lama (104 baris) dikecualikan dengan alasan tertulis. Jika ikut dihitung,
angkanya menjadi 88,1%.

---

## 9. Temuan yang belum terselesaikan

| Temuan | Dampak | Rencana |
| :--- | :--- | :--- |
| `SyncService`, `syncServiceProvider`, `NoteRepository` lama, `Note`/`Post` lokal, `PostsPage` tidak dipakai | kode mati, membingungkan pembaca, menurunkan cakupan | hapus pada pembersihan terpisah; dihapus dari hitungan cakupan sekarang |
| Fitur Posts tidak dirutekan | tidak bisa diuji end-to-end, tidak terlihat pengguna | putuskan: hidupkan atau hapus |
| `openNotesDb()` butuh platform channel | 7 baris `db.dart` tidak tercakup | skema sudah diuji lewat `createNotesSchema`; sisa baris hanya path database |
| Panggilan Gemini sungguhan tidak diuji | kesalahan format respons nyata tidak tertangkap | tambahkan test kontrak dengan rekaman respons (VCR) bila jaringan diizinkan |
| Cakupan integration test tidak digabung | alur perangkat tidak menambah angka `lcov` | gabungkan manual bila diperlukan; angka saat ini hanya unit + widget |
| Retry Riverpod 3 berbeda di produksi dan test | test mematikan retry, produksi memakai default | dokumentasikan; pertimbangkan `retry` eksplisit di `ProviderScope` produksi |

---

## 10. Cara mereproduksi

Dari `12-week-12-testing-quality-assurance`:

```bash
flutter pub get
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter test --coverage
python docs/tools/coverage_summary.py \
  --lcov coverage/lcov.info --out docs/coverage-summary.md
flutter test integration_test/app_test.dart -d 5751c2fd0013
```
