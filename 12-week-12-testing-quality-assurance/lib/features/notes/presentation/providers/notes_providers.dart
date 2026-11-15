import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';

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

final noteDetailProvider = FutureProvider.autoDispose.family<Note?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(noteRepositoryProvider);
  final result = await repo.getNote(id);
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.note;
});

/// Statistik ringkas daftar catatan (total dan jumlah yang belum sinkron).
///
/// Dihitung sekali setiap daftar berubah, bukan setiap widget dibangun.
/// Sebelumnya `NotesPage` menjalankan `notes.where((n) => n.dirty).length`
/// langsung di dalam `build`, sehingga setiap ketikan pada kolom pencarian
/// memindai ulang seluruh 1.500 catatan.
///
/// Nilai balik berupa record, yang perbandingannya berdasarkan isi field:
/// bila total dan dirty tidak berubah, Riverpod tidak memicu rebuild.
final noteStatsProvider = Provider.autoDispose<({int total, int dirty})>((ref) {
  final notes = ref.watch(notesProvider).value ?? const <Note>[];
  var dirty = 0;
  for (final note in notes) {
    if (note.dirty) {
      dirty++;
    }
  }
  return (total: notes.length, dirty: dirty);
});

/// Kata kunci pencarian judul yang sedang aktif.
///
/// Provider ini mengikuti siklus hidup halaman catatan. Saat pengguna pindah
/// tab, query ikut dibuang supaya daftar tidak tetap tersaring tanpa teks di
/// kolom cari.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider.autoDispose<SearchQueryNotifier, String>(
      SearchQueryNotifier.new,
    );

/// Daftar catatan yang sudah disaring berdasarkan judul.
///
/// Penyaringan dilakukan oleh use case domain, bukan di widget, sehingga
/// perilakunya bisa diuji tanpa membangun UI.
final filteredNotesProvider = Provider.autoDispose<AsyncValue<List<Note>>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(notesProvider)
      .whenData((notes) => searchNotesByTitle(notes, query));
});
