import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';

import 'support/note_fakes.dart';
import 'support/notes_test_harness.dart';

void main() {
  testWidgets('tombol Buat Catatan membuka form tambah catatan', (
    tester,
  ) async {
    await pumpNotesPage(tester, FakeNoteRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Buat Catatan Baru'), findsOneWidget);
    expect(find.byKey(const Key('add-note-title')), findsOneWidget);
    expect(find.byKey(const Key('add-note-body')), findsOneWidget);
  });

  testWidgets('judul kosong ditolak dan repository tidak dipanggil', (
    tester,
  ) async {
    final repository = FakeNoteRepository();
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-note-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-note-save')));
    await tester.pumpAndSettle();

    expect(find.text('Judul catatan tidak boleh kosong.'), findsOneWidget);
    expect(repository.addCalls, 0);
    // Form tetap terbuka supaya pengguna bisa memperbaiki input.
    expect(find.text('Buat Catatan Baru'), findsOneWidget);
  });

  testWidgets('input valid menyimpan catatan dan menampilkannya di daftar', (
    tester,
  ) async {
    final repository = FakeNoteRepository();
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-note-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('add-note-title')),
      '  Catatan dari form  ',
    );
    await tester.enterText(
      find.byKey(const Key('add-note-body')),
      'Isi catatan dari form',
    );
    await tester.tap(find.byKey(const Key('add-note-save')));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    // Spasi di awal dan akhir dibuang sebelum disimpan.
    expect(repository.addedNotes.single.title, 'Catatan dari form');
    expect(repository.addedNotes.single.body, 'Isi catatan dari form');

    expect(find.text('Buat Catatan Baru'), findsNothing);
    expect(find.text('Catatan dari form'), findsOneWidget);
    expect(find.text('1 catatan • 1 perlu sinkron'), findsOneWidget);
  });

  testWidgets('kegagalan penyimpanan dilaporkan lewat SnackBar', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      addFailure: const LocalFailure('Database penuh (simulasi)'),
    );
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-note-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-note-title')),
      'Catatan gagal',
    );
    await tester.tap(find.byKey(const Key('add-note-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Database penuh'), findsOneWidget);
    expect(find.text('Catatan gagal'), findsNothing);
  });

  testWidgets('kolom input cepat menyimpan catatan dan mengosongkan field', (
    tester,
  ) async {
    final repository = FakeNoteRepository();
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('quick-add-field')),
      '  Catatan cepat  ',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(repository.addedNotes.single.title, 'Catatan cepat');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('quick-add-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Catatan cepat'), findsOneWidget);
  });

  testWidgets('input cepat yang kosong tidak menyimpan apa pun', (
    tester,
  ) async {
    final repository = FakeNoteRepository();
    await pumpNotesPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('quick-add-field')), '   ');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Judul catatan tidak boleh kosong.'), findsOneWidget);
    expect(repository.addCalls, 0);
  });
}
