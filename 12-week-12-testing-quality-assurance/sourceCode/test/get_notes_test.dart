import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/get_notes.dart';

import 'support/note_fakes.dart';

void main() {
  test(
    'GetNotes meneruskan daftar catatan dari repository secara sukses',
    () async {
      final repo = FakeNoteRepository(
        notes: [Note(title: 'Catatan A', updatedAt: DateTime(2026, 9, 27))],
      );

      final result = await GetNotes(repo).call();

      expect(result.failure, isNull);
      expect(result.notes.length, 1);
      expect(result.notes.first.title, 'Catatan A');
    },
  );

  test('GetNotes meneruskan failure tanpa melempar exception liar', () async {
    final repo = FakeNoteRepository(
      fetchFailure: const LocalFailure('db locked (simulasi)'),
    );

    final result = await GetNotes(repo).call();

    expect(result.failure, isA<LocalFailure>());
    expect(result.notes, isEmpty);
  });
}
