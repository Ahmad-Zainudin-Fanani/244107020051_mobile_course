import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'pages/settings_page.dart';
import 'data/prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsRepo = PrefsRepository();
  await prefsRepo.initLastOpened();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;
    final router = ref.watch(routerProvider);

    const tealPrimary = Color(0xFF00796B);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Catatan Offline',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F6F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: tealPrimary,
          brightness: Brightness.light,
          primary: tealPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F6F4),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1412),
        colorScheme: ColorScheme.fromSeed(
          seedColor: tealPrimary,
          brightness: Brightness.dark,
          primary: const Color(0xFF26A69A),
          surface: const Color(0xFF151E1B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1412),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF16201D),
          elevation: 0,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
