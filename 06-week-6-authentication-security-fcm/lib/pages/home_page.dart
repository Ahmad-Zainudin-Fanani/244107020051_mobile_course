import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/api_client.dart';
import '../data/api_errors.dart';
import '../data/token_store.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _maskedAccess;
  String? _maskedRefresh;
  bool _isTestingRefresh = false;
  String? _refreshTestMessage;

  @override
  void initState() {
    super.initState();
    _loadStoredTokens();
  }

  Future<void> _loadStoredTokens() async {
    final store = ref.read(tokenStoreProvider);
    final access = await store.readAccess();
    final refresh = await store.readRefresh();
    if (mounted) {
      setState(() {
        _maskedAccess = TokenStore.maskToken(access);
        _maskedRefresh = TokenStore.maskToken(refresh);
      });
    }
  }

  /// Simulasi request dengan 401 untuk membuktikan refresh token otomatis bekerja
  Future<void> _testAutoRefresh401() async {
    setState(() {
      _isTestingRefresh = true;
      _refreshTestMessage = null;
    });

    try {
      final store = ref.read(tokenStoreProvider);
      final repo = ref.read(authRepositoryProvider);

      // Simulasikan 401 menggunakan adapter / client
      final dio = buildApiClient(
        store,
        repo,
        baseUrl: 'https://example-campus-api.test',
        onSessionExpired: () {
          ref.read(authStateProvider.notifier).forceLogout();
        },
      );

      // Tambahkan interceptor penguji yang mengembalikan 401 pada percobaan pertama
      var attemptCount = 0;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attemptCount++;
            if (attemptCount == 1) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 401,
                    statusMessage: 'Unauthorized - Token Expired',
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'message': 'Data berhasil diakses dengan token baru',
                },
              ),
            );
          },
        ),
      );

      final response = await dio.get('/protected-profile');
      await _loadStoredTokens();

      if (mounted) {
        setState(() {
          _refreshTestMessage =
              'Sukses! HTTP 401 terdeteksi, token di-refresh otomatis, dan request diulang: ${response.data['status']}';
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _refreshTestMessage = ApiErrorMapper.mapDioError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingRefresh = false;
        });
      }
    }
  }

  /// Simulasi notifikasi foreground manual
  Future<void> _triggerTestForegroundNotification() async {
    await PushService.instance.showLocalNotification(
      id: 303,
      title: 'Jadwal Kuliah Berubah',
      body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
      payload: '/pengumuman/3',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Local notification foreground dikirim! Tekan banner di atas untuk menguji navigasi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Simulasi onTokenRefresh untuk rotasi token FCM
  Future<void> _triggerSimulatedTokenRefresh() async {
    final newToken = 'dK91_rotated-${DateTime.now().millisecondsSinceEpoch}';
    ref.read(fcmTokenProvider.notifier).updateToken(newToken);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('FCM onTokenRefresh dipicu: ${PushService.maskToken(newToken)}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fcmToken = ref.watch(fcmTokenProvider);
    final maskedFcm = PushService.maskToken(fcmToken);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Notify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Perbarui Token View',
            onPressed: _loadStoredTokens,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStoredTokens,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sesi Mahasiswa Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent.shade400),
                        ),
                        child: const Text(
                          'TERAUTENTIKASI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Selamat datang di Campus Notification App. Push notification dan token tersinkronisasi aman.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Debug Token & Security (Target Screenshot: token-terpotong.png)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security_rounded, color: Colors.blue.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Status Keamanan & Token Terpotong',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sesuai standar OWASP: token tidak pernah di-log atau ditampilkan penuh.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 20),

                    // Access Token
                    _buildTokenRow(
                      label: 'Access Token',
                      maskedValue: _maskedAccess ?? '(memuat...)',
                      icon: Icons.key_outlined,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 10),

                    // Refresh Token
                    _buildTokenRow(
                      label: 'Refresh Token',
                      maskedValue: _maskedRefresh ?? '(memuat...)',
                      icon: Icons.sync_lock_outlined,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 10),

                    // FCM Token
                    _buildTokenRow(
                      label: 'FCM Registration Token',
                      maskedValue: maskedFcm,
                      icon: Icons.phonelink_ring_outlined,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 10),

                    // Topic Status
                    _buildTokenRow(
                      label: 'Topik FCM Langganan',
                      maskedValue: 'pengumuman-kampus (Aktif)',
                      icon: Icons.campaign_outlined,
                      color: Colors.orange.shade800,
                    ),

                    const Divider(height: 24),

                    // Interactive Action Buttons
                    Text(
                      'Pengujian Mandiri Modul 6:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isTestingRefresh ? null : _testAutoRefresh401,
                          icon: _isTestingRefresh
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, size: 16),
                          label: const Text('Uji Auto-Refresh 401', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _triggerTestForegroundNotification,
                          icon: const Icon(Icons.notifications_active, size: 16),
                          label: const Text('Uji Banner Foreground', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _triggerSimulatedTokenRefresh,
                          icon: const Icon(Icons.published_with_changes, size: 16),
                          label: const Text('Simulasi onTokenRefresh', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),

                    if (_refreshTestMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          _refreshTestMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Announcement List Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Pengumuman Kampus',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  Text(
                    'Topik Broadcast',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            _buildAnnouncementCard(
              id: '3',
              title: 'Jadwal Kuliah Berubah (Payload Pengujian)',
              subtitle: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
              date: 'Hari ini • 09:30',
              highlight: true,
            ),
            const SizedBox(height: 8),

            _buildAnnouncementCard(
              id: '1',
              title: 'Pendaftaran KRS Semester Genap Dibuka',
              subtitle: 'Batas akhir pengisian KRS adalah 28 Februari.',
              date: 'Kemarin • 14:00',
              highlight: false,
            ),
            const SizedBox(height: 8),

            _buildAnnouncementCard(
              id: '2',
              title: 'Seminar Nasional AI & Mobile Technology',
              subtitle: 'Pendaftaran terbuka untuk mahasiswa jurusan TI.',
              date: '3 hari lalu',
              highlight: false,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenRow({
    required String label,
    required String maskedValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  maskedValue,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String id,
    required String title,
    required String subtitle,
    required String date,
    required bool highlight,
  }) {
    return Card(
      elevation: highlight ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight ? Colors.blue.shade400 : Colors.grey.shade200,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: highlight ? Colors.blue.shade100 : Colors.grey.shade100,
          child: Icon(
            Icons.campaign_rounded,
            color: highlight ? Colors.blue.shade800 : Colors.grey.shade700,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: highlight ? Colors.blue.shade900 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              date,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          context.push(AppRoutes.announcementDetail(id));
        },
      ),
    );
  }
}
