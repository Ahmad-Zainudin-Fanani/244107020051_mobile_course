import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:week5_offline_notes/features/assistant/presentation/widgets/api_key_card.dart';

import 'support/fakes.dart';

Widget _wrap(FakeApiKeyStore store) {
  return ProviderScope(
    overrides: [apiKeyStoreProvider.overrideWithValue(store)],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: ApiKeyCard())),
    ),
  );
}

void main() {
  testWidgets('menampilkan status belum diatur lalu menyimpan key', (
    tester,
  ) async {
    final store = FakeApiKeyStore();

    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('Belum diatur'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'AIza-contoh-key-untuk-test-1234567890',
    );
    await tester.tap(find.text('Simpan key'));
    await tester.pumpAndSettle();

    expect(store.value, 'AIza-contoh-key-untuk-test-1234567890');
    expect(find.text('Tersimpan'), findsOneWidget);
  });

  testWidgets('menolak key yang terlalu pendek tanpa menyimpan', (
    tester,
  ) async {
    final store = FakeApiKeyStore();

    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'pendek');
    await tester.tap(find.text('Simpan key'));
    await tester.pump();

    expect(find.textContaining('terlalu pendek'), findsOneWidget);
    expect(store.value, isNull);
  });
}
