import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_app/providers/stats_provider.dart';

// Test Notifier khusus untuk menguji skenario sukses (dibuat deterministik)
class TestSuccessStatsNotifier extends StatsNotifier {
  @override
  Future<List<StatItem>> build() async {
    return const [
      StatItem(label: 'Total Tugas Selesai', value: '12 Tugas'),
      StatItem(label: 'Tugas Dalam Proses', value: '3 Tugas'),
      StatItem(label: 'Tingkat Penyelesaian', value: '80%'),
    ];
  }
}

// Test Notifier khusus untuk menguji skenario error (dibuat deterministik)
class TestErrorStatsNotifier extends StatsNotifier {
  @override
  Future<List<StatItem>> build() async {
    throw Exception('Gagal mengambil data statistik dari server');
  }
}

void main() {
  group('StatsNotifier Unit Test', () {
    test('Mengembalikan 3 item data statistik pada kondisi sukses', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(() => TestSuccessStatsNotifier()),
        ],
      );

      final stats = await container.read(statsProvider.future);

      expect(stats.length, equals(3));
      expect(stats[0].label, equals('Total Tugas Selesai'));
      expect(stats[1].label, equals('Tugas Dalam Proses'));
      expect(stats[2].label, equals('Tingkat Penyelesaian'));

      container.dispose();
    });

    test('Menangani error dengan benar pada kondisi gagal', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(() => TestErrorStatsNotifier()),
        ],
      );

      container.listen(statsProvider, (previous, next) {});
      await Future.delayed(Duration.zero);

      final state = container.read(statsProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Gagal mengambil data statistik dari server'));

      container.dispose();
    });
  });
}
