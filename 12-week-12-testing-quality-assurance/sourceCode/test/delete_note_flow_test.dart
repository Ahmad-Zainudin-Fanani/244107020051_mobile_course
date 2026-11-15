import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/note_tile.dart';

import 'support/note_fakes.dart';
import 'support/notes_test_harness.dart';

void main() {
  testWidgets('menekan lama lalu Batal tidak menghapus catatan', (
    tester,
  ) async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Rencana rapat mingguan'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Catatan?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(find.byType(NoteTile), findsNWidgets(2));
  });

  testWidgets('konfirmasi hapus menghapus catatan dari daftar', (tester) async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Rencana rapat mingguan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [1]);
    expect(find.text('Rencana rapat mingguan'), findsNothing);
    expect(find.byType(NoteTile), findsOneWidget);
  });

  testWidgets('kegagalan hapus dari daftar memberi umpan balik', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: sampleNotes(),
      deleteFailure: const LocalFailure('Database terkunci'),
    );
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Rencana rapat mingguan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Database terkunci'), findsOneWidget);
    // Catatan masih ada karena penghapusan gagal.
    expect(find.byType(NoteTile), findsNWidgets(2));
  });

  testWidgets('mengetuk catatan membuka halaman rincian', (tester) async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    await pumpNotesApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rencana rapat mingguan'));
    await tester.pumpAndSettle();

    expect(find.text('Rincian Catatan'), findsOneWidget);
    expect(
      find.text('Agenda: evaluasi performa dan rencana rilis.'),
      findsOneWidget,
    );
  });

  testWidgets('hapus dari halaman rincian kembali ke daftar', (tester) async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    await pumpNotesApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rencana rapat mingguan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [1]);
    expect(find.text('Catatan berhasil dihapus.'), findsOneWidget);
    expect(find.text('Rincian Catatan'), findsNothing);
    expect(find.byType(NoteTile), findsOneWidget);
  });

  testWidgets('kegagalan hapus di halaman rincian tidak mengklaim sukses', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: sampleNotes(),
      deleteFailure: const LocalFailure('Database terkunci'),
    );
    await pumpNotesApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rencana rapat mingguan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Database terkunci'), findsOneWidget);
    expect(find.text('Catatan berhasil dihapus.'), findsNothing);
    // Tetap di halaman rincian supaya pengguna bisa mencoba lagi.
    expect(find.text('Rincian Catatan'), findsOneWidget);
  });
}
