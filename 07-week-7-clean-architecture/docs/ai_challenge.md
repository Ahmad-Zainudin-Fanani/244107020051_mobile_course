# Laporan AI Challenge: Clean Architecture & SOLID Principles

**Nama Mahasiswa:** Ahmad Zainudin Fanani  
**NIM:** 244107020051  
**Proyek:** `week5_offline_notes` -> Clean Architecture Refactoring  
**Mata Kuliah:** Pemrograman Mobile  

---

## 1. Prompt AI Challenge

Prompt yang diajukan kepada AI Coding Assistant untuk menganalisis dan mengusulkan arsitektur sistem:

```text
Proyek Flutter saya: week5_offline_notes (aplikasi catatan offline-first dengan SQLite dan Riverpod).
Kondisi awal: struktur folder lib/{data, widgets, pages}, kelas repositori bercampur dengan implementasi basis data, dan widget UI berinteraksi langsung dengan database.

Tugas Arsitektur:
1. Rancang struktur Feature-First Clean Architecture (presentation, domain, data) khusus untuk modul catatan (notes).
2. Tentukan disposisi untuk setiap file lama (pemisahan, pemindahan, atau eliminasi).
3. Evaluasi potensi over-engineering pada operasi CRUD sederhana dan tentukan batas kapan use case mutlak diperlukan vs akses repositori langsung.
4. Peragakan konfigurasi Dependency Injection memanfaatkan kemampuan bawaan Riverpod tanpa paket pihak ketiga tambahan.
Jelaskan alasan dan trade-off di balik setiap keputusan rancangan.
```

---

## 2. Ringkasan Respons Awal AI

Asisten AI memberikan usulan perancangan awal sebagai berikut:
1. **Pemisahan Modul Fitur:** Mengusulkan restrukturisasi penuh ke dalam folder `features/notes/` yang membagi kode ke dalam subfolder `domain/`, `data/`, dan `presentation/`.
2. **Generasi Banyak Use Case:** AI merekomendasikan untuk membuat file terpisah bagi setiap fungsi CRUD: `GetNotes`, `AddNote`, `UpdateNote`, `DeleteNote`, dan `SyncNotes`.
3. **Penyatuan Mapping di Entity:** AI menyarankan untuk mempertahankan method `toMap()` dan constructor factory `fromMap()` langsung di dalam kelas `Note` domain untuk kepraktisan penulisan kode.
4. **Saran Pustaka DI Eksternal:** AI menyarankan penggunaan package `get_it` yang dipadukan dengan code generator `injectable` untuk menangani *Service Locator* dan *Dependency Injection*.
5. **Pemformatan Tanggal:** AI menyarankan penggunaan pustaka `intl` langsung di dalam method `build()` pada widget presentasi.

---

## 3. Checklist Verifikasi Teknis Terhadap Usulan AI

| Kriteria Pemeriksaan Arsitektur | Status Evaluasi | Catatan & Verifikasi Pengembang |
| :--- | :---: | :--- |
| Apakah antarmuka (*interface*) repositori berada di `domain` dan implementasi konkret di `data`? | **LOLOS** | Usulan AI disetujui. Interface murni berada di `domain/repositories/` dan implementasi SQLite berada di `data/repositories/`. |
| Apakah layer `domain` steril dari impor framework (`flutter`, `dio`, `sqflite`, `firebase`)? | **LOLOS DENGAN KOREKSI** | Pengembang memastikan domain 100% murni Dart. Anjuran AI untuk mengimpor package serialisasi dibatalkan. |
| Apakah entity bebas dari method mapping (`toMap`/`fromMap`)? | **DIKOREKSI** | Usulan AI yang menyatukan mapper di entity ditolak tegas. Mapper hanya diizinkan di `NoteModel` pada lapisan `data`. |
| Apakah AI membuat use case untuk operasi CRUD satu-baris tanpa logika bisnis? | **DISEDERHANAKAN** | Disederhanakan. Operasi passthrough murni tidak dibuatkan file use case tersendiri untuk mencegah *file sprawl*. |
| Apakah injeksi dependensi terpusat tanpa widget memanggil `new Repository()`? | **LOLOS** | Seluruh dependensi di-wiring melalui provider Riverpod bawaan tanpa membutuhkan package tambahan. |

---

## 4. Tabel Komparasi: Usulan AI vs Keputusan Teknis Final

| Aspek Evaluasi | Rekomendasi Asisten AI | Keputusan Teknis Final | Argumentasi & Rasionalisasi Rekayasa |
| :--- | :--- | :--- | :--- |
| **Lokasi Interface Repositori** | Diletakkan di `domain/repositories/`. | **Diterima Penuh** | Menerapkan *Dependency Inversion Principle* (DIP). Domain berdaulat menentukan kontrak kebutuhan, sedangkan lapisan data berkewajiban memenuhinya. |
| **Granularitas File Use Case** | Membuat 5 file use case terpisah untuk setiap aksi CRUD: `GetNotes`, `AddNote`, `UpdateNote`, `DeleteNote`, dan `SyncNotes`. | **Disederhanakan Secara Selektif**: Hanya aksi dengan aturan bisnis (`GetNotes` & `AddNote`) yang dibuatkan berkas Use Case. | Membuat use case satu baris yang sekadar memanggil method repositori (*pure passthrough*) pada CRUD sepele adalah *over-engineering* yang menambah boilerplate tanpa nilai fungsional. |
| **Pemisahan Entitas vs Model Data** | Menaruh `toMap`/`fromMap` di dalam kelas entitas agar ringkas. | **Ditolak Keras**: Entitas murni Dart; seluruh konversi data diisolasi pada `NoteModel` di layer data. | Jika method serialisasi ditaruh di entity, perubahan struktur skema SQLite akan memaksa domain berubah, merusak sterilitas Clean Architecture. |
| **Pustaka Dependency Injection** | Mengusulkan penambahan package `get_it` + `injectable`. | **Ditolak**: Mengoptimalkan kemampuan bawaan Riverpod (`Provider`, `NotifierProvider`). | Menambah pustaka DI pihak ketiga menambah ketergantungan eksternal dan memperlambat kompilasi karena kebutuhan *code generation* yang tidak esensial. |
| **Pemformatan Waktu & Helper** | Menggunakan package `intl` langsung di dalam method `build()` widget. | **Disederhanakan**: Mengekstrak formatting ke fungsi murni di `lib/core/format.dart`. | Memungkinkan pemformatan waktu diuji secara mandiri melalui *unit test* murni tanpa membutuhkan instansiasi widget Flutter. |

---

## 5. Analisis Trade-off: Menilai Batas *Over-Engineering*

### Kapan Use Case Satu-Baris Tergolong *Over-Engineering*?
Ketika use case hanya berisi pemanggilan passthrough tanpa logika validasi, transformasi, atau koordinasi:
```dart
// Contoh over-engineering yang tidak menambah nilai bisnis:
class DeleteNote {
  final NoteRepository repository;
  DeleteNote(this.repository);
  Future<void> call(int id) => repository.deleteNote(id);
}
```
Pada aplikasi berskala kecil hingga menengah, pembuatan berkas seperti di atas meningkatkan kompleksitas navigasi (*file sprawl*), memperlambat *onboarding*, dan menambah *mental overhead* bagi pengembang.

### Kapan Use Case Menjadi Mutlak Dibutuhkan?
1. **Validasi Aturan Bisnis:** Sebelum diteruskan ke repositori, data harus diverifikasi integritasnya (contoh: validasi judul tidak boleh kosong pada `AddNote`).
2. **Orkestrasi Multi-Sumber Data:** Terdapat koordinasi antar lebih dari satu repositori (misal mengambil kredensial sesi dari `AuthRepository` sebelum menyinkronkan data di `NoteRepository`).
3. **Penggunaan Ulang Logika (*Reusability*):** Logika bisnis yang sama dipanggil dari berbagai tempat berbeda (seperti widget antarmuka dan *background periodic task*).
4. **Standardisasi Penanganan Error:** Mengonversi galat tingkat rendah dari infrastruktur menjadi objek bisnis terstandar (`Failure`) sebelum disajikan ke lapisan UI.

---

## 6. Refleksi Kritis Arsitektural

### 1. Mengapa antarmuka repositori wajib diletakkan di domain dan bukan di data? Apa yang rusak bila posisinya dibalik?
Jika antarmuka diletakkan di lapisan `data`, maka lapisan `domain` terpaksa mengimpor lapisan `data` untuk dapat mengakses repositori tersebut. Hal ini membalikkan arah panah ketergantungan yang benar (*Dependency Inversion Principle dilanggar*). Akibatnya, domain akan terikat pada detail infrastruktur (misalnya SQLite atau Dio). Apabila teknologi penyimpanan diganti atau dimutakhirkan, domain akan ikut rusak. Dengan meletakkan antarmuka di `domain`, domain memegang kendali atas kontrak yang harus dipenuhi oleh lapisan data.

### 2. Kapan use case benar-benar bernilai tambah vs kapan pemanggilan repositori langsung via provider sudah memadai?
Pemanggilan repositori secara langsung via provider Riverpod sudah memadai untuk operasi CRUD pembacaan/penulisan langsung yang tidak memerlukan transformasi data dan hanya dikonsumsi oleh satu widget atau presenter. Sementara itu, use case menjadi mutlak saat ada komputasi bisnis, validasi masukan, atau kebutuhan pengujian independen tingkat domain (*domain unit test*).

### 3. Apa biaya over-engineering bagi tim kecil vs skalabilitas jangka panjang?
Bagi tim kecil (1–3 orang), arsitektur yang terlalu kaku dapat menghabiskan waktu awal hingga 40% lebih banyak hanya untuk menulis kode boilerplate (entitas, model, mapper, interface, implementasi, use case, dan provider). Namun, biaya ini menjadi sangat berharga ketika aplikasi mulai berkembang, anggota tim bertambah, dan terdapat kebutuhan pipeline CI/CD dengan pengujian unit otomatis yang cepat.

### 4. Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?
1. **Penolakan Mapper di Entity:** AI menyarankan factory `fromMap` di Entity demi kesederhanaan. Keputusan ini ditolak karena mencemari kemurnian domain.
2. **Eliminasi Use Case Satu-Baris:** Kami menolak membuat berkas use case untuk seluruh fungsi CRUD sederhana dan memfokuskan use case hanya pada aksi yang memiliki aturan bisnis nyata.
3. **Penolakan DI Eksternal (`get_it`):** AI merekomendasikan `get_it`, padahal Riverpod sudah menyediakan *compile-time safe dependency injection* yang lebih ramah terhadap arsitektur reaktif Flutter.
