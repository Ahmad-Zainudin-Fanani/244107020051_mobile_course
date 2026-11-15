import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/add_note.dart';

import 'support/note_fakes.dart';

void main() {
  test('AddNote berhasil menambahkan catatan dengan judul valid', () async {
    final repo = FakeNoteRepository();
    final useCase = AddNote(repo);

    final result = await useCase.call(title: 'Belajar Clean Architecture');
    expect(result.failure, isNull);
    expect(result.note, isNotNull);
    expect(result.note!.title, 'Belajar Clean Architecture');
    expect(repo.notes.length, 1);
  });

  test('AddNote gagal jika judul kosong (validasi aturan bisnis)', () async {
    final repo = FakeNoteRepository();
    final useCase = AddNote(repo);

    final result = await useCase.call(title: '   ');
    expect(result.failure, isA<LocalFailure>());
    expect(result.failure!.message, 'Judul catatan tidak boleh kosong.');
    expect(result.note, isNull);
    expect(repo.notes, isEmpty);
  });

  test('AddNote meneruskan kegagalan repository tanpa menelan error', () async {
    final repo = FakeNoteRepository(
      addFailure: const LocalFailure('Database penuh (simulasi)'),
    );
    final useCase = AddNote(repo);

    final result = await useCase.call(title: 'Judul valid');

    expect(result.failure, isA<LocalFailure>());
    expect(result.failure!.message, 'Database penuh (simulasi)');
    expect(result.note, isNull);
    expect(repo.notes, isEmpty);
  });
}
