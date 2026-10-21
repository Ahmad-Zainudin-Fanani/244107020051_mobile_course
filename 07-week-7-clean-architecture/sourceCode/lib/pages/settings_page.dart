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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Tampilan
          _buildSectionHeader('TAMPILAN & TEMA', isDark),
          _buildCard(
            isDark,
            [
              SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: const Text(
                  'Tema Gelap',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text('Beralih antara tema terang dan gelap'),
                value: isDark,
                onChanged: (_) =>
                    ref.read(darkModeProvider.notifier).toggle(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Section 2: Jaringan & Sinkronisasi
          _buildSectionHeader('JARINGAN & SINKRONISASI', isDark),
          _buildCard(
            isDark,
            [
              SwitchListTile(
                secondary: Icon(
                  Icons.cloud_off_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text(
                  'Beralih ke Mode Offline',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                    'Simpan catatan di basis data lokal tanpa sinkronisasi'),
                value: isOffline,
                onChanged: (val) =>
                    ref.read(forceOfflineProvider.notifier).toggle(val),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Section 3: Informasi Sesi
          _buildSectionHeader('RIWAYAT AKTIVITAS', isDark),
          _buildCard(
            isDark,
            [
              lastOpenedAsync.when(
                data: (lastOpened) => ListTile(
                  leading: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Terakhir Dibuka',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Text(lastOpened ?? 'Sesi pertama saat ini'),
                ),
                loading: () => const ListTile(
                  leading: Icon(Icons.history_rounded),
                  title: Text('Terakhir Dibuka'),
                  subtitle: Text('Memuat riwayat...'),
                ),
                error: (err, _) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }
}
