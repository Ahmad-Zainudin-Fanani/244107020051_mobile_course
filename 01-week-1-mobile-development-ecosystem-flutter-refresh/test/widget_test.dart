import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('menampilkan profil mahasiswa', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Profil Mahasiswa'), findsOneWidget);
    expect(find.text('Ahmad Zainudin Fanani'), findsOneWidget);
    expect(find.text('NIM: 244107020051'), findsOneWidget);
    expect(find.text('Program Studi: D4 Teknik Informatika'), findsOneWidget);
    expect(find.text('Pemrograman Mobile — Minggu 1'), findsOneWidget);
  });
}
