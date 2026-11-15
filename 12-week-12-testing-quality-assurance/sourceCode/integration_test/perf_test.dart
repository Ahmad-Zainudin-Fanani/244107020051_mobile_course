import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/note_tile.dart';
import 'package:week5_offline_notes/main.dart' as app;

const _seedCount = 1500;

const _titles = [
  'Rencana rapat mingguan',
  'Belanja bulanan keluarga',
  'Ide aplikasi catatan offline',
  'Review pull request Minggu 8',
  'Belajar Clean Architecture',
  'Daftar buku yang ingin dibaca',
  'Rencana liburan akhir tahun',
  'Catatan rapat koordinasi tim',
  'Anggaran transportasi bulan ini',
  'Checklist presentasi proyek',
  'Resep masakan rumahan sederhana',
  'Target belajar Flutter minggu ini',
  'Daftar kontak penting kampus',
  'Evaluasi performa aplikasi',
  'Rencana perbaikan UI beranda',
];

String _body(int index) =>
    'Catatan contoh nomor $index untuk mengukur performa daftar panjang. '
    'Isi ini sengaja dibuat beberapa baris agar tinggi kartu bervariasi, '
    'sehingga layout dan paint benar-benar diuji.';

Future<void> _seedNotes() async {
  final path = p.join(await getDatabasesPath(), 'offline_notes.db');
  final db = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
  await db.delete('notes');
  final batch = db.batch();
  final now = DateTime.now();
  for (var i = 0; i < _seedCount; i++) {
    final title = '${_titles[i % _titles.length]} ${i + 1}';
    batch.insert('notes', {
      'title': title,
      'body': i % 3 == 0 ? '' : _body(i + 1),
      'updated_at': now.subtract(Duration(minutes: i)).toIso8601String(),
      'dirty': i % 7 == 0 ? 1 : 0,
    });
  }
  await batch.commit(noResult: true);
  await db.close();
  debugPrint('PERF_SEEDED=$_seedCount');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profil daftar, scroll, detail, dan pencarian', (tester) async {
    await _seedNotes();
    app.main();
    await tester.pumpAndSettle();

    await binding.watchPerformance(() async {
      final list = find.byType(ListView);
      expect(list, findsOneWidget);

      for (var i = 0; i < 6; i++) {
        await tester.fling(list, const Offset(0, -700), 1600);
        await tester.pumpAndSettle();
      }

      await tester.fling(list, const Offset(0, 900), 1600);
      await tester.pumpAndSettle();

      final firstTile = find.byType(NoteTile).first;
      await tester.ensureVisible(firstTile);
      await tester.tap(firstTile);
      await tester.pumpAndSettle();
      expect(find.text('Rincian Catatan'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'belanja');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Simulasi mengetik cepat: setiap karakter memicu rebuild pada
      // implementasi baseline.
      const query = 'rencana rapat';
      for (var i = 1; i <= query.length; i++) {
        await tester.enterText(
          find.byType(TextField).last,
          query.substring(0, i),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }, reportKey: 'performance');

    final summary = binding.reportData!['performance'];
    debugPrint('PERF_SUMMARY=${jsonEncode(summary)}');

    // Memory profiling: buka detail -> kembali 5x, bandingkan RSS proses.
    // Angka ini kasar (RSS seluruh proses), tetapi cukup untuk mendeteksi
    // kebocoran besar seperti controller/listener yang tidak di-dispose.
    final rssBefore = ProcessInfo.currentRss;
    final firstTile = find.byType(NoteTile).first;
    await tester.ensureVisible(firstTile);
    for (var i = 0; i < 5; i++) {
      await tester.tap(firstTile);
      await tester.pumpAndSettle();
      expect(find.text('Rincian Catatan'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    final rssAfter = ProcessInfo.currentRss;

    const mb = 1024 * 1024;
    debugPrint(
      'PERF_MEMORY='
      '{"rss_before_mb":${rssBefore ~/ mb},'
      '"rss_after_mb":${rssAfter ~/ mb},'
      '"delta_mb":${(rssAfter - rssBefore) ~/ mb},'
      '"nav_loops":5}',
    );
  });
}
