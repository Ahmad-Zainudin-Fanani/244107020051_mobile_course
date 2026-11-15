import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_app/main.dart';

void main() {
  testWidgets('menambah tugas baru pada aplikasi ToDo',
      (WidgetTester tester) async {
    // 1. Build aplikasi yang dibungkus ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 2. Verifikasi kondisi awal "Belum ada tugas"
    expect(find.text('Belum ada tugas'), findsOneWidget);

    // 3. Tekan tombol FAB tambah tugas (+)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 4. Masukkan teks ke dalam TextField dialog
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');

    // 5. Tekan tombol "Tambah" di dialog
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // 6. Verifikasi tugas baru "Kerjakan PR minggu 3" tampil di layar
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });

  testWidgets('Memverifikasi navigasi ke StatsPage dan 3 item statistik tampil',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pump();

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Statistik Aplikasi'), findsOneWidget);
    expect(find.text('Total Tugas Selesai'), findsOneWidget);
    expect(find.text('Tugas Dalam Proses'), findsOneWidget);
    expect(find.text('Tingkat Penyelesaian'), findsOneWidget);
  });
}
