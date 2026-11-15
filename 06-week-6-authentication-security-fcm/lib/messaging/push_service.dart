import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../routes.dart';

/// Top-level background message handler for FCM.
/// Wajib memiliki anotasi @pragma('vm:entry-point') karena dieksekusi pada isolate terpisah.
/// PENTING: Dilarang mengakses BuildContext atau Riverpod di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Hanya melakukan operasi pencatatan ringan atau sinkronisasi lokal.
  if (kDebugMode) {
    debugPrint('[FCM Background] Message received: ${message.messageId}');
  }
}

/// Global pending deep link yang ditangkap dari interaksi notifikasi
String? pendingDeepLink;

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void Function(String route)? _navigateCallback;
  Future<void> Function(String token)? _tokenUpdateCallback;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Inisialisasi Firebase Core secara aman
  Future<bool> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      // Daftarkan background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Firebase.initializeApp note: $e');
      }
      return false;
    }
  }

  /// Meminta izin notifikasi (Wajib untuk Android 13+ dan iOS)
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] requestPermission error: $e');
      }
      return false;
    }
  }

  /// Inisialisasi flutter_local_notifications untuk banner foreground
  Future<void> initLocalNotifications({
    void Function(String route)? onNotificationTapped,
  }) async {
    _navigateCallback = onNotificationTapped;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          pendingDeepLink = payload;
          _navigateCallback?.call(payload);
        }
      },
    );

    // Buat notification channel Android
    const androidChannel = AndroidNotificationChannel(
      'pengumuman',
      'Pengumuman Kampus',
      description: 'Saluran untuk push notifikasi pengumuman kampus penting',
      importance: Importance.high,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(androidChannel);
  }

  /// Token Lifecycle: Ambil token, kirim ke backend/callback, dan dengarkan onTokenRefresh
  Future<String?> initFcmToken({
    required Future<void> Function(String token) onToken,
  }) async {
    _tokenUpdateCallback = onToken;
    String? token;

    try {
      // ignore: deprecated_member_use
      token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('FCM device registered: ${maskToken(token)}');
        }
        await onToken(token);
      }

      // Listener onTokenRefresh: WAJIB ADA agar backend tidak menyimpan token basi saat rotasi
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          // ignore: deprecated_member_use
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          debugPrint(
              '[FCM] onTokenRefresh triggered: ${maskToken(newToken)}');
        }
        await _tokenUpdateCallback?.call(newToken);
      });

      // Langganan topik pengumuman-kampus untuk broadcast
      await subscribeToTopic('pengumuman-kampus');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] initFcmToken fallback note: $e');
      }
      // Simulasi token fallback jika berjalan tanpa kredensial google-services
      token = 'dK91_fcm-token-campus-${DateTime.now().millisecondsSinceEpoch}';
      await onToken(token);
    }

    return token;
  }

  /// Listener pesan saat aplikasi berada di Foreground
  void listenForeground(void Function(String route) go) {
    _navigateCallback = go;

    try {
      // Foreground: Sistem TIDAK menampilkan banner otomatis di foreground.
      // Kita tampilkan manual via flutter_local_notifications.
      FirebaseMessaging.onMessage.listen((message) async {
        final dataMap = message.data;
        final targetRoute = routeFromMessage(dataMap);

        final title = message.notification?.title ?? 'Pengumuman Kampus';
        final body = message.notification?.body ?? 'Ada pengumuman baru untuk Anda.';

        await showLocalNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: targetRoute,
        );
      });

      // Background: Banner sistem diklik saat aplikasi di-minimize
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final targetRoute = routeFromMessage(message.data);
        go(targetRoute);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] listenForeground note: $e');
      }
    }
  }

  /// Menangani navigasi saat aplikasi dibuka dari keadaan Terminated (mati total)
  Future<void> handleTerminated(void Function(String route) go) async {
    _navigateCallback = go;

    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final targetRoute = routeFromMessage(initialMessage.data);
        go(targetRoute);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] handleTerminated note: $e');
      }
    }

    if (pendingDeepLink != null) {
      final route = pendingDeepLink!;
      pendingDeepLink = null;
      go(route);
    }
  }

  /// Tampilkan notifikasi lokal secara manual
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      channelDescription:
          'Saluran untuk push notifikasi pengumuman kampus penting',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Berlangganan topik FCM
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] subscribeToTopic error: $e');
      }
    }
  }

  /// Berhenti langganan topik FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] unsubscribeFromTopic error: $e');
      }
    }
  }

  /// Helper untuk memotong token agar aman ditampilkan pada layar dan laporan
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '(tidak ada token)';
    if (token.length <= 8) return '$token...';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
