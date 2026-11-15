import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:week5_offline_notes/data/local/db.dart';
import 'package:week5_offline_notes/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  // Catatan: sqflite tidak tersedia di `flutter test` biasa karena butuh
  // platform channel. sqflite_common_ffi menjalankan SQLite asli di memori,
  // sehingga repository diuji terhadap database sungguhan, bukan stub.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late NoteRepositoryImpl repository;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        // Skema diambil dari kode produksi supaya test gagal bila skema
        // berubah tanpa migrasi.
        onCreate: (database, version) => createNotesSchema(database),
      ),
    );
    repository = NoteRepositoryImpl(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('jalur sukses', () {
    test(
      'addNote menyimpan catatan baru dan menandainya belum sinkron',
      () async {
        final result = await repository.addNote(
          title: 'Belajar pengujian',
          body: 'Unit test repository',
        );

        expect(result.failure, isNull);
        expect(result.note, isNotNull);
        expect(result.note!.id, isNotNull);
        expect(result.note!.title, 'Belajar pengujian');
        expect(result.note!.body, 'Unit test repository');
        expect(result.note!.dirty, isTrue);

        final fetched = await repository.fetchNotes();
        expect(fetched.failure, isNull);
        expect(fetched.notes, hasLength(1));
        expect(fetched.notes.single.id, result.note!.id);
      },
    );

    test('fetchNotes mengurutkan catatan dari updated_at terbaru', () async {
      await db.insert('notes', {
        'title': 'Catatan lama',
        'body': '',
        'updated_at': '2026-11-14T08:00:00.000',
        'dirty': 0,
      });
      await db.insert('notes', {
        'title': 'Catatan baru',
        'body': '',
        'updated_at': '2026-11-15T08:00:00.000',
        'dirty': 0,
      });

      final fetched = await repository.fetchNotes();

      expect(fetched.notes.map((note) => note.title), [
        'Catatan baru',
        'Catatan lama',
      ]);
    });

    test('getNote mengembalikan null bila id tidak ada', () async {
      final result = await repository.getNote(999);

      expect(result.failure, isNull);
      expect(result.note, isNull);
    });

    test('getNote mengembalikan catatan yang tersimpan', () async {
      final added = await repository.addNote(title: 'Rincian');

      final result = await repository.getNote(added.note!.id!);

      expect(result.failure, isNull);
      expect(result.note!.title, 'Rincian');
    });

    test('deleteNote menghapus catatan dari database', () async {
      final added = await repository.addNote(title: 'Akan dihapus');

      final result = await repository.deleteNote(added.note!.id!);
      final fetched = await repository.fetchNotes();

      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(fetched.notes, isEmpty);
    });

    test('countDirty hanya menghitung catatan yang belum sinkron', () async {
      await repository.addNote(title: 'Dirty 1');
      await repository.addNote(title: 'Dirty 2');
      await db.insert('notes', {
        'title': 'Sudah sinkron',
        'body': '',
        'updated_at': '2026-11-15T08:00:00.000',
        'dirty': 0,
      });

      final result = await repository.countDirty();

      expect(result.failure, isNull);
      expect(result.count, 2);
    });

    test('markAllSynced mengubah semua catatan menjadi tersinkron', () async {
      await repository.addNote(title: 'Dirty 1');
      await repository.addNote(title: 'Dirty 2');

      final result = await repository.markAllSynced();
      final after = await repository.countDirty();

      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(after.count, 0);
    });
  });

  group('jalur kegagalan database', () {
    // Setiap metode menangkap error database dan mengubahnya menjadi Failure,
    // bukan membiarkan exception naik ke UI.
    late NoteRepositoryImpl broken;

    setUp(() {
      broken = NoteRepositoryImpl(
        openDb: () async => throw StateError('database tidak dapat dibuka'),
      );
    });

    test('fetchNotes mengembalikan daftar kosong dan LocalFailure', () async {
      final result = await broken.fetchNotes();

      expect(result.notes, isEmpty);
      expect(result.failure!.message, contains('Gagal membaca catatan'));
    });

    test('addNote mengembalikan note null dan LocalFailure', () async {
      final result = await broken.addNote(title: 'Tidak tersimpan');

      expect(result.note, isNull);
      expect(result.failure!.message, contains('Gagal menyimpan catatan'));
    });

    test('getNote mengembalikan LocalFailure', () async {
      final result = await broken.getNote(1);

      expect(result.note, isNull);
      expect(result.failure!.message, contains('Gagal mengambil catatan'));
    });

    test('deleteNote melaporkan success false', () async {
      final result = await broken.deleteNote(1);

      expect(result.success, isFalse);
      expect(result.failure!.message, contains('Gagal menghapus catatan'));
    });

    test('countDirty mengembalikan 0 dan LocalFailure', () async {
      final result = await broken.countDirty();

      expect(result.count, 0);
      expect(
        result.failure!.message,
        contains('Gagal menghitung catatan belum sinkron'),
      );
    });

    test('markAllSynced melaporkan success false', () async {
      final result = await broken.markAllSynced();

      expect(result.success, isFalse);
      expect(
        result.failure!.message,
        contains('Gagal memperbarui status sinkron'),
      );
    });
  });
}
