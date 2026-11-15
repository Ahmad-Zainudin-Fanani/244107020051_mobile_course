import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/note_tile.dart';

import 'support/note_fakes.dart';
import 'support/notes_test_harness.dart';

void main() {
  testWidgets('menampilkan indikator loading selagi data dimuat', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeNoteRepository(
      notes: sampleNotes(),
      fetchGate: gate,
    );

    await pumpNotesPage(tester, repository);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(NoteTile), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(NoteTile), findsNWidgets(2));
  });

  testWidgets('menampilkan pesan error lalu berhasil setelah Coba Lagi', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: sampleNotes(),
      fetchFailure: const LocalFailure('Database terkunci'),
    );

    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.textContaining('Database terkunci'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(repository.fetchCalls, 1);

    // Kondisi database pulih, pengguna menekan tombol coba lagi.
    repository.fetchFailure = null;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Database terkunci'), findsNothing);
    expect(find.byType(NoteTile), findsNWidgets(2));
    expect(repository.fetchCalls, 2);
  });

  testWidgets('menampilkan empty state saat belum ada catatan', (tester) async {
    await pumpNotesPage(tester, FakeNoteRepository());
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Catatan'), findsOneWidget);
    expect(find.byType(NoteTile), findsNothing);
  });

  testWidgets('menampilkan statistik dan badge status pada daftar', (
    tester,
  ) async {
    await pumpNotesPage(tester, FakeNoteRepository(notes: sampleNotes()));
    await tester.pumpAndSettle();

    expect(find.text('2 catatan • 1 perlu sinkron'), findsOneWidget);
    expect(find.text('Belum Sinkron'), findsOneWidget);
    expect(find.text('Tersinkron'), findsOneWidget);
  });

  testWidgets('menyaring daftar dan menampilkan empty state pencarian', (
    tester,
  ) async {
    await pumpNotesPage(tester, FakeNoteRepository(notes: sampleNotes()));
    await tester.pumpAndSettle();

    await searchFor(tester, 'belanja');
    expect(find.byType(NoteTile), findsOneWidget);
    expect(find.text('Belanja bulanan keluarga'), findsOneWidget);

    await searchFor(tester, 'tidak-ada-yang-cocok');
    expect(find.byType(NoteTile), findsNothing);
    expect(find.text('Tidak ada catatan yang cocok'), findsOneWidget);

    // Tombol hapus pencarian mengembalikan seluruh daftar.
    await tester.tap(find.text('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteTile), findsNWidgets(2));
  });
}
