import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

void main() {
  test('kata kunci dibuang saat tidak ada lagi yang mendengarkan', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final subscription = container.listen(searchQueryProvider, (_, _) {});
    container.read(searchQueryProvider.notifier).update('belanja');
    expect(container.read(searchQueryProvider), 'belanja');

    subscription.close();
    await container.pump();

    expect(container.read(searchQueryProvider), isEmpty);
  });
}
