# Temuan Profiling — Minggu 11

Dokumen ini mencatat **baseline** dan masalah performa yang benar-benar terukur
pada aplikasi `week5_offline_notes` sebelum optimasi. Semua angka berasal dari
pengukuran di perangkat, bukan perkiraan.

- **Perangkat:** `2209116AG` (Android 13, API 33, arm64)
- **Flutter:** 3.47.2 / Dart 3.13.2
- **Mode:** `flutter drive --profile` (bukan debug, karena mode debug punya
  overhead besar dan tidak representatif)
- **Data uji:** 1.500 catatan diseed langsung ke SQLite oleh
  `integration_test/perf_test.dart`

## 1. Cara mengukur ulang

```bash
cd 11-week-11-performance-optimization/sourceCode

# Profiling CPU + memori (hasil JSON ditulis ke build/integration_response_data.json)
flutter drive --profile --no-dds -d 5751c2fd0013 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/perf_test.dart

# Hitungan rebuild widget
flutter test test/rebuild_count_test.dart
```

`--no-dds` wajib dipakai. Tanpa flag itu `watchPerformance` gagal karena DDS
memblokir koneksi VM Service dari dalam aplikasi:

```text
Bad state: Failed to connect to VM Service at ws://localhost:60989/...
This may happen if DDS is enabled. If this test was launched via
`flutter drive`, try adding `--no-dds`.
```

Data mentah baseline disimpan di [`measurements/baseline.json`](measurements/baseline.json).

## 2. Baseline

Skenario yang diukur (sama untuk sebelum dan sesudah):

1. Buka daftar 1.500 catatan.
2. Fling daftar 6 kali.
3. Fling balik, buka detail catatan, kembali.
4. Cari `belanja`, lalu kosongkan.
5. Ketik `rencana rapat` karakter per karakter (13 karakter, 50 ms/karakter).
6. Buka-tutup halaman detail 5 kali untuk melihat pertumbuhan memori.

### 2.1 Frame time

| Metrik | Baseline |
| :--- | ---: |
| Frame build rata-rata | 1,167 ms |
| Frame build p90 | 3,413 ms |
| Frame build p99 | 8,858 ms |
| Frame build terburuk | 12,491 ms |
| Frame build melewati budget | 0 dari 447 |
| Frame raster rata-rata | 3,774 ms |
| Frame raster p90 | 4,186 ms |
| Frame raster terburuk | **33,829 ms** |
| Frame raster melewati budget | 3 dari 447 |
| New gen GC / old gen GC | 22 / 8 |

Catatan penting: rata-rata terlihat sehat, tetapi **frame raster terburuk
33,8 ms** berarti ada frame yang butuh dua kali budget 60 FPS. Itu penyebab
jank yang terasa saat scroll, dan rata-rata menyembunyikannya.

### 2.2 Rebuild widget

`test/rebuild_count_test.dart` menghitung setiap elemen yang dibangun ulang
lewat `debugOnRebuildDirtyWidget` selama 13 ketikan:

| Metrik | Baseline |
| :--- | ---: |
| Rebuild `NotesPage` | 13 (1 per ketikan) |
| Rebuild `NoteTile` | 78 |
| **Total rebuild** | **5.052** |
| Rata-rata per ketikan | **388,6** |

### 2.3 Memori

| Metrik | Baseline |
| :--- | ---: |
| RSS sebelum 5x buka-tutup detail | 236 MB |
| RSS sesudah 5x buka-tutup detail | 240 MB |
| Selisih | +3 MB |

## 3. Temuan

### Temuan 1 — Satu ketikan membangun ulang seluruh halaman

`NotesPage.build` mengamati tiga provider sekaligus:

```dart
final notesAsyncValue = ref.watch(notesProvider);
final filteredNotesAsyncValue = ref.watch(filteredNotesProvider);
final searchQuery = ref.watch(searchQueryProvider);
```

Akibatnya setiap karakter yang diketik membangun ulang `Scaffold`, `AppBar`,
kolom input cepat, kolom pencarian, dan seluruh daftar: **388 elemen per
ketikan** (5.052 untuk 13 ketikan). Hanya `ListView` dan item yang terlihat
yang benar-benar perlu berubah.

### Temuan 2 — Penyaringan dan statistik dihitung berulang tanpa jeda

Masih di `build` yang sama:

```dart
final notesList = notesAsyncValue.value ?? [];
final dirtyCount = notesList.where((n) => n.dirty).length;
```

Dua masalah:

1. `where(...).length` memindai 1.500 catatan **setiap rebuild**, termasuk
   setiap ketikan.
2. `filteredNotesProvider` memanggil `searchNotesByTitle` (lowercase + `contains`
   untuk 1.500 judul) pada **setiap karakter**, tanpa debounce. Mengetik
   13 karakter = 13 penyaringan penuh, padahal pengguna hanya butuh hasil
   akhirnya.

### Temuan 3 — `IntrinsicHeight` dan `ClipRRect` pada setiap item

`NoteTile` membungkus isinya dengan:

```dart
ClipRRect(
  child: IntrinsicHeight(
    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, ...),
  ),
)
```

- `IntrinsicHeight` memaksa **dua kali layout** untuk setiap item: sekali untuk
  mengukur tinggi intrinsik, sekali lagi untuk layout sebenarnya. Biaya ini
  dibayar ulang setiap kali item masuk viewport saat scroll.
- `ClipRRect` membuat **satu `saveLayer`** per item pada raster thread.

Keduanya menjelaskan frame raster terburuk 33,8 ms, sementara build thread
relatif aman (0 frame melewati budget).

### Temuan 4 — Daftar mengelola seluruh 1.500 item sekaligus

`ListView.builder` sudah lazy (ini bagus), tetapi `itemCount` langsung 1.500
dan setiap item dibungkus `AutomaticKeepAlive` secara default. Tidak ada
pagination, sehingga daftar tidak punya batas kerja per halaman dan tidak ada
cara memuat bertahap.

### Temuan 5 — Memori: tidak ada kebocoran yang terdeteksi

RSS hanya naik 3 MB setelah 5 kali buka-tutup halaman detail, dan turun lagi
setelah GC. `TextEditingController` di `NotesPage` sudah di-`dispose()`.
Karena itu Minggu 11 **tidak** melakukan perubahan memori yang dipaksakan;
fokusnya di CPU dan raster. Ini juga contoh menghindari optimasi prematur.

### Yang sengaja tidak dioptimasi

| Kategori modul | Keputusan | Alasan |
| :--- | :--- | :--- |
| Optimasi gambar | Dilewati | Aplikasi tidak menampilkan gambar jaringan sama sekali; tidak ada `Image.network`/aset besar untuk di-resize atau di-cache |
| Caching jaringan | Tidak diubah | Fitur catatan sepenuhnya lokal (SQLite); halaman Posts sudah memakai cache-first sejak Minggu 5 |
| Pagination server | Tidak relevan | Tidak ada endpoint daftar catatan; data berasal dari SQLite lokal |

Melaporkan kategori yang tidak relevan lebih jujur daripada menambahkan
`CachedNetworkImage` pada aplikasi yang tidak punya gambar.

## 4. Rencana perbaikan

| # | Temuan | Optimasi | Target terukur |
| :--- | :--- | :--- | :--- |
| 1 | Temuan 1 | Pecah halaman menjadi `NotesAppBar`, `QuickAddBar`, `NoteSearchField`, `NotesList`; hanya subtree terdampak yang mengamati provider | Rebuild `NotesPage` = 0 saat mengetik |
| 2 | Temuan 1 & 2 | `noteStatsProvider` turunan + `select` untuk total/dirty | Pindai 1.500 catatan hanya saat data berubah |
| 3 | Temuan 2 | Debounce 250 ms sebelum `searchQueryProvider` diperbarui | 13 penyaringan → 1 penyaringan |
| 4 | Temuan 3 | Hapus `IntrinsicHeight` dan `ClipRRect`; aksen kiri jadi `Positioned` | Layout satu kali per item, tanpa `saveLayer` |
| 5 | Temuan 4 | Pagination 60 item + `addAutomaticKeepAlives: false` | Daftar mengelola maksimal 60 item per halaman |
