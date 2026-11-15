import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/search_empty_view.dart';

void main() {
  testWidgets('menampilkan kata kunci dan tombol hapus pencarian', (
    tester,
  ) async {
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchEmptyView(
            query: 'zzz-tidak-ada',
            onClear: () => cleared = true,
          ),
        ),
      ),
    );

    expect(find.text('Tidak ada catatan yang cocok'), findsOneWidget);
    expect(find.textContaining('zzz-tidak-ada'), findsOneWidget);

    await tester.tap(find.text('Hapus pencarian'));
    await tester.pump();

    expect(cleared, isTrue);
  });
}
