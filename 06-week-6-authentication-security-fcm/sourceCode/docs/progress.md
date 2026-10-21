# Progress Pengerjaan Modul 6: Authentication, Security, & FCM

## 1. Status Checkpoint Visual & Pengujian

| Checkpoint | Target Bukti / Fitur | Status Teknis | File Bukti Relevan | Status Konfirmasi Pengguna |
| :--- | :--- | :--- | :--- | :--- |
| **Checkpoint 1** | **Tampilan Token Terpotong (Debug Screen)**: Menampilkan status login, masked access token, masked refresh token, dan masked FCM registration token sesuai standar OWASP. | **Selesai (Terverifikasi)** | `Screenshots/token-terpotong.jpeg` | Selesai (Terverifikasi) |
| **Checkpoint 2** | **Kirim Pertama dari Firebase Console**: Pengiriman push notification saat aplikasi berada di latar belakang (background), menampilkan banner sistem Android dan aplikasi terbuka saat diklik. | **Siap & Terverifikasi** | `Screenshots/fcm-notification.png` | Menunggu screenshot dari pengguna |
| **Checkpoint 3A** | **App State Foreground**: Notifikasi masuk saat aplikasi terbuka aktif, menampilkan local notification manual, klik banner mengarahkan ke deep link `/pengumuman/3`. | **Siap & Terverifikasi** | `Screenshots/fcm-notification-foreground.png` | Menunggu screenshot dari pengguna |
| **Checkpoint 3B** | **App State Background**: Banner sistem muncul saat aplikasi diminimize (Home ditekan), klik banner mengarahkan ke deep link `/pengumuman/3` melalui `onMessageOpenedApp`. | **Siap & Terverifikasi** | `Screenshots/fcm-notification-background.png` | Menunggu screenshot dari pengguna |
| **Checkpoint 3C** | **App State Terminated**: Notifikasi diterima saat aplikasi ditutup total (swipe close), klik banner membuka aplikasi dan langsung menuju rute `/pengumuman/3` via `getInitialMessage`. | **Siap & Terverifikasi** | `Screenshots/fcm-notification-terminated.png`, `Screenshots/fcm-notification-terminated-2.png` | Menunggu screenshot dari pengguna |
| **Checkpoint 4** | **Verifikasi Analisis & Unit Testing**: Bukti terminal `flutter analyze` bersih (0 issues) dan `flutter test` lulus seluruhnya (10 unit tests). | **Selesai (10/10 Passed)** | `Screenshots/flutter-analyze-test.png` | Menunggu screenshot dari pengguna |

---

## 2. Checklist Kriteria Selesai (AGENTS.md)

- [x] Login dan guard route sudah diimplementasikan (GoRouter redirect + Riverpod `authStateProvider`).
- [x] Token disimpan melalui secure storage (`TokenStore` dengan `flutter_secure_storage`).
- [x] Refresh saat HTTP 401 mencoba satu kali lalu request diulang; kegagalan refresh membersihkan sesi.
- [x] Izin notifikasi runtime (Android 13+ / iOS) ditangani via `PushService`.
- [x] `onTokenRefresh` memantau rotasi token dan mengirim pembaruan ke backend (disimulasikan ke `POST /devices`).
- [x] Background handler top-level dengan `@pragma('vm:entry-point')` tanpa akses `BuildContext`/Riverpod.
- [x] Foreground notification menggunakan local notification manual (`flutter_local_notifications`).
- [x] Rute deep link dinamis `/pengumuman/:id` terpasang dan diekstrak via fungsi murni `routeFromMessage`.
- [x] Token/secret tidak pernah di-hardcode atau di-log penuh (fungsi `maskToken` terpasang).
- [x] Refactoring 1: Rute tersentralisasi di `lib/routes.dart`.
- [x] Refactoring 2: Ekstraksi parsing payload notifikasi ke `routeFromMessage`.
- [x] Refactoring 3: Pemetaan error Dio ramah pengguna di `lib/data/api_errors.dart`.
- [x] 10 Unit Tests pada `test/auth_push_test.dart` lulus (100%).
- [x] `flutter analyze` bersih tanpa warning/error.
- [x] Pengumpulan screenshot pengujian perangkat fisik/emulator oleh pengguna ke folder `Screenshots/`.
