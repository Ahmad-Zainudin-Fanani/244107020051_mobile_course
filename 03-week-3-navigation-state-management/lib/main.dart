import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/stats_page.dart';
import 'pages/todo_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

// Layout Shell dengan NavigationBar untuk berpindah halaman
class MainShellLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'Daftar ToDo',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}

// Konfigurasi GoRouter dengan StatefulShellRoute agar state tetap bertahan saat berpindah halaman
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TodoPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - ToDo & Stats App',
      routerConfig: _router,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    );
  }
}
