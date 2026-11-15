import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    // Data pengumuman kampus berdasarkan id
    final announcementData = _getAnnouncementData(id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman Kampus #$id'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deep Link Target Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Deep Link Berhasil: Rute /pengumuman/$id terbuka via FCM payload navigation.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            announcementData['tag'] ?? 'AKADEMIK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          announcementData['date'] ?? 'Hari ini',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      announcementData['title'] ?? 'Pengumuman Kampus',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const Divider(height: 32),
                    Text(
                      announcementData['body'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Metadata Notifikasi FCM:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Topic: pengumuman-kampus\n• Route: /pengumuman/$id\n• ID: $id',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Kembali ke Beranda'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getAnnouncementData(String id) {
    if (id == '3') {
      return {
        'title': 'Jadwal Kuliah Berubah',
        'tag': 'PERUBAHAN JADWAL',
        'date': 'Hari ini • 09:30 WIB',
        'body':
            'Diberitahukan kepada seluruh mahasiswa peserta mata kuliah Pemrograman Mobile bahwa perkuliahan hari ini dipindahkan ke Ruang A2 pada pukul 13.00 WIB dikarenakan pemeliharaan laboratorium utama.\n\nHarap hadir tepat waktu dan membawa perangkat laptop yang telah terkonfigurasi Flutter SDK.',
      };
    } else if (id == '1') {
      return {
        'title': 'Pendaftaran KRS Semester Genap Dibuka',
        'tag': 'AKADEMIK',
        'date': '20 Februari 2026',
        'body':
            'Pendaftaran dan revisi Kartu Rencana Studi (KRS) untuk semester genap tahun akademik 2025/2026 telah dibuka melalui portal sistem informasi akademik. Batas akhir pengisian adalah tanggal 28 Februari.',
      };
    } else {
      return {
        'title': 'Seminar Nasional AI & Mobile Technology',
        'tag': 'EVENT',
        'date': '18 Februari 2026',
        'body':
            'Program Studi menyelenggarakan Seminar Nasional dengan tema "Membangun Aplikasi Cerdas Berbasis On-Device AI". Terbuka untuk seluruh mahasiswa angkatan aktif.',
      };
    }
  }
}
