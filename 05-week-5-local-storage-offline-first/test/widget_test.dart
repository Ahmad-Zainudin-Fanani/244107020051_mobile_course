import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/main.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('beranda menampilkan tab Notes dan Posts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Ganti akses SQLite dengan daftar kosong agar test tidak butuh
          // database perangkat.
          notesProvider.overrideWith((ref) async => []),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline Notes'), findsOneWidget);
    expect(find.text('No notes yet.'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);
  });
}
