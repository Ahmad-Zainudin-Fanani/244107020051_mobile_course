import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase & Messaging
  await PushService.instance.initializeFirebase();
  await PushService.instance.requestNotificationPermission();

  runApp(
    const ProviderScope(
      child: CampusNotifyApp(),
    ),
  );
}

/// Helper Listenable untuk menghubungkan Riverpod Auth State dengan GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  return GoRouterRefreshStream(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value ?? false;
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;

      // Guard Route: Belum login harus ke /login
      if (!isLoggedIn && !isGoingToLogin) {
        return AppRoutes.login;
      }

      // Bila sudah login dan berada di /login, arahkan ke beranda
      if (isLoggedIn && isGoingToLogin) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AnnouncementPage(id: id);
        },
      ),
    ],
  );
});

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMessaging();
    });
  }

  Future<void> _setupMessaging() async {
    final router = ref.read(routerProvider);

    // Inisialisasi notifikasi lokal dengan routing callback
    await PushService.instance.initLocalNotifications(
      onNotificationTapped: (route) {
        router.go(route);
      },
    );

    // Inisialisasi token FCM & pantau rotasi (onTokenRefresh)
    final token = await PushService.instance.initFcmToken(
      onToken: (newToken) async {
        ref.read(fcmTokenProvider.notifier).updateToken(newToken);
        if (kDebugMode) {
          debugPrint(
            '[FCM Backend Sync] POST /devices payload: {"fcm_token": "${PushService.maskToken(newToken)}", "platform": "android"}',
          );
        }
      },
    );

    if (token != null) {
      ref.read(fcmTokenProvider.notifier).updateToken(token);
    }

    // Dengarkan pesan foreground & background banner click
    PushService.instance.listenForeground((route) {
      router.go(route);
    });

    // Tangani navigasi jika aplikasi dibuka dari keadaan Terminated
    await PushService.instance.handleTerminated((route) {
      router.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
