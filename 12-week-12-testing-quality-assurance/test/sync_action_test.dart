import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';

import 'support/note_fakes.dart';
import 'support/notes_test_harness.dart';

void main() {
  testWidgets('sinkronisasi menandai semua catatan tersinkron', (tester) async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync-notes-button')));
    // Lewati jeda simulasi jaringan 500 ms di dalam aksi sinkronisasi.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repository.markAllSyncedCalls, 1);
    expect(
      find.text('Berhasil! Seluruh catatan telah disinkronkan.'),
      findsOneWidget,
    );
    expect(find.text('2 catatan • Semua tersinkron'), findsOneWidget);
  });

  testWidgets('tanpa catatan belum sinkron tidak ada perubahan status', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: [
        Note(
          id: 1,
          title: 'Sudah tersinkron',
          updatedAt: DateTime(2026, 11, 15, 9),
          dirty: false,
        ),
      ],
    );
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync-notes-button')));
    await tester.pumpAndSettle();

    expect(repository.markAllSyncedCalls, 0);
    expect(
      find.text('Semua catatan sudah berstatus tersinkron.'),
      findsOneWidget,
    );
  });

  testWidgets('mode offline menolak sinkronisasi tanpa menyentuh database', (
    tester,
  ) async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    await pumpNotesPage(tester, repository, offline: true);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync-notes-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Mode Offline aktif. Tidak dapat menyinkronkan.'),
      findsOneWidget,
    );
    expect(repository.countDirtyCalls, 0);
    expect(repository.markAllSyncedCalls, 0);
  });

  testWidgets('kegagalan menghitung catatan tidak dilaporkan sebagai sukses', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: sampleNotes(),
      countFailure: const LocalFailure('Database terkunci'),
    );
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync-notes-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Database terkunci'), findsOneWidget);
    expect(
      find.text('Semua catatan sudah berstatus tersinkron.'),
      findsNothing,
    );
    expect(repository.markAllSyncedCalls, 0);
  });

  testWidgets('kegagalan menandai tersinkron tidak dilaporkan sebagai sukses', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: sampleNotes(),
      syncFailure: const LocalFailure('Gagal menulis ke database'),
    );
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sync-notes-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal menulis ke database'), findsOneWidget);
    expect(
      find.text('Berhasil! Seluruh catatan telah disinkronkan.'),
      findsNothing,
    );
  });
}
