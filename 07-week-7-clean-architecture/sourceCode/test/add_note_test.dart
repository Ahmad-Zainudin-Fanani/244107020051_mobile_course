import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/add_note.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.fail = false});

  final bool fail;
  final List<Note> items = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    throw UnimplementedError();
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (fail) {
      return (
        note: null,
        failure: const LocalFailure('Database penuh (simulasi)'),
      );
    }
    final newNote = Note(
      id: items.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 10, 21),
      dirty: true,
    );
    items.add(newNote);
    return (note: newNote, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    throw UnimplementedError();
  }
}

void main() {
  test('AddNote berhasil menambahkan catatan dengan judul valid', () async {
    final repo = FakeNoteRepository();
    final useCase = AddNote(repo);

    final result = await useCase.call(title: 'Belajar Clean Architecture');
    expect(result.failure, isNull);
    expect(result.note, isNotNull);
    expect(result.note!.title, 'Belajar Clean Architecture');
    expect(repo.items.length, 1);
  });

  test('AddNote gagal jika judul kosong (validasi aturan bisnis)', () async {
    final repo = FakeNoteRepository();
    final useCase = AddNote(repo);

    final result = await useCase.call(title: '   ');
    expect(result.failure, isA<LocalFailure>());
    expect(result.failure!.message, 'Judul catatan tidak boleh kosong.');
    expect(result.note, isNull);
    expect(repo.items, isEmpty);
  });
}
