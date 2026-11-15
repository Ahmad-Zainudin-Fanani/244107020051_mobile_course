import 'dart:async';
import 'dart:math' as math;

import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';

/// Repository catatan palsu dengan perilaku yang dikendalikan test.
///
/// Semua jalur (sukses dan gagal) dapat diatur lewat konstruktor atau dengan
/// mengubah field-nya di tengah test, sehingga skenario "gagal lalu retry"
/// bisa diuji tanpa database sungguhan.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({
    List<Note>? notes,
    this.fetchFailure,
    this.addFailure,
    this.deleteFailure,
    this.countFailure,
    this.syncFailure,
    this.fetchGate,
  }) : notes = List<Note>.of(notes ?? const <Note>[]);

  /// Data yang dikembalikan [fetchNotes]. Test boleh mengubahnya langsung.
  final List<Note> notes;

  Failure? fetchFailure;
  Failure? addFailure;
  Failure? deleteFailure;
  Failure? countFailure;
  Failure? syncFailure;

  /// Bila diisi, [fetchNotes] menunggu completer ini selesai. Dipakai untuk
  /// memeriksa indikator loading tanpa `Future.delayed` yang membuat test
  /// bergantung pada waktu.
  Completer<void>? fetchGate;

  int fetchCalls = 0;
  int addCalls = 0;
  int deleteCalls = 0;
  int countDirtyCalls = 0;
  int markAllSyncedCalls = 0;

  final List<int> deletedIds = <int>[];
  final List<({String title, String body})> addedNotes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    fetchCalls++;
    final gate = fetchGate;
    if (gate != null) {
      await gate.future;
    }
    final failure = fetchFailure;
    if (failure != null) {
      return (notes: const <Note>[], failure: failure);
    }
    final sorted = List<Note>.of(notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return (notes: sorted, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    addedNotes.add((title: title, body: body));

    final failure = addFailure;
    if (failure != null) {
      return (note: null, failure: failure);
    }

    final nextId =
        notes.fold<int>(0, (maxId, note) => math.max(maxId, note.id ?? 0)) + 1;
    final note = Note(
      id: nextId,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 15, 12),
      dirty: true,
    );
    notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> getNote(int id) async {
    final failure = fetchFailure;
    if (failure != null) {
      return (note: null, failure: failure);
    }
    for (final note in notes) {
      if (note.id == id) {
        return (note: note, failure: null);
      }
    }
    return (note: null, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    deleteCalls++;
    final failure = deleteFailure;
    if (failure != null) {
      return (success: false, failure: failure);
    }
    deletedIds.add(id);
    notes.removeWhere((note) => note.id == id);
    return (success: true, failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    countDirtyCalls++;
    final failure = countFailure;
    if (failure != null) {
      return (count: 0, failure: failure);
    }
    return (count: notes.where((note) => note.dirty).length, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    markAllSyncedCalls++;
    final failure = syncFailure;
    if (failure != null) {
      return (success: false, failure: failure);
    }
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      notes[i] = Note(
        id: note.id,
        title: note.title,
        body: note.body,
        updatedAt: note.updatedAt,
        dirty: false,
      );
    }
    return (success: true, failure: null);
  }
}

/// Catatan contoh untuk test widget dan integrasi.
List<Note> sampleNotes() => [
  Note(
    id: 1,
    title: 'Rencana rapat mingguan',
    body: 'Agenda: evaluasi performa dan rencana rilis.',
    updatedAt: DateTime(2026, 11, 15, 9, 30),
    dirty: true,
  ),
  Note(
    id: 2,
    title: 'Belanja bulanan keluarga',
    body: '',
    updatedAt: DateTime(2026, 11, 14, 18, 0),
    dirty: false,
  ),
];
