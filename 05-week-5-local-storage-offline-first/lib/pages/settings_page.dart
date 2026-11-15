import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

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
    final lastOpenedAsync = ref.watch(lastOpenedProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark theme'),
            value: isDark,
            onChanged: (val) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          const Divider(),
          lastOpenedAsync.when(
            data: (lastOpened) => ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Last Opened'),
              subtitle: Text(lastOpened ?? 'Never'),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.history),
              title: Text('Last Opened'),
              subtitle: Text('Loading...'),
            ),
            error: (err, stack) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
