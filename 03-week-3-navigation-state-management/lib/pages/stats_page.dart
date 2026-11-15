import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// Halaman statistik menggunakan ConsumerWidget agar dapat membaca Riverpod provider lewat `ref`
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch HANYA digunakan di dalam method build untuk berlangganan perubahan state
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
      ),
      // statsAsync.when menangani 3 kondisi AsyncValue: loading, error, dan success (data)
      body: statsAsync.when(
        // Kondisi 1: Loading -> Menampilkan CircularProgressIndicator di tengah layar
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Kondisi 2: Error -> Menampilkan pesan error dan tombol "Coba lagi"
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat data:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  // ref.read digunakan di callback event (onPressed)
                  // ref.invalidate memaksa provider untuk melakukan reset dan fetch data dari awal
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        // Kondisi 3: Success -> Menampilkan ListView berisi 3 item statistik
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.teal),
                title: Text(item.label),
                trailing: Text(
                  item.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
