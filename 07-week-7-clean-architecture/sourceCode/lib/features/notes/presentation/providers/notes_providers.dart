import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';

// Injeksi Repositori Data Layer (implementasi konkret dengan openDb yang dapat ditukar saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Injeksi Use Cases Domain Layer (menerima kontrak abstraksi, bukan konkrit)
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

// Presentation Layer State: UI mengamati provider ini
final notesProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.notes;
});

final noteDetailProvider =
    FutureProvider.autoDispose.family<Note?, int>((ref, id) async {
  final repo = ref.watch(noteRepositoryProvider);
  final result = await repo.getNote(id);
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.note;
});
