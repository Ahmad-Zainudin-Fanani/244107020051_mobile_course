import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model data statistik (Immutable - atribut bersifat final)
class StatItem {
  final String label;
  final String value;

  const StatItem({required this.label, required this.value});
}

// Notifier berbasis AsyncNotifier untuk mengelola state statistik secara asinkron
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  @override
  Future<List<StatItem>> build() async {
    // Simulasi delay jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Mengembalikan 3 item data statistik jika berhasil (AsyncData)
    return const [
      StatItem(label: 'Total Tugas Selesai', value: '12 Tugas'),
      StatItem(label: 'Tugas Dalam Proses', value: '3 Tugas'),
      StatItem(label: 'Tingkat Penyelesaian', value: '80%'),
    ];
  }
}

// Provider global menggunakan pola modern AsyncNotifierProvider
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
