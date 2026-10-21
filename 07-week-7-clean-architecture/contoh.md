# Week 7 - Clean Architecture & SOLID Principles

## 1. Deskripsi & Latar Belakang

Pada praktikum Week 7 ini, dilakukan refaktorisasi arsitektur perangkat lunak dari project **Week 5 (`05-week-5-local-storage-offline-first`)** menjadi **Clean Architecture** dengan pendekatan **Feature-First** dan penerapan prinsip **SOLID**.

### Mengapa Memilih Project Week 5?
Project Week 5 memiliki fitur penyimpanan catatan lokal offline (*offline-first note app*) yang memanfaatkan SQLite (`sqflite`) dan state management Riverpod. Pada implementasi awalnya di Week 5:
- Logika UI, query database, manipulasi model, dan penanganan error tercampur di dalam layer presentation (`main.dart`).
- Kelas `Note` menggabungkan identitas objek bisnis dengan logika serialisasi SQLite (`toMap` dan `fromMap`).
- Dependency Injection bocor karena widget memanggil repository secara langsung, dan repository konkret tidak memiliki abstraksi antarmuka (interface) terpisah.

### Tujuan Refactoring
1. **Separation of Concerns (SoC):** Memisahkan tanggung jawab kode ke dalam tiga layer utama: **Domain**, **Data**, dan **Presentation**.
2. **Dependency Inversion (DIP):** Mengharuskan layer Presentation dan Data bergantung pada Domain, bukan sebaliknya.
3. **Testability & Sterility:** Memastikan layer Domain murni Dart (tanpa dependensi Flutter, SQLite, Dio, atau path) sehingga business logic dapat diuji menggunakan Fake Repository dalam hitungan milidetik tanpa emulator atau database sungguhan.

---

## 2. Audit Awal (Praktikum 1)

Berikut adalah hasil audit komprehensif terhadap kode Week 5 sebelum refactoring dilakukan:

### Tabel Audit Kode Lama (Week 5)

| File Lama | Layer Saat Ini | Masalah & Pelanggaran SOLID | Target Refactor |
| :--- | :--- | :--- | :--- |
| `lib/main.dart` (`NotesTab`) | Presentation | **Pelanggaran SRP & DIP:** Widget UI memanggil `noteRepositoryProvider.add()` langsung, menangani `catch (error)` database mentah, dan memicu sinkronisasi imperatif. | Pecah ke `features/notes/presentation/pages/notes_page.dart` dan alirkan aksi melalui use case dan Notifier terisolasi. |
| `lib/main.dart` (`SettingsTab`) | Presentation | **Pelanggaran SRP:** Formatting tanggal mentah `lastOpened.toLocal().toString()` dilakukan langsung di dalam method `build()`. | Ekstrak formatting tanggal ke fungsi murni `lib/core/format.dart`. |
| `lib/data/local/note.dart` | Data / Domain (Tercampur) | **Pelanggaran SRP:** Kelas `Note` berfungsi ganda sebagai entitas bisnis sekaligus mapper SQLite (`toMap`, `fromMap`, fallback parsing). | Pisahkan menjadi entity murni `features/notes/domain/entities/note.dart` dan data model `features/notes/data/models/note_model.dart`. |
| `lib/data/repositories/note_repository.dart` | Data | **Pelanggaran DIP & OCP:** Merupakan kelas konkret langsung tanpa interface/abstraksi, mengimpor `sqflite` langsung, serta diimpor langsung oleh UI. | Buat kontrak abstrak murni `features/notes/domain/repositories/note_repository.dart` dan implementasikan di `features/notes/data/repositories/note_repository_impl.dart`. |
| `lib/data/providers.dart` | Data / Presentation (Sprawl) | **Pelanggaran DIP & ISP:** File menampung berbagai provider lintas modul (auth, posts, notes), menginstansiasi repository konkret secara langsung, dan UI mengakses repository tanpa lapisan use case. | Buat provider tersegregasi per fitur di `features/notes/presentation/providers/notes_providers.dart` dengan penyuntikan Use Case. |
| `lib/widgets/note_tile.dart` | Presentation | **Dependency Leakage:** Widget UI mengimpor `../data/local/note.dart` dan bergantung langsung pada model data. | Pindahkan ke `features/notes/presentation/widgets/note_tile.dart` dan hanya menerima domain entity `Note`. |

---

## 3. Struktur Arsitektur & Diagram Dependensi

### Diagram Alur Dependensi (The Dependency Rule)

Sesuai aturan emas Clean Architecture, dependensi kode hanya mengarah ke dalam (*inward*). Layer **Domain** berada di pusat dan tidak mengetahui layer Presentation maupun Data.

```
       +-------------------------------------------------------+
       |                  PRESENTATION LAYER                   |
       |  (UI Pages, Custom Widgets, Riverpod Notifiers & DI)  |
       +-------------------------------------------------------+
                                  |
                                  | Menggunakan / Memanggil
                                  v
+---------------------------------------------------------------------+
|                            DOMAIN LAYER                             |
|      (Entities, Use Cases, Repository Interfaces, Failures)         |
+---------------------------------------------------------------------+
                                  ^
                                  | Mengimplementasikan Kontrak
                                  |
       +-------------------------------------------------------+
       |                      DATA LAYER                       |
       |     (Models, Repository Impl, SQLite Datasource)      |
       +-------------------------------------------------------+
```

---

### Struktur Folder Feature-First

Proyek direstrukturisasi menggunakan pola **Feature-First**:

```
lib/
├── core/
│   ├── failures.dart                                # Hierarki Failure sealed class murni Dart
│   └── format.dart                                  # Helper formatting tanggal & status murni Dart (testable)
├── features/
│   ├── notes/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── note.dart                        # Entity murni Dart (tanpa Flutter/sqflite/JSON)
│   │   │   ├── repositories/
│   │   │   │   └── note_repository.dart             # Kontrak interface repository murni
│   │   │   └── usecases/
│   │   │       ├── get_notes.dart                   # Use case ambil catatan (Record sukses/gagal)
│   │   │       └── add_note.dart                    # Use case tambah catatan + validasi bisnis
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── note_model.dart                  # Model turunan entity (toMap, fromMap, toEntity)
│   │   │   └── repositories/
│   │   │       └── note_repository_impl.dart        # Implementasi konkret SQLite memenuhi kontrak domain
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── notes_providers.dart             # Riverpod Notifier, Provider wiring & Dependency Injection
│   │       ├── pages/
│   │       │   └── notes_page.dart                  # UI utama bersih tanpa SQL/Dio/JSON/Formatting mentah
│   │       └── widgets/
│   │           ├── error_view.dart                  # Widget state error interaktif
│   │           └── note_tile.dart                   # Item list catatan menggunakan domain entity
│   └── settings/
│       ├── domain/
│       │   └── repositories/
│       │       └── settings_repository.dart         # Kontrak interface preferensi pengaturan murni
│       ├── data/
│       │   └── repositories/
│       │       └── settings_repository_impl.dart    # Implementasi SharedPreferences memenuhi kontrak
│       └── presentation/
│           ├── providers/
│           │   └── settings_providers.dart          # Provider theme & force offline (steril dari SharedPreferences)
│           └── pages/
│               └── settings_page.dart               # UI menu pengaturan (tema gelap & paksa offline)
└── main.dart                                        # Inisialisasi aplikasi, NavigationBar, & ProviderScope
```

---

### Peran Masing-Masing Komponen

1. **Entity vs Model:**
   - **Entity (`domain/entities/note.dart`):** Objek inti aturan bisnis. Berisi atribut murni (`id`, `title`, `body`, `updatedAt`, `dirty`) tanpa metode serialisasi atau dependensi database.
   - **Model (`data/models/note_model.dart`):** Representasi data untuk penyimpanan. Mewarisi/memetakan entitas dengan metode `toMap()`, `fromMap()`, dan `toEntity()`. Menangani kompatibilitas tipe SQLite seperti parsing integer milliseconds dan fallback ISO 8601.

2. **Repository Interface vs Implementation:**
   - **Interface (`domain/repositories/note_repository.dart`):** Kontrak abstrak murni yang mendefinisikan apa yang dibutuhkan oleh domain bisnis (`fetchNotes`, `addNote`, `countDirty`, `syncNotes`).
   - **Implementation (`data/repositories/note_repository_impl.dart`):** Cara konkret memenuhi kontrak tersebut menggunakan SQLite (`sqflite`). Semua query, transaksi, dan penanganan exception lokal diisolasi di sini.

3. **Use Cases (`domain/usecases/`):**
   - Merepresentasikan aksi bisnis diskrit.
   - Mengembalikan Dart Record `({T data, Failure? failure})` sehingga hasil sukses dan gagal diekspresikan secara eksplisit tanpa kebocoran exception sistem ke UI.
   - `AddNote` melakukan validasi bisnis (memastikan judul tidak kosong setelah di-trim) sebelum mendelegasikan ke repository.

4. **Riverpod Dependency Injection (`presentation/providers/notes_providers.dart`):**
   - Menghubungkan implementasi data konkret ke abstraksi domain melalui provider.
   - Widget Presentation hanya membaca `notesProvider` dan `notesActionProvider` tanpa pernah membuat instansi repository secara manual (`new NoteRepository()`).

---

## 4. Hasil Verifikasi Sterilitas & Quality Gate

### 1. Verifikasi Sterilitas Presentation Layer
Pemeriksaan dilakukan untuk memastikan tidak ada pemanggilan `openDatabase`, `getDatabasesPath`, `FlutterSecureStorage`, `SharedPreferences`, atau `jsonDecode` di dalam folder presentation:
![Sterilitas Presentation Layer](./screenshots/verif_sterilisasi.png)

### 2. Verifikasi Sterilitas Domain & Core Layer
Pemeriksaan dilakukan untuk memastikan tidak ada impor `package:flutter`, `package:dio`, `package:sqflite`, atau `package:path` di dalam domain dan core:
![Sterilitas Domain & Core Layer](./screenshots/verif_sterilisasi_domain_core.png)

### 3. Static Analysis (`flutter analyze`)
![Static Analysis](./screenshots/verif_flutter_analyze.png)

### 4. Unit Testing (`flutter test`)
Pengujian use case dijalankan menggunakan Fake Repository tanpa SQLite sungguhan (`test/get_notes_test.dart`, `test/add_note_test.dart`, dan `test/format_test.dart`):
![Unit Testing](./screenshots/verif_unit_test.png)

---

## 5. AI Challenge & Refleksi Arsitektur

### AI Prompt Challenge

```text
Project Flutter saya: offline_notes (aplikasi catatan offline-first dengan SQLite dan Riverpod).
Kondisi kini: folder lib/{data, widgets, pages}, repository tercampur dengan implementasi, widget memanggil database langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture (presentation/domain/data) untuk fitur notes.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana, dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

### Tabel Perbandingan Usulan AI vs Keputusan Final

| Topik Evaluasi | Usulan AI | Keputusan Final Tim Pengembang | Alasan Teknis & Pertimbangan |
| :--- | :--- | :--- | :--- |
| **Lokasi Interface Repository** | Disarankan di `domain/repositories/` | **Diterima** | Memenuhi Dependency Inversion Principle. Domain mendikte kontrak, Data mengimplementasikan. |
| **Use Case per Operasi CRUD** | AI menyarankan membuat 5 file use case: `GetNotes`, `AddNote`, `UpdateNote`, `DeleteNote`, `SyncNotes`. | **Disederhanakan**: Hanya dibuat use case untuk aksi dengan aturan bisnis (`GetNotes` & `AddNote`), sedangkan helper sinkronisasi dikonsolidasikan. | Membuat usecase satu-baris murni passthrough untuk setiap operasi CRUD sederhana adalah over-engineering yang menambah *boilerplate* tanpa nilai tambah. |
| **Entity vs Model** | Menaruh `fromMap`/`toMap` di entity dengan alasan kemudahan. | **Ditolak tegas**: Entity dibuat murni Dart, serialisasi hanya ada di `NoteModel` pada data layer. | Jika mapping ditaruh di entity, perubahan struktur tabel database akan memaksa domain berubah, merusak sterilitas Clean Architecture. |
| **Wiring DI** | Mengusulkan package tambahan `get_it` + `injectable`. | **Ditolak**: Memanfaatkan Riverpod bawaan (`Provider` & `NotifierProvider`). | Menambah library DI pihak ketiga menambah kompleksitas kompilasi (code generation) tanpa urgensi nyata. |
| **Format & Helpers** | Disarankan menggunakan `intl` di dalam widget `build()`. | **Disederhanakan**: Diekstrak ke fungsi murni `lib/core/format.dart` tanpa dependensi eksternal. | Memungkinkan formatting tanggal dan status diuji murni lewat unit test tanpa dependensi konteks widget Flutter. |

---

### Analisis Trade-off: Kapan Use Case Satu-Baris Over-Engineering?

- **Kapan Menjadi Over-Engineering:**
  Ketika sebuah use case hanya melakukan pemanggilan satu baris langsung ke repository:
  ```dart
  // Contoh over-engineering tanpa logika bisnis:
  class DeleteNote {
    final NoteRepository repo;
    DeleteNote(this.repo);
    Future<void> call(int id) => repo.delete(id);
  }
  ```
  Pada CRUD sederhana, use case semacam ini hanya memindahkan kode tanpa menambah validasi, transformasi data, atau logika orkestrasi. Ini membebani tim dengan file berlebih (*file sprawl*), navigasi kode yang lambat, dan waktu onboarding yang tinggi.
- **Kapan Use Case Benar-Benar Dibutuhkan:**
  1. Terdapat validasi aturan bisnis sebelum pemanggilan repository (contoh: validasi input pada `AddNote`).
  2. Terdapat orkestrasi antara lebih dari satu repository (misal: mengambil user token dari `AuthRepository` lalu mengambil catatan dari `NoteRepository`).
  3. Logika bisnis perlu digunakan ulang (*reusable*) di beberapa presenter/halaman berbeda.
  4. Perlu standarisasi pemformatan error ke `Failure` sebelum mencapai UI.

---

### Refleksi

#### 1. Mengapa interface repository harus tinggal di domain, bukan di data? Apa yang rusak bila dibalik?
Jika interface diletakkan di `data`, maka layer `domain` harus mengimpor layer `data` agar bisa memanggil repository. Hal ini membalikkan arah dependensi (*Dependency Inversion terlanggar*). Akibatnya, domain akan terikat pada detail implementasi (SQLite, Dio, Firebase). Jika kita mengganti database atau framework pengujian, domain akan ikut terpengaruh dan rusak. Dengan meletakkan interface di `domain`, domain tetap menjadi pemilik kontrak, dan data layer yang tunduk pada domain.

#### 2. Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke provider sudah cukup?
- **Repository langsung ke provider cukup** ketika operasi bersifat CRUD sederhana tanpa aturan bisnis, tidak ada penggabungan sumber data, dan hanya dipanggil oleh satu controller/notifier.
- **Use case dibutuhkan** ketika terdapat logika bisnis yang harus diuji secara terisolasi (misalnya perhitungan kuota, validasi input, penggabungan cache dan jaringan, atau auditing), atau ketika use case yang sama digunakan oleh beberapa fitur berbeda (misal background worker dan UI).

#### 3. Apa biaya over-engineering bagi tim kecil vs skalabilitas?
Bagi tim kecil (1–3 developer), Clean Architecture yang terlalu kaku (*dogmatic*) menghabiskan waktu hingga 40–50% lebih banyak hanya untuk membuat boilerplate (entity, model, mapper, interface, impl, 4 use case per entitas, provider). Namun, biayanya menjadi sepadan (*worth it*) ketika:
- Proyek mulai melibatkan banyak anggota tim (mencegah *merge conflict* karena batas layer jelas).
- Aplikasi memiliki aturan bisnis kompleks yang sering berubah terlepas dari UI.
- Dibutuhkan otomatisasi testing tinggi (TDD/CI-CD) tanpa ketergantungan pada backend atau database lokal.

#### 4. Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?
1. **Penolakan `toMap`/`fromMap` di Entity:** AI sering kali tergoda menaruh factory `fromMap` di Entity demi menghemat file. Kami menolaknya karena itu melanggar aturan sterilitas domain.
2. **Penyederhanaan Jumlah Use Case:** AI mengusulkan pembuatan file terpisah untuk setiap query kecil. Kami hanya membuat use case untuk operasi utama (`GetNotes` dan `AddNote`), menjaga repository tetap bersih dan ramping.
3. **Penolakan Package DI Eksternal (`get_it`):** AI sering merekomendasikan `get_it`, padahal Riverpod sudah menyediakan *compile-time safe dependency injection* yang lebih ramah terhadap tree reactivity di Flutter.

---

## 6. Screenshot UI (Before & After)

| Kategori | Before (Week 5 - Monolithic Architecture) | After (Week 7 - Clean Architecture) |
| :--- | :---: | :---: |
| **Daftar Catatan & Badge** | ![Before Add Note](./screenshots/badge_before.png) | ![After Clean List](screenshots/badge_after.png) |
| **Tambah Catatan** | ![Before Form](./screenshots/add_note.png) | ![After Clean Add](screenshots/add_note_after.png) |
| **Mode Gelap / Tema** | ![Before Dark Mode](./screenshots/dark_mode.png) | ![After Light Mode](screenshots/dark_mode_after.png) |
| **Status Sinkronisasi** | ![Before Sync](./screenshots/note_badge_synced_on.png) | ![After Synced](screenshots/status_sinkronasi.png) |

