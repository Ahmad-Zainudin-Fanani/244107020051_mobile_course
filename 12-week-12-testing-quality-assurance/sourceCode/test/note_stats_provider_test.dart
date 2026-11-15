import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

import 'support/note_fakes.dart';

void main() {
  ProviderContainer containerWith(FakeNoteRepository repository) {
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('statistik bernilai nol selama data belum termuat', () {
    final container = containerWith(FakeNoteRepository(notes: sampleNotes()));

    expect(container.read(noteStatsProvider), (total: 0, dirty: 0));
  });

  test('menghitung total dan jumlah catatan belum sinkron', () async {
    final container = containerWith(FakeNoteRepository(notes: sampleNotes()));

    await container.read(notesProvider.future);

    expect(container.read(noteStatsProvider), (total: 2, dirty: 1));
  });

  test('tidak memberi notifikasi bila total dan dirty tidak berubah', () async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    final container = containerWith(repository);
    await container.read(notesProvider.future);

    var notifications = 0;
    final subscription = container.listen(noteStatsProvider, (_, _) {
      notifications++;
    });
    addTearDown(subscription.close);

    // Muat ulang daftar dengan isi yang sama. Sebelum memakai record, setiap
    // muat ulang memicu rebuild AppBar karena objeknya selalu baru.
    container.invalidate(notesProvider);
    await container.read(notesProvider.future);
    await container.pump();

    expect(notifications, 0);
    expect(container.read(noteStatsProvider), (total: 2, dirty: 1));
  });

  test('memberi notifikasi saat jumlah catatan berubah', () async {
    final repository = FakeNoteRepository(notes: sampleNotes());
    final container = containerWith(repository);
    await container.read(notesProvider.future);

    var notifications = 0;
    final subscription = container.listen(noteStatsProvider, (_, _) {
      notifications++;
    });
    addTearDown(subscription.close);

    repository.notes.add(
      Note(
        id: 3,
        title: 'Catatan baru',
        updatedAt: DateTime(2026, 11, 15, 13),
        dirty: false,
      ),
    );
    container.invalidate(notesProvider);
    await container.read(notesProvider.future);
    await container.pump();

    expect(notifications, 1);
    expect(container.read(noteStatsProvider), (total: 3, dirty: 1));
  });
}
