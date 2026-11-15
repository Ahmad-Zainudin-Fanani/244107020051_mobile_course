import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/assistant/domain/services/ai_assistant.dart';
import 'package:week5_offline_notes/features/assistant/presentation/providers/assistant_providers.dart';

import 'support/fakes.dart';

ProviderContainer _container({
  required FakeApiKeyStore store,
  required AiAssistantFactory factory,
  int? limit,
}) {
  final container = ProviderContainer(
    overrides: [
      apiKeyStoreProvider.overrideWithValue(store),
      aiAssistantFactoryProvider.overrideWithValue(factory),
      if (limit != null) chatRequestLimitProvider.overrideWithValue(limit),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'tanpa API key: pertanyaan tetap tampil, ada arahan ke Pengaturan',
    () async {
      final assistant = FakeAssistant(chunks: ['Tidak dipakai']);
      final container = _container(
        store: FakeApiKeyStore(),
        factory: (_) => assistant,
      );

      await container.read(chatControllerProvider.notifier).send('Halo');

      final state = container.read(chatControllerProvider);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.isUser, isTrue);
      expect(state.error, contains('Pengaturan'));
      expect(state.requestsUsed, 0);
      expect(assistant.calls, 0);
    },
  );

  test('potongan jawaban digabung jadi satu pesan asisten', () async {
    final assistant = FakeAssistant(chunks: ['Halo', ' dari', ' AI']);
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
    );

    await container.read(chatControllerProvider.notifier).send('Apa kabar?');

    final state = container.read(chatControllerProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages.first.text, 'Apa kabar?');
    expect(state.messages.last.text, 'Halo dari AI');
    expect(state.messages.last.isStreaming, isFalse);
    expect(state.isStreaming, isFalse);
    expect(state.requestsUsed, 1);
  });

  test('konteks judul hanya dikirim saat pengguna menyalakannya', () async {
    final assistant = FakeAssistant(chunks: ['Baik']);
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
    );
    final notifier = container.read(chatControllerProvider.notifier);

    await notifier.send('Apa catatan saya?');
    expect(assistant.lastSystemPrompt, isNot(contains('Belanja bulanan')));

    await notifier.send(
      'Apa catatan saya?',
      noteTitles: ['Belanja bulanan'],
      includeContext: true,
    );
    expect(assistant.lastSystemPrompt, contains('- Belanja bulanan'));
  });

  test('pertanyaan identik memakai cache, bukan panggilan baru', () async {
    final assistant = FakeAssistant(chunks: ['Jawaban']);
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
    );
    final notifier = container.read(chatControllerProvider.notifier);

    await notifier.send('Apa itu catatan?');
    await notifier.send('  apa itu CATATAN? ');

    final state = container.read(chatControllerProvider);
    expect(assistant.calls, 1);
    expect(state.messages, hasLength(4));
    expect(state.messages.last.text, 'Jawaban');
    expect(state.requestsUsed, 1);
  });

  test('batas permintaan per sesi dihentikan dengan pesan jelas', () async {
    final assistant = FakeAssistant(chunks: ['Jawaban']);
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
      limit: 2,
    );
    final notifier = container.read(chatControllerProvider.notifier);

    await notifier.send('Satu');
    await notifier.send('Dua');
    await notifier.send('Tiga');

    final state = container.read(chatControllerProvider);
    expect(assistant.calls, 2);
    expect(state.requestsUsed, 2);
    expect(state.error, contains('Batas 2'));
    expect(state.messages, hasLength(4));
  });

  test('tombol stop menyimpan teks parsial dan menutup stream', () async {
    final assistant = ManualAssistant();
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
    );
    final notifier = container.read(chatControllerProvider.notifier);

    final pending = notifier.send('Halo');
    await pumpEventQueue();
    assistant.controller.add('Halo');
    await pumpEventQueue();
    expect(container.read(chatControllerProvider).messages.last.text, 'Halo');

    notifier.cancel();
    await pending;

    final state = container.read(chatControllerProvider);
    expect(state.isStreaming, isFalse);
    expect(state.messages.last.text, 'Halo (dihentikan)');
    expect(state.messages.last.isStreaming, isFalse);

    await assistant.controller.close();
  });

  test('error dari layanan AI tidak meninggalkan bubble kosong', () async {
    final assistant = FakeAssistant(
      error: const AssistantException('Kuota AI habis.'),
    );
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
    );

    await container.read(chatControllerProvider.notifier).send('Halo');

    final state = container.read(chatControllerProvider);
    expect(state.error, 'Kuota AI habis.');
    expect(state.messages, hasLength(1));
    expect(state.messages.single.isUser, isTrue);
    expect(state.isStreaming, isFalse);
  });

  test('hapus percakapan mengosongkan pesan, error, dan hitungan', () async {
    final assistant = FakeAssistant(chunks: ['Jawaban']);
    final container = _container(
      store: FakeApiKeyStore('AIza-test'),
      factory: (_) => assistant,
    );
    final notifier = container.read(chatControllerProvider.notifier);

    await notifier.send('Halo');
    notifier.clear();

    final state = container.read(chatControllerProvider);
    expect(state.messages, isEmpty);
    expect(state.error, isNull);
    expect(state.requestsUsed, 0);
  });
}
