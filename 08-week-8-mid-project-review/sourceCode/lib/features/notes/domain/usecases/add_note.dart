import '../../../../core/failures.dart';
import '../../../../core/validation.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class AddNote {
  const AddNote(this._repository);
  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    final titleError = validateNoteTitle(title);
    if (titleError != null) {
      return (note: null, failure: LocalFailure(titleError));
    }
    return _repository.addNote(title: title.trim(), body: body);
  }
}
