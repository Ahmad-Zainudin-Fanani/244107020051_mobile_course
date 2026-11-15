import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:week5_offline_notes/data/sync.dart'
    show ForceOfflineNotifier, forceOfflineProvider;
import 'package:week5_offline_notes/features/notes/presentation/pages/note_detail_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

import 'note_fakes.dart';

/// Notifier offline yang selalu aktif, untuk menguji jalur "mode offline".
class AlwaysOfflineNotifier extends ForceOfflineNotifier {
  @override
  bool build() => true;
}

Widget notesScope(
  FakeNoteRepository repository, {
  bool offline = false,
  required Widget child,
}) {
  return ProviderScope(
    // Riverpod 3 melakukan retry otomatis untuk provider yang gagal. Retry itu
    // berguna di produksi, tetapi membuat test state error bergantung pada
    // waktu (jumlah fetch bisa 1 atau 11). Di test, perilaku itu dimatikan
    // supaya tiap skenario hanya menguji satu jalur.
    retry: (retryCount, error) => null,
    overrides: [
      noteRepositoryProvider.overrideWithValue(repository),
      if (offline) forceOfflineProvider.overrideWith(AlwaysOfflineNotifier.new),
    ],
    child: child,
  );
}

/// Menampilkan [NotesPage] tanpa router. Dipakai test yang tidak berpindah
/// halaman (state, form, pencarian, sinkronisasi).
Future<void> pumpNotesPage(
  WidgetTester tester,
  FakeNoteRepository repository, {
  bool offline = false,
}) async {
  await tester.pumpWidget(
    notesScope(
      repository,
      offline: offline,
      child: const MaterialApp(home: NotesPage()),
    ),
  );
}

/// Menampilkan [NotesPage] dengan rute detail, untuk test navigasi.
Future<GoRouter> pumpNotesApp(
  WidgetTester tester,
  FakeNoteRepository repository,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const NotesPage()),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) =>
            NoteDetailPage(noteId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );

  await tester.pumpWidget(
    notesScope(repository, child: MaterialApp.router(routerConfig: router)),
  );
  return router;
}

/// Mengetik kata kunci lalu menunggu debounce 250 ms milik halaman.
Future<void> searchFor(
  WidgetTester tester,
  String query, {
  bool settle = true,
}) async {
  await tester.enterText(find.byKey(const Key('search-field')), query);
  await tester.pump(const Duration(milliseconds: 300));
  if (settle) {
    await tester.pumpAndSettle();
  }
}
