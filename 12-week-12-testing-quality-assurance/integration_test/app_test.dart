import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/note_tile.dart';
import 'package:week5_offline_notes/main.dart' as app;

/// Pengujian integrasi alur utama aplikasi catatan.
///
/// Jalankan di perangkat/emulator:
///   `flutter test integration_test/app_test.dart -d <device_id>`
///
/// Test ini memakai database sungguhan di perangkat, sehingga membuktikan
/// widget, provider, use case, dan SQLite bekerja bersama — hal yang tidak
/// bisa dibuktikan widget test dengan repository palsu.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur utama: tambah, buka rincian, cari, lalu hapus', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Catatan Saya'), findsOneWidget);

    // Judul unik supaya test tidak bergantung pada isi database perangkat.
    final title = 'Catatan QA ${DateTime.now().millisecondsSinceEpoch}';
    const body = 'Dibuat oleh integration test Minggu 12.';

    // Dicari lewat NoteTile, bukan `find.text`, karena kolom pencarian juga
    // memuat teks yang sama sehingga `find.text(title)` menemukan dua widget.
    final noteCard = find.widgetWithText(NoteTile, title);

    // 1. Tambah catatan lewat form.
    await tester.tap(find.byKey(const Key('add-note-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-note-title')), title);
    await tester.enterText(find.byKey(const Key('add-note-body')), body);
    await tester.tap(find.byKey(const Key('add-note-save')));
    await tester.pumpAndSettle();

    expect(noteCard, findsOneWidget);

    // 2. Buka halaman rincian.
    await tester.tap(noteCard);
    await tester.pumpAndSettle();
    expect(find.text('Rincian Catatan'), findsOneWidget);
    expect(find.text(body), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Cari catatan yang baru dibuat.
    await tester.enterText(find.byKey(const Key('search-field')), title);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(noteCard, findsOneWidget);

    // 4. Hapus lewat long press, lalu pastikan hilang dari daftar.
    await tester.longPress(noteCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(noteCard, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
