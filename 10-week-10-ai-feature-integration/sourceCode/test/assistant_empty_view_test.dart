import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/assistant/presentation/widgets/assistant_empty_view.dart';

void main() {
  testWidgets('menampilkan contoh pertanyaan dan meneruskan pilihan', (
    tester,
  ) async {
    String? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssistantEmptyView(onSuggestionTap: (value) => tapped = value),
        ),
      ),
    );

    expect(find.text('Tanya apa saja tentang catatan Anda'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(3));

    await tester.tap(find.text('Apa yang bisa kamu lakukan?'));
    await tester.pump();

    expect(tapped, 'Apa yang bisa kamu lakukan?');
  });
}
