import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

Note _note(String title) =>
    Note(title: title, updatedAt: DateTime(2026, 11, 15));

ProviderContainer _container({
  required Future<List<Note>> Function() load,
  bool includeContext = false,
}) {
  final container = ProviderContainer(
    overrides: [notesProvider.overrideWith((ref) => load())],
  );
  addTearDown(container.dispose);
  if (includeContext) {
    container.read(includeNotesContextProvider.notifier).toggle(true);
  }
  return container;
}

void main() {
  test('konteks mati tidak pernah membaca judul catatan', () {
    final container = _container(load: () async => [_note('Belanja bulanan')]);
    final sub = container.listen(assistantContextTitlesProvider, (_, _) {});

    expect(sub.read(), isEmpty);
  });

  test('konteks nyala mengirim judul setelah daftar termuat', () async {
    final container = _container(
      load: () async => [_note('Belanja bulanan'), _note('Rencana rapat')],
      includeContext: true,
    );
    final sub = container.listen(assistantContextTitlesProvider, (_, _) {});

    // Regresi: halaman Catatan sudah dibuang, jadi provider harus memuat
    // sendiri tanpa menunggu tombol kirim ditekan.
    expect(sub.read(), isEmpty);

    await container.read(notesProvider.future);

    expect(sub.read(), ['Belanja bulanan', 'Rencana rapat']);
  });

  test('daftar yang masih dimuat tidak dikirim setengah jadi', () async {
    final completer = Completer<List<Note>>();
    final container = _container(
      load: () => completer.future,
      includeContext: true,
    );
    final sub = container.listen(assistantContextTitlesProvider, (_, _) {});

    expect(sub.read(), isEmpty);

    completer.complete([_note('Ide aplikasi')]);
    await pumpEventQueue();

    expect(sub.read(), ['Ide aplikasi']);
  });

  test('mematikan saklar mengosongkan konteks lagi', () async {
    final container = _container(
      load: () async => [_note('Belanja bulanan')],
      includeContext: true,
    );
    final sub = container.listen(assistantContextTitlesProvider, (_, _) {});
    await container.read(notesProvider.future);
    expect(sub.read(), isNotEmpty);

    container.read(includeNotesContextProvider.notifier).toggle(false);

    expect(sub.read(), isEmpty);
  });
}
