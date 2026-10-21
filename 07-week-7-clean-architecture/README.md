# Laporan Praktikum Minggu 7: Clean Architecture

**Nama Mahasiswa:** Ahmad Zainudin Fanani  
**NIM:** 244107020051  
**Mata Kuliah:** Pemrograman Mobile  
**Basis Proyek:** `week5_offline_notes` (Offline-First Notes with SQLite & Riverpod)  

---

## Ringkasan Proyek

Praktikum Minggu 7 berfokus pada refactoring arsitektur aplikasi mobile Flutter dari struktur lama (*layer-mixed / feature-mixed*) menuju **Clean Architecture** dengan pendekatan **Feature-First**. 

Arsitektur ini memisahkan kode ke dalam tiga layer utama:
1. **Domain:** Entitas murni, kontrak antarmuka repositori (*repository interface*), use case (interactor), dan representasi kegagalan (*failures*). Layer ini murni Dart dan tidak bergantung pada Flutter SDK, SQLite, Dio, maupun framework eksternal.
2. **Data:** Model representasi data (dengan serialisasi `toMap`, `fromMap`), implementasi repositori (*repository implementation*), serta integrasi database lokal/remote.
3. **Presentation:** Widget antarmuka pengguna (UI), state management (Riverpod Providers & Notifiers), dan perutean navigasi (*GoRouter*).

Aturan dependensi (*dependency rule*): dependensi selalu mengarah ke dalam (`Presentation` -> `Domain` <- `Data`).

---

## Praktikum 1: Audit Layer Project Lama

### 1.1 Pemetaan File ke Layer dan Masalah Arsitektur

Sebelum refactoring dilakukan, berikut audit file pada codebase awal `week5_offline_notes`:

| File | Layer Saat Ini | Masalah / Pelanggaran Arsitektur |
| :--- | :--- | :--- |
| `lib/data/local/note.dart` | Campuran Domain & Data | Kelas `Note` bertindak ganda sebagai entitas domain dan model data, memiliki method `toMap()` dan factory `fromMap()` di dalamnya. |
| `lib/data/repositories/note_repository.dart` | Data (tanpa Domain) | Interface dan implementasi SQL menyatu dalam satu kelas konkret tanpa abstraksi kontrak repositori di domain layer. |
| `lib/data/sync.dart` | Campuran Data & Presentation | Mendefinisikan Riverpod provider di layer data, menginisialisasi `Dio()` langsung, dan memadukan business logic sinkronisasi. |
| `lib/pages/notes_page.dart` | Presentation | Mengakses repositori secara langsung, menjalankan proses sinkronisasi manual (`_syncData`), dan memiliki logic build context asynchronous. |
| `lib/pages/note_detail_page.dart` | Presentation | Menampilkan formatting tanggal mentah (`DateTime.toIso8601String()`) langsung di dalam widget build. |
| `lib/widgets/note_tile.dart` | Presentation | Melakukan format tanggal `note.updatedAt.toIso8601String()` langsung di dalam widget rendering. |
| `lib/pages/posts_page.dart` | Presentation | Melakukan instansiasi manual service (`PostsSyncService(repo, ref, isOffline)`) yang membocorkan DI ke presentation. |

### 1.2 Pemeriksaan Tiga Pelanggaran Klasik (Baseline Grep)

Dilakukan pemeriksaan menggunakan static search / ripgrep pada kode awal:

1. **Akses Data Mentah/Database/Jaringan Langsung di Layer Presentation / Utility:**
   ```bash
   rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/
   ```
   *Temuan Awal:*
   - `lib/data/sync.dart:59`: `final _dio = Dio();`
   - `lib/data/prefs.dart:8,13,20`: `SharedPreferences.getInstance()`
   - `lib/data/local/db.dart:23`: `openDatabase(...)`

2. **Logika Bisnis & Formatting Tanggal Mentah di Widget/Presentation:**
   ```bash
   rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
   ```
   *Temuan Awal:*
   - `lib/widgets/note_tile.dart:20`: `note.updatedAt.toIso8601String()`
   - `lib/pages/note_detail_page.dart:70`: `note.updatedAt.toIso8601String()`

3. **Instansiasi Manual & Kebocoran Dependency Injection (DI):**
   ```bash
   rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
   ```
   *Temuan Awal:*
   - `lib/data/sync.dart`: `Provider((ref) => NoteRepository())` & `Provider((ref) => PostRepository())`
   - `lib/pages/posts_page.dart:9`: `PostsSyncService(repo, ref, isOffline)`

### 1.3 Struktur Target Clean Architecture (Feature-First)

Target reorganisasi untuk fitur `notes` adalah sebagai berikut:

```text
lib/
├── core/
│   ├── failures.dart                        # Failure domain (murni Dart)
│   └── format.dart                          # Format helper murni (tanpa widget)
├── features/
│   └── notes/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── note.dart                # Pure business entity (tanpa toMap/fromMap)
│       │   ├── repositories/
│       │   │   └── note_repository.dart     # Abstract interface/contract
│       │   └── usecases/
│       │       ├── get_notes.dart           # Use case mengambil catatan
│       │       └── add_note.dart            # Use case menambah catatan
│       ├── data/
│       │   ├── models/
│       │   │   └── note_model.dart          # Data model + mapping toMap/fromMap/toEntity
│       │   └── repositories/
│       │       └── note_repository_impl.dart# Implementasi SQLite
│       └── presentation/
│           ├── providers/
│           │   └── notes_providers.dart     # Riverpod notifier & DI wiring
│           └── pages/
│               ├── notes_page.dart          # UI murni (state-driven)
│               └── note_detail_page.dart    # UI detail catatan
└── router.dart                              # GoRouter central routing
```

### 1.4 Checklist Status & Verifikasi Praktikum 1

- [x] Kode dasar `week5_offline_notes` telah disiapkan di `07-week-7-clean-architecture/sourceCode`.
- [x] Audit layer dan tabel pemetaan masalah telah disusun di README.
- [x] Grep baseline untuk 3 pelanggaran arsitektur klasik telah dijalankan dan dicatat.
- [x] Snapshot commit Git sebelum refactor dibuat.
- [ ] **Bukti Screenshot Praktikum 1:** Menunggu konfirmasi pengguna.
