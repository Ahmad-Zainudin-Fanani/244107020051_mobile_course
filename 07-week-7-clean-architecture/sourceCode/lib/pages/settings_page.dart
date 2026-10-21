import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';
import '../data/sync.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider.autoDispose<String?>((ref) async {
  return ref.read(prefsRepositoryProvider).getLastOpened();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider).value ?? false;
    final isOffline = ref.watch(forceOfflineProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.nightlight_round, size: 24),
            title: const Text(
              'Tema Gelap',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Disimpan sebagai preferensi lokal'),
            value: isDark,
            onChanged: (val) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_outlined, size: 24),
            title: const Text(
              'Paksa Mode Offline',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Catatan tidak menggunakan sinkronisasi server'),
            value: isOffline,
            onChanged: (val) =>
                ref.read(forceOfflineProvider.notifier).toggle(val),
          ),
          const SizedBox(height: 6),
          lastOpenedAsync.when(
            data: (lastOpened) => ListTile(
              leading: const Icon(Icons.access_time, size: 24),
              title: const Text(
                'Terakhir Dibuka',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(lastOpened ?? 'Baru saja'),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.access_time, size: 24),
              title: Text(
                'Terakhir Dibuka',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Memuat...'),
            ),
            error: (err, stack) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
