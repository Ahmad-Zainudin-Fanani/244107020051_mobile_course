import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.openDb});

  final Future<Database> Function() openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan dari basis data: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ).toMap(),
      );
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } catch (e) {
      return (
        note: null,
        failure: LocalFailure('Gagal menyimpan catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async {
    try {
      final db = await openDb();
      final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        return (
          note: NoteModel.fromMap(rows.first).toEntity(),
          failure: null,
        );
      }
      return (note: null, failure: null);
    } catch (e) {
      return (
        note: null,
        failure: LocalFailure('Gagal mengambil catatan dengan ID $id: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    try {
      final db = await openDb();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return (success: true, failure: null);
    } catch (e) {
      return (
        success: false,
        failure: LocalFailure('Gagal menghapus catatan: $e'),
      );
    }
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    try {
      final db = await openDb();
      final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
      final count = (rows.first['c'] as num?)?.toInt() ?? 0;
      return (count: count, failure: null);
    } catch (e) {
      return (
        count: 0,
        failure: LocalFailure('Gagal menghitung catatan belum sinkron: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    try {
      final db = await openDb();
      await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
      return (success: true, failure: null);
    } catch (e) {
      return (
        success: false,
        failure: LocalFailure('Gagal memperbarui status sinkron: $e'),
      );
    }
  }
}
