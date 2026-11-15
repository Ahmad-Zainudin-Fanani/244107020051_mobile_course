import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

/// Repository palsu: test ini hanya mengukur rebuild, bukan database.
class _NoopNoteRepository implements NoteRepository {
  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: const <Note>[], failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (note: null, failure: null);

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async =>
      (note: null, failure: null);

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async =>
      (success: true, failure: null);

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async =>
      (success: true, failure: null);
}

List<Note> _seedNotes(int count) {
  const titles = [
    'Rencana rapat mingguan',
    'Belanja bulanan keluarga',
    'Ide aplikasi catatan offline',
    'Review pull request Minggu 8',
    'Belajar Clean Architecture',
    'Daftar buku yang ingin dibaca',
    'Rencana liburan akhir tahun',
    'Catatan rapat koordinasi tim',
  ];
  return List.generate(count, (i) {
    return Note(
      id: i + 1,
      title: '${titles[i % titles.length]} ${i + 1}',
      body: i % 3 == 0 ? '' : 'Isi catatan contoh nomor ${i + 1}.',
      updatedAt: DateTime(2026, 11, 15).subtract(Duration(minutes: i)),
      dirty: i % 7 == 0,
    );
  });
}

void main() {
  testWidgets('hitung rebuild saat mengetik kata kunci pencarian', (
    tester,
  ) async {
    final notes = _seedNotes(1500);
    final counts = <String, int>{};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) => notes),
          noteRepositoryProvider.overrideWithValue(_NoopNoteRepository()),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Mulai menghitung rebuild hanya pada fase mengetik.
    // Catatan: `builtOnce` pada callback ini hanya terisi jika
    // `debugPrintRebuildDirtyWidgets` aktif, jadi hitungan memakai nama widget
    // apa adanya. Callback dipasang setelah layar stabil, sehingga semua
    // pemanggilan di bawah ini memang rebuild akibat ketikan.
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final name = element.widget.runtimeType.toString();
      counts[name] = (counts[name] ?? 0) + 1;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    // Skenario sama dengan integration_test/perf_test.dart: 13 karakter,
    // satu karakter setiap 50 ms.
    const query = 'rencana rapat';
    final searchField = find.byType(TextField).last;
    for (var i = 1; i <= query.length; i++) {
      await tester.enterText(searchField, query.substring(0, i));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final stats = {
      'notesPageRebuilds': counts['NotesPage'] ?? 0,
      'noteTileRebuilds': counts['NoteTile'] ?? 0,
      'totalRebuilds': total,
      'rebuildsPerKeystroke': (total / query.length).toStringAsFixed(1),
    };
    debugPrint('REBUILD_STATS=${stats.toString()}');

    // Fungsional tetap benar: hasil pencarian muncul.
    expect(find.textContaining('Rencana rapat mingguan'), findsWidgets);

    // Penjaga regresi untuk optimasi Minggu 11:
    // - halaman tidak boleh ikut dibangun ulang saat mengetik
    // - total rebuild harus jauh di bawah baseline 5.052
    expect(counts['NotesPage'] ?? 0, 0);
    expect(total, lessThan(1200));
  });
}
