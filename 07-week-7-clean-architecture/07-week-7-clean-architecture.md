## 1. Selamat datang

**Terakhir diperbarui:** 27 September 2026

[Bahasa Indonesia](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html) | [English](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index-en.html)

## Tujuan pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa mampu:

- menjelaskan prinsip SOLID dan separation of concerns dengan contoh kode Flutter;
- membedakan struktur feature-first vs layer-first beserta trade-off-nya;
- menjelaskan tiga layer (presentation, domain, data) dan aturan dependensi (dependensi mengarah ke dalam);
- membedakan entity vs model serta peran repository, use case, dan dependency injection;
- merefactor project Minggu 5/6 menjadi struktur feature-first yang terpisah layer-nya;
- menguji use case dengan repository palsu tanpa database atau jaringan sungguhan.

## Persiapan

- Laptop/PC dan repository portfolio (GitHub/GitLab) berisi project Minggu 5 (`week5_offline_notes`) atau Minggu 6 (`campus_notify`). Codelab ini merefactor project tersebut, bukan membuat dari nol.
- Flutter SDK, VS Code (ekstensi Flutter/Dart), emulator atau perangkat fisik.
- Pemahaman Minggu 3 (Riverpod, AsyncValue, GoRouter), Minggu 4 (repository pattern, Dio), dan Minggu 5–6 (SQLite, secure storage).

**Kebijakan AI.** Minggu 7 adalah materi lanjutan: AI boleh mengusulkan reorganisasi project, tetapi Anda wajib menilai trade-off-nya (mis. over-engineering untuk fitur kecil), memutuskan struktur final sendiri, dan menjelaskan setiap keputusan. Nilai ada pada justifikasi arsitektur, bukan pada kerapian folder hasil AI.

[**Back**](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html# "Previous step")

## 2. Konsep SOLID dan Clean Architecture

### 2.1 SOLID dalam satu contoh Flutter

Lima prinsip, masing-masing satu kalimat plus gejala pelanggarannya:

| Prinsip | Arti praktis | Gejala pelanggaran di Flutter |
| --- | --- | --- |
| **S**ingle Responsibility | Satu kelas punya satu alasan berubah | Widget 400 baris yang sekaligus fetch API, parsing JSON, dan formatting tanggal |
| **O**pen/Closed | Tambah perilaku lewat ekstensi, bukan edit kode lama | Setiap sumber data baru memaksa edit widget yang sudah jalan |
| **L**iskov Substitution | Pengganti harus bisa menggantikan aslinya tanpa merusak | Repository palsu untuk test malah melempar error yang tak pernah dilempar repository asli |
| **I**nterface Segregation | Jangan paksa klien bergantung pada yang tak dipakai | Satu interface raksasa `AppRepository` untuk auth + notes + push sekaligus |
| **D**ependency Inversion | Bergantung pada abstraksi, bukan concretion | Notifier memanggil `Dio` / `sqflite` langsung alih-alih repository |

### 2.2 Tiga layer dan aturan dependensi

```text
presentation (widget, notifier, router)
      |
      v  bergantung ke
domain (entity, repository interface, use case, failure)
      ^
      |  diimplementasikan oleh
data (model, repository impl, Dio, SQLite, secure storage)
```

Aturan emas (**dependency rule**): dependensi hanya mengarah ke dalam. `domain` tidak tahu apa pun tentang Flutter, Dio, atau SQLite — sehingga logika bisnis bisa diunit-test murni.

### 2.3 Feature-first vs layer-first

| Struktur | Bentuk | Kapan dipakai |
| --- | --- | --- |
| `feature-first` | `lib/features/notes/{data,domain,presentation}` | Project multi-fitur (pilihan codelab ini): satu fitur bisa dipahami/dihapus tanpa menyentuh fitur lain |
| `layer-first` | `lib/{data,domain,presentation}` global | Project kecil satu fitur; cepat tapi berantakan saat fitur bertambah |

### 2.4 Kosakata peran

- **Entity:** objek bisnis murni (tanpa `toMap/fromMap/toJson`). Hidup di `domain`.
- **Model:** representasi data luar (JSON/SQLite) + mapping ke entity. Hidup di `data`.
- **Repository interface:** kontrak yang dibutuhkan domain (mis. `fetchNotes()`). Hidup di `domain`.
- **Repository impl:** cara memenuhi kontrak memakai Dio/SQLite. Hidup di `data`.
- **Use case:** satu operasi bisnis (mis. `GetNotes`, `SyncNotes`). Hidup di `domain`, dipanggil presentation.
- **DI:** penyuntikan dependensi lewat provider Riverpod (atau `get_it`). Widget tidak pernah `new Repository()` sendiri.

**Bukan sekadar pindah folder.** Memindahkan file tanpa memutus dependensi terlarang (widget → Dio, notifier → SQLite) bukan Clean Architecture. Yang dinilai adalah arah panah dependensi, bukan kedalaman folder.

## 3. Praktikum 1: Audit layer project lama

### 3.1 Petakan file ke layer

Buka project Minggu 5 atau 6 Anda dan isi tabel ini di README (contoh untuk `campus_notify`):

| File | Layer saat ini | Masalah |
| --- | --- | --- |
| `pages/home_page.dart` | presentation | memanggil Dio langsung? memformat tanggal + parsing JSON di widget? |
| `data/api_client.dart` | data | OK bila hanya dipakai repository, bukan widget |
| `providers/auth_provider.dart` | presentation (state) | OK bila hanya memanggil repository/use case |
| `data/auth_repository.dart` | data (+kontrak tercampur) | interface dan implementasi masih satu kelas |

### 3.2 Tandai tiga pelanggaran klasik

Cari dengan grep di project Anda:

```bash
# Widget yang menyentuh jaringan / database langsung
rg "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets

# Logika bisnis di dalam build()
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets

# Instansiasi manual (DI bocor)
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
```

Setiap temuan adalah satu item refactor. Target: ketiga pencarian di atas **nol hasil** di folder presentation setelah Praktikum 3.

### 3.3 Gambar struktur target

Untuk satu fitur (`notes` atau `announcements`):

```text
lib/
├── core/
│   ├── failures.dart        # Failure domain (murni Dart)
│   └── providers.dart       # (opsional) provider lintas fitur
├── features/
│   └── notes/
│       ├── domain/
│       │   ├── entities/note.dart
│       │   ├── repositories/note_repository.dart  # interface!
│       │   └── usecases/get_notes.dart
│       │   └── usecases/add_note.dart
│       ├── data/
│       │   ├── models/note_model.dart
│       │   └── repositories/note_repository_impl.dart
│       └── presentation/
│           ├── providers/notes_providers.dart     # notifier + DI
│           └── pages/notes_page.dart
└── routes.dart              # GoRouter + konstanta rute
```

**Jangan buat fitur baru.** Praktikum ini memindahkan dan memisahkan kode yang sudah ada dan sudah jalan. Commit sebelum refactor (`git commit -m "chore: snapshot before clean architecture"`) agar bisa dibandingkan dan di-rollback.

## 4. Praktikum 2: Domain dan data per fitur

### 4.1 Entity murni (domain)

Buat `lib/features/notes/domain/entities/note.dart`. Tanpa import Flutter, tanpa mapping:

```dart
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}
```

### 4.2 Failure dan kontrak repository (domain)

Buat `lib/core/failures.dart` dan `lib/features/notes/domain/repositories/note_repository.dart`:

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
```

```dart
import '../../domain/entities/note.dart';
import '../../../../core/failures.dart';

abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });
}
```

Contoh memakai *record* Dart agar sukses/gagal eksplisit tanpa exception bocor ke presentation. Alternatif industri: package `fpdart`/`dartz` (`Either<Failure, T>`) — pola kontraknya sama.

### 4.3 Model dan implementasi (data)

Buat `lib/features/notes/data/models/note_model.dart` (mapping hanya di sini) dan `note_repository_impl.dart`:

```dart
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body = '',
    required super.updatedAt,
    super.dirty = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  Note toEntity() => Note(
        id: id,
        title: title,
        body: body,
        updatedAt: updatedAt,
        dirty: dirty,
      );
}
```

```dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required Future<Database> Function() openDb})
      : _openDb = openDb;

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows =
          await db.query('notes', orderBy: 'updated_at DESC');
      final notes =
          rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
            title: title, body: body, updatedAt: now, dirty: true)
            .toMap(),
      );
      return (
        note: Note(id: id, title: title, body: body,
            updatedAt: now, dirty: true),
        failure: null,
      );
    } catch (e) {
      return (note: null,
          failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }
}
```

### 4.4 Use case: satu operasi bisnis

Buat `lib/features/notes/domain/usecases/get_notes.dart`:

```dart
import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  const GetNotes(this._repository);
  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call() {
    return _repository.fetchNotes();
  }
}
```

**Kapan use case perlu?** Bila operasi menggabungkan >1 repository atau punya aturan bisnis (validasi, sorting, sync). CRUD satu-baris boleh langsung repository → notifier; use case menjadi wajib saat logika tumbuh. Keputusan ini bagian dari AI Challenge.

## 5. Praktikum 3: Presentation, DI, dan verifikasi

### 5.1 Dependency injection dengan Riverpod

Buat `lib/features/notes/presentation/providers/notes_providers.dart`. Inilah satu-satunya tempat wiring:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/entities/note.dart';

// Data layer: database opener disuntikkan (mudah diganti fake saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});
```

### 5.2 Halaman hanya membaca state

`notes_page.dart` versi bersih tidak mengandung SQL, Dio, JSON, atau formatting tanggal mentah:

```dart
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : NotesList(notes),
    );
  }
}
```

### 5.3 Verifikasi dependency rule

Jalankan tiga pemeriksaan ini; semuanya harus lolos:

```bash
# 1. Presentation steril dari data mentah (harus NOL hasil)
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages

# 2. Domain steril dari framework & package (harus NOL hasil)
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core

# 3. Static analysis + test
flutter analyze
flutter test
```

**Definisi selesai.** Refactor dinyatakan selesai bila: aplikasi berjalan sama seperti sebelum refactor (uji manual 5 menit tiap fitur), tiga grep di atas nol hasil, `flutter analyze` bersih, dan test hijau. Screenshot before/after (UI sama, struktur beda) masuk folder `screenshots/`.

## 6. AI Challenge

### Peran AI pada codelab ini

AI boleh mengusulkan reorganisasi folder, tetapi **Anda yang menilai trade-off-nya**. Arsitektur yang salah (over-engineering untuk CRUD sederhana, atau under-engineering untuk fitur kompleks) lebih mahal daripada kode yang jelek.

### AI Prompt Challenge

Minta AI coding assistant dengan prompt berikut:

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

### AI Verification Checklist

Sebelum usulan AI diterima, verifikasi dan catat temuan di README/docs:

- Apakah interface repository tinggal di `domain` dan implementasi di `data`? (tolak bila AI menaruh keduanya di satu folder).
- Apakah `domain` bebas import Flutter/Dio/SQLite/Firebase? Periksa dengan grep, bukan dengan membaca sekilas.
- Apakah AI membuat use case untuk tiap CRUD satu-baris? (itu over-engineering: cukup repository langsung ke notifier, dengan alasan tertulis).
- Apakah entity bebas mapping (`toMap/fromMap/toJson` hanya di model)?
- Apakah wiring DI terpusat di provider dan widget tidak `new Repository()` sendiri?
- Keputusan final dan alasan teknis Anda, boleh berbeda dari saran AI selama berargumen.

**Tanggung jawab teknis:** simpan prompt, output awal AI, tabel usulan-vs-keputusan-final, dan hasil tiga grep verifikasi pada folder `docs/`. Saat demo Anda harus mampu menggambar arah panah dependensi tanpa membuka catatan.

## 7. Refactoring, testing, dan error umum

### 7.1 Refactoring Challenge

1. Terapkan pola yang sama ke fitur kedua (`auth` atau `announcements`): entity + repository interface + impl + 1 use case + provider wiring. Jangan biarkan satu fitur bersih dan sisanya kotor.
2. Ekstrak formatting tanggal dan parsing rute ke fungsi murni di `lib/core/format.dart` agar bisa diuji tanpa widget.
3. Pindahkan semua exception mentah menjadi `Failure` yang ramah pengguna sebelum mencapai UI; UI hanya menerima `message`.

### 7.2 Testing: use case dengan repository palsu

Buat `test/get_notes_test.dart`. Domain diuji murni — tanpa SQLite, tanpa Dio, tanpa Firebase:

```dart
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (notes: items, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('GetNotes meneruskan daftar dari repository', () async {
    final repo = FakeNoteRepository(items: [
      Note(title: 'A', updatedAt: DateTime(2026, 9, 27)),
    ]);
    final result = await GetNotes(repo).call();
    expect(result.failure, isNull);
    expect(result.notes.length, 1);
    expect(result.notes.first.title, 'A');
  });

  test('GetNotes meneruskan failure tanpa melempar', () async {
    final repo = FakeNoteRepository(fail: true);
    final result = await GetNotes(repo).call();
    expect(result.failure, isA<LocalFailure>());
    expect(result.notes, isEmpty);
  });
}
```

Jalankan:

```bash
flutter analyze
flutter test
```

### 7.3 Error umum dan solusinya

| Gejala | Penyebab umum | Solusi |
| --- | --- | --- |
| Import cycle / file saling mengimpor | Presentation diimpor oleh domain/data, atau feature mengimpor antar-presentation | Periksa arah panah: hanya presentation → domain ← data; fitur berkomunikasi via rute, bukan import widget |
| `The argument type 'NoteModel' can't be assigned to 'Note'` | Repository impl mengembalikan model, kontrak meminta entity | Selalu konversi `.toEntity()` di batas data → domain |
| Provider `ref.watch` di luar widget/provider | Wiring DI ditulis di fungsi biasa atau constructor | Wiring hanya di dalam `Provider/Notifier` atau widget via `ConsumerWidget` |
| Test butuh database sungguhan | Use case diuji dengan `NoteRepositoryImpl` asli | Uji domain selalu dengan fake yang mengimplementasikan interface |
| Refactor merusak fitur yang sudah jalan | Tidak ada snapshot commit + tidak ada uji manual per fitur | Commit snapshot dulu; setelah refactor uji tiap fitur ±5 menit dan bandingkan screenshot |

### 7.4 Checklist verifikasi mandiri

- Tiga grep sterilitas (presentation & domain) nol hasil.
- Interface di domain, implementasi di data, mapping hanya di model.
- Widget tidak menginstansiasi repository; semua lewat provider.
- Aplikasi berjalan identik sebelum/sesudah refactor (bukti screenshot).
- `flutter analyze` bersih dan semua test lulus.

## 8. Tugas, refleksi, dan referensi

### 8.1 Mini project / Industry Challenge

Refactor project Minggu 5 atau 6 Anda menjadi **Clean Architecture feature-first** (lanjutkan repository yang sama, bukan project baru):

1. Minimal 1 fitur penuh (`notes` atau `announcements`) terpisah menjadi `domain/` (entity, repository interface, use case, failure) + `data/` (model, repository impl) + `presentation/` (provider wiring, pages).
2. Dependency rule terbukti: sertakan hasil tiga grep sterilitas di README.
3. Behavior identik: screenshot before/after tiap fitur di folder `screenshots/`.
4. Sertakan minimal 2 test yang lulus (use case sukses + failure dengan repository palsu).
5. Kerjakan AI Challenge dan dokumentasikan prompt, tabel usulan-vs-keputusan-final, dan alasan teknis di `docs/`.
6. Push ke repository portfolio pada folder `07-week-7-clean-architecture/` (atau lanjutkan folder minggu asal + catat refactor di README) dengan struktur `lib/`, `test/`, `docs/`, `README.md`, dan `screenshots/`. README menjelaskan tujuan, diagram layer + arah dependensi, fitur utama, stack teknologi, cara menjalankan, dan hasil yang dicapai.

### 8.2 Refleksi

- Mengapa interface repository harus tinggal di domain, bukan di data? Apa yang rusak bila dibalik?
- Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke notifier sudah cukup?
- Apa biaya over-engineering (use case per CRUD satu-baris) bagi tim kecil? Kapan biayanya sepadan?
- Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?

### 8.3 Referensi pendukung

- [Slide Week 7: Clean Architecture](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_07_Clean_Architecture.html)
- [Flutter: App architecture guide](https://docs.flutter.dev/app-architecture/guide)
- [The Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/clean-architecture.html)
- [Riverpod: Providers & dependency injection](https://riverpod.dev/docs/concepts/providers)
- [Dart: Records (return ganda sukses/gagal)](https://dart.dev/language/records)
- [fpdart package (alternatif Either)](https://pub.dev/packages/fpdart)
- [GoRouter: redirect & deep linking](https://go_router.dev/)
- [Learn Dart in Y Minutes](https://learnxinyminutes.com/docs/dart/)
