# Log AI-Assisted Development — Minggu 9

**Nama:** Ahmad Zainudin Fanani
**NIM:** 244107020051
**Fitur:** pencarian judul catatan + empty state
**Basis proyek:** `week5_offline_notes` hasil refaktor Minggu 7, disalin dari `08-week-8-mid-project-review`
**Branch:** `feature/8-search-notes`, lalu `fix/11-search-query-lifecycle` → `develop`
**Issue:** [#8](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/issues/8), lanjutan [#11](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/issues/11)

> AI dipakai sebagai pembuat draf dan reviewer awal. Setiap baris saya baca, setiap API saya cek, dan setiap keputusan di bawah ini bisa saya jelaskan tanpa membuka AI.

---

## 1. Prompt yang dipakai

Prompt disusun dengan formula lima slot, lalu ditempeli konteks nyata dari proyek.

```text
Peran: senior Flutter developer yang disiplin pada Clean Architecture.
Konteks: project Flutter feature-first (presentation -> domain <- data),
  Riverpod 2, GoRouter, SQLite (sqflite). Fitur notes sudah punya
  Note, NoteRepository, GetNotes, AddNote, dan notesProvider
  (FutureProvider<List<Note>>). Domain tidak boleh impor Flutter.
Tugas: tambah pencarian judul catatan + empty state.
  Aturan: tidak peka huruf besar/kecil, spasi awal/akhir diabaikan,
  kata kunci kosong menampilkan semua catatan.
Batas: jangan ubah arsitektur, jangan panggil SQLite dari widget,
  jangan tambah package baru, maksimal 80 baris kode inti.
Output: potongan kode per layer + minimal 3 test case + cara uji manual.
```

Konteks yang ditempel ke AI (bukan seluruh repo, dan tanpa token/secret):

```dart
class Note {
  const Note({this.id, required this.title, this.body = '',
      required this.updatedAt, this.dirty = false});
  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}

// presentation/providers/notes_providers.dart
final notesProvider =
    FutureProvider.autoDispose<List<Note>>((ref) async { ... });
```

---

## 2. Output awal AI

Potongan inti output awal AI, apa adanya sebelum diedit:

```dart
// Draf 1 — ditaruh langsung di dalam build() NotesPage
TextField(
  onChanged: (value) {
    ref.read(notesProvider.notifier).search(value); // <-- API fiktif
  },
)

// Draf 2 — filter di widget, peka huruf besar/kecil
final results = notes.where((n) => n.title.contains(query)).toList();

// Draf 3 — saran dependency
// "Tambahkan package fuzzy untuk pencarian yang lebih pintar."

// Draf 4 — empty state
if (results.isEmpty) {
  return const Center(child: Text('Tidak ada catatan'));
}
```

Draf itu terlihat masuk akal dan hampir seluruhnya bisa dikompilasi. Masalahnya justru ada di bagian yang paling percaya diri.

---

## 3. Verifikasi dan halusinasi yang terbukti

### 3.1 `notesProvider.notifier.search()` tidak ada

Draf menganggap `FutureProvider` punya notifier dengan method `search`. Saya tidak menebak: potongan itu saya taruh apa adanya di `lib/ai_draft_probe.dart`, lalu jalankan analyzer.

```text
$ dart analyze lib/ai_draft_probe.dart
Analyzing ai_draft_probe.dart...

  error - ai_draft_probe.dart:12:28 - The getter 'notifier' isn't defined
  for the type 'FutureProvider<List<Note>>'. Try importing the library that
  defines 'notifier', correcting the name to the name of an existing getter,
  or defining a getter or field named 'notifier'. - undefined_getter

1 issue found.
```

Bukti tambahan dari `grep` pada kode nyata:

```text
$ grep -n "notifier" lib/features/notes/presentation/providers/notes_providers.dart
lib/features/notes/presentation/providers/notes_providers.dart:45:
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
```

`notesProvider` hanyalah `FutureProvider.autoDispose`; notifier yang benar-benar ada adalah `searchQueryProvider` yang saya tulis sendiri. **Keputusan:** tolak API fiktif, tulis `SearchQueryNotifier` manual.

### 3.2 Filter `contains()` yakin tapi salah

Draf kedua lolos compile dan tampak benar, tetapi gagal pada input yang wajar: `BELANJA` tidak menemukan `Belanja bulanan`. Saya buktikan dengan test, bukan dengan asumsi. Test ditulis lebih dulu, dijalankan pada implementasi draf, dan dua kasus merah:

```text
$ flutter test test/search_notes_test.dart
00:00 +0: searchNotesByTitle mengabaikan huruf besar/kecil
00:00 +0 -1: searchNotesByTitle mengabaikan huruf besar/kecil [E]
  Expected: an object with length of <2>
    Actual: []
     Which: has length of <0>

00:00 +0 -1: searchNotesByTitle mengabaikan spasi di awal dan akhir kata kunci
00:00 +0 -2: searchNotesByTitle mengabaikan spasi di awal dan akhir kata kunci [E]
  Expected: an object with length of <1>
    Actual: []
     Which: has length of <0>

00:00 +3 -2: Some tests failed.
```

Perbaikan kecil: normalisasi query **dan** judul ke huruf kecil sebelum `contains`, setelah `trim()`.

```dart
final normalizedQuery = query.trim().toLowerCase();
if (normalizedQuery.isEmpty) {
  return notes;
}
return notes
    .where((note) => note.title.toLowerCase().contains(normalizedQuery))
    .toList();
```

Hasil setelah perbaikan:

```text
$ flutter test test/search_notes_test.dart
00:00 +0: searchNotesByTitle mengabaikan huruf besar/kecil
00:00 +1: searchNotesByTitle mengabaikan spasi di awal dan akhir kata kunci
00:00 +2: searchNotesByTitle kata kunci kosong mengembalikan semua catatan
00:00 +3: searchNotesByTitle kata kunci tanpa hasil mengembalikan list kosong
00:00 +4: searchNotesByTitle mencocokkan sebagian judul, bukan hanya awalan
00:00 +5: All tests passed!
```

### 3.3 Review tahap kedua: bug siklus hidup state

Setelah fitur hijau, saya menjalankan prompt review yang diminta modul pada kode pencarian final:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

Tiga temuan yang muncul:

| ID | Level | Temuan | Keputusan |
| :---: | :--- | :--- | :--- |
| R1 | blocker | `searchQueryProvider` berumur aplikasi, sedangkan `_searchController` berumur halaman. Saat tab berpindah, halaman dibuang tetapi query tetap, sehingga daftar tersaring tanpa teks di kolom cari. | **Diterima + diperbaiki**: provider diubah ke `NotifierProvider.autoDispose`, ditambah test regresi. |
| R2 | saran | Tambahkan debounce pada `onChanged` supaya tidak memfilter tiap ketikan. | **Ditolak**: daftar sudah ada di memori dan tidak ada I/O; debounce hanya menambah delay yang terasa. |
| R3 | saran | Tambahkan widget test yang mengetik di kolom cari lalu memeriksa daftar tersaring. | **Ditolak untuk saat ini**: wiring sudah diuji manual di perangkat dan aturan filter punya 5 unit test; widget test penuh butuh fake repository/DB yang menambah setup tanpa menambah keyakinan pada aturan yang sama. |

R1 saya reproduksi di perangkat: cari `belanja`, pindah ke **Pengaturan**, lalu kembali ke **Catatan**. Hasilnya kolom cari kosong tetapi hanya dua catatan `Belanja` yang tampil. Setelah perbaikan, test regresi sempat merah pada kode lama:

```text
$ flutter test test/search_query_lifecycle_test.dart
00:00 +0: kata kunci dibuang saat tidak ada lagi yang mendengarkan [E]
  Expected: empty
    Actual: 'belanja'
00:00 +0 -1: Some tests failed.
```

lalu hijau setelah provider memakai `autoDispose`:

```text
00:00 +0: kata kunci dibuang saat tidak ada lagi yang mendengarkan
00:00 +1: All tests passed!
```

Bukti visual: [`fix_search_state_before.png`](../screenshots/fix_search_state_before.png) dan [`fix_search_state_after.png`](../screenshots/fix_search_state_after.png).

### 3.4 Cek batas layer

Domain tidak boleh menyentuh Flutter, Dio, atau SQLite. Saya cek dengan pencarian langsung, bukan hanya membaca:

```text
$ Get-ChildItem lib/features/notes/domain -Recurse -Filter *.dart |
    Select-String "package:flutter|package:dio|sqflite"
(tidak ada output)
```

`flutter analyze` juga bersih, sehingga tidak ada import lintas layer yang lolos.

---

## 4. Saran AI yang ditolak

| Saran AI | Alasan teknis penolakan | Yang dikerjakan |
| :--- | :--- | :--- |
| Tambahkan package `fuzzy` (atau `string_similarity`) untuk pencarian yang "lebih pintar". | Kebutuhan hanya *contains* pada judul yang sudah ada di memori. Menambah dependency berarti menambah permukaan risiko, ukuran build, dan perilaku yang lebih sulit dijelaskan. Untuk 5–50 catatan, pencarian eksak setelah normalisasi sudah cukup dan bisa diuji tanpa package. | Tetap pakai `String.contains` setelah `trim().toLowerCase()`. |
| Pindahkan filter ke query SQLite (`WHERE title LIKE ?`) supaya "lebih scalable". | `notesProvider` sudah memegang daftar `Note` lengkap untuk kebutuhan offline-first, dan `NoteRepository` tidak punya kontrak pencarian. Menambah query baru berarti mengubah kontrak repository + schema test, padahal UI butuh hasil instan setiap ketikan. Aturan filter juga jadi tidak bisa diuji tanpa database. | Filter di use case domain murni, di atas data yang sudah dimuat. |
| Simpan hasil pencarian di `setState` dalam `NotesPage`. | State pencarian akan hilang setiap rebuild/refresh dan tidak bisa dipakai widget lain. Ini juga mencampur aturan filter ke UI, melanggar pemisahan yang sudah dibangun Minggu 7. | `SearchQueryNotifier` + `filteredNotesProvider` di Riverpod. |
| Buat empty state langsung `Center(child: Text(...))` di halaman. | Tidak bisa diuji sendiri dan menduplikasi layout saat nanti ada empty state lain. | Widget terpisah `SearchEmptyView` + widget test. |
| Tambahkan debounce pada `onChanged` (temuan review R2). | Daftar catatan sudah ada di memori dan tidak ada I/O; debounce hanya menambah jeda yang terasa tanpa menghemat pekerjaan berarti. | Filter tetap dijalankan langsung setiap ketikan. |
| Tambahkan widget test penuh untuk alur ketik -> filter (temuan review R3). | Aturan filter sudah diuji 5 kasus dan wiring-nya diuji manual di perangkat. Widget test penuh membutuhkan fake repository/DB, menambah setup tanpa menambah keyakinan pada aturan yang sama. | Test provider siklus hidup + uji manual; widget test tetap fokus pada empty state. |

---

## 5. Keputusan per berkas

| Berkas | Keputusan | Catatan |
| :--- | :--- | :--- |
| `lib/features/notes/domain/usecases/search_notes.dart` | **Terima + refactor** | Ide AI dipakai, tapi dipindah dari widget ke fungsi domain murni dan dibuat peka huruf besar/kecil. |
| `lib/features/notes/presentation/providers/notes_providers.dart` | **Tolak draf, tulis manual** | `notesProvider.notifier.search()` tidak ada; diganti `SearchQueryNotifier` dan `filteredNotesProvider`. Setelah review tahap kedua, provider query dibuat `autoDispose`. |
| `lib/features/notes/presentation/pages/notes_page.dart` | **Terima + refactor** | Kolom cari dipakai, tetapi state diarahkan ke provider dan daftar memakai hasil `filteredNotesProvider`. |
| `lib/features/notes/presentation/widgets/search_empty_view.dart` | **Terima + rapikan** | Draf teks polos diubah jadi widget dengan ikon, pesan kata kunci, dan tombol hapus pencarian. |
| `test/search_notes_test.dart` | **Tulis manual** | Lima kasus: beda huruf, spasi, query kosong, tanpa hasil, dan kecocokan di tengah judul. |
| `test/search_empty_view_test.dart` | **Tulis manual** | Memastikan kata kunci tampil dan tombol memanggil `onClear`. |
| `test/search_query_lifecycle_test.dart` | **Tulis manual** | Regresi R1: state query harus kosong setelah listener terakhir dilepas. |
| Dependency baru (`fuzzy`, dll.) | **Tolak** | Tidak perlu untuk kebutuhan *contains* sederhana. |

---

## 6. Uji manual di perangkat

Perangkat: `2209116AG (mobile) • 5751c2fd0013 • android-arm64 • Android 13 (API 33)`.

| Skenario | Input | Hasil yang diharapkan | Status |
| :--- | :--- | :--- | :---: |
| Daftar awal | — | 5 catatan tampil, kolom cari terlihat | Lolos |
| Cocok, beda huruf | `belanja` | 2 catatan: "Belanja bulanan", "Belanja harian" | Lolos |
| Tidak cocok | `zzz` | Empty state + tombol "Hapus pencarian" | Lolos |
| Query kosong | tekan tombol hapus | Kembali ke daftar penuh, kolom cari kosong | Lolos |
| Pindah tab saat query aktif | `belanja` -> Pengaturan -> Catatan | Sebelum perbaikan: daftar tetap tersaring padahal kolom kosong. Sesudah perbaikan: seluruh catatan tampil | **Lolos setelah fix R1** |

Bukti visual ada di [`../screenshots/app_notes_home.png`](../screenshots/app_notes_home.png), [`../screenshots/app_search_results.png`](../screenshots/app_search_results.png), [`../screenshots/app_search_empty.png`](../screenshots/app_search_empty.png), [`../screenshots/fix_search_state_before.png`](../screenshots/fix_search_state_before.png), dan [`../screenshots/fix_search_state_after.png`](../screenshots/fix_search_state_after.png).

---

## 7. Quality gate mesin

Dijalankan di `09-week-9-ai-assisted-development`:

```text
$ flutter analyze
No issues found! (ran in 4.3s)

$ dart format --output=none --set-exit-if-changed .
Formatted 34 files (0 changed)

$ flutter test
00:00 +17: All tests passed!
```

Tangkapan layar: [`verif_flutter_analyze.png`](../screenshots/verif_flutter_analyze.png), [`verif_dart_format.png`](../screenshots/verif_dart_format.png), [`verif_flutter_test.png`](../screenshots/verif_flutter_test.png).

---

## 8. Refleksi

**Halusinasi yang paling menonjol** adalah `notesProvider.notifier.search()`. AI menuliskannya dengan yakin, padahal `FutureProvider` tidak punya notifier. Analyzer yang membuktikannya, bukan perasaan saya. Yang kedua lebih berbahaya karena lolos compile: filter case-sensitive. Dua test merah membuat bug itu terlihat hitam-putih.

**Prompt yang paling membantu** adalah yang menyebut batas secara eksplisit: "jangan panggil SQLite dari widget" dan "domain tidak boleh impor Flutter". Begitu batas itu disebut, draf AI langsung menaruh aturan di tempat yang lebih benar. Yang saya ubah dari prompt awal adalah menambahkan bentuk konkret `Note` dan `notesProvider`, karena tanpa itu AI mengarang nama API.

**Refactor terpenting** adalah memindahkan filter dari `build()` ke `searchNotesByTitle`. Efeknya bukan hanya lebih rapi: aturan bisnis sekarang bisa diuji lima kasus dalam hitungan milidetik, tanpa membangun widget atau database.

**Keputusan tersulit** adalah menolak pencarian berbasis SQL. Terdengar lebih "dewasa" dan scalable, tetapi untuk ukuran data aplikasi ini justru menambah jalur yang tidak perlu diuji dan memutus kontrak repository yang sudah stabil.

**Pelajaran dari review tahap kedua:** bug yang paling mengganggu justru tidak terlihat dari unit test domain. Test pencarian hijau, empty state hijau, tetapi siklus hidup state antarhalaman tetap salah. Review dengan prompt yang tepat menemukannya, dan satu test regresi kecil membuat perbaikannya bisa dibuktikan. Ini alasan saya tidak berhenti di "test hijau" — yang diuji harus mencakup perpindahan state, bukan hanya fungsi murni.
