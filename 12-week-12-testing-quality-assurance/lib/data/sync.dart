import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sakelar simulasi offline yang dipakai layar Pengaturan dan app bar catatan.
///
/// Catatan pembersihan: berkas ini sebelumnya juga memuat `SyncService`,
/// `PostsSyncService`, serta provider repository versi lama. Semua bagian itu
/// tidak lagi dirujuk dari `lib/main.dart` maupun test, sehingga dihapus agar
/// tidak menurunkan cakupan kode dan tidak membingungkan pembaca.
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool val) => state = val;
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);
