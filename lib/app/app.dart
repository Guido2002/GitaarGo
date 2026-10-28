import '../features/update/update_panel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state.dart';
import '../features/home/home_screen.dart';
import '../features/learning/learning_screen.dart';
import '../features/tuner/tuner_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/leren', builder: (_, _) => const LearningScreen()),
          GoRoute(
            path: '/spelen',
            builder: (_, _) => const PlayLibraryScreen(),
          ),
          GoRoute(path: '/stemmen', builder: (_, _) => const TunerScreen()),
          GoRoute(path: '/profiel', builder: (_, _) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/oefenen',
        builder: (_, state) => PracticeScreen(
          exerciseId: state.uri.queryParameters['id'],
          game: state.uri.queryParameters['game'] == '1',
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF9370FF),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFAE94FF) : const Color(0xFF6943D2),
        secondary: dark ? const Color(0xFF36D6BC) : const Color(0xFF006B5B),
        surface: dark ? const Color(0xFF101116) : const Color(0xFFF6F5FA),
      );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF1B1D26) : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class GitaarGoApp extends ConsumerWidget {
  const GitaarGoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.asData?.value['theme'] ?? 'dark';
    return MaterialApp.router(
      title: 'GitaarGo',
      debugShowCheckedModeBanner: false,
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: theme == 'light' ? ThemeMode.light : ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => settings.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          body: Center(
            child: Text('Lokale gegevens konden niet worden geopend: $e'),
          ),
        ),
        data: (data) =>
            data['onboarded'] == true ? child! : const OnboardingScreen(),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  final String path;
  final Widget child;
  const MainShell({required this.path, required this.child, super.key});
  @override
  Widget build(BuildContext context) {
    const paths = ['/', '/leren', '/spelen', '/stemmen', '/profiel'];
    return Scaffold(
      body: UpdateStartup(child: SafeArea(child: child)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: paths.indexOf(path).clamp(0, 4),
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'Vandaag',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Leren',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            label: 'Spelen',
          ),
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Stemmen'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profiel',
          ),
        ],
      ),
    );
  }
}
