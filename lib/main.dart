import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/app_colors.dart';
import 'constants/app_themes.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/home_screen.dart';
import 'screens/student/my_courses_screen.dart';
import 'screens/student/progress_screen.dart';
import 'screens/student/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MarkazAlFurqanApp()));
}

class MarkazAlFurqanApp extends ConsumerWidget {
  const MarkazAlFurqanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);

    return MaterialApp.router(
      title: 'مركز الفرقان لتحفيظ القرآن',
      debugShowCheckedModeBanner: false,

      // Localization
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.light,

      // Routing
      routerConfig: _createRouter(authState),
    );
  }

  GoRouter _createRouter(AuthState authState) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn && !isLoggingIn && state.matchedLocation != '/splash') {
          return '/login';
        }

        if (isLoggedIn && isLoggingIn) {
          return '/student/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Student Routes
        ShellRoute(
          builder: (context, state, child) => StudentMainScreen(child: child),
          routes: [
            GoRoute(
              path: '/student/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/student/courses',
              builder: (context, state) => const MyCoursesScreen(),
            ),
            GoRoute(
              path: '/student/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
            GoRoute(
              path: '/student/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class StudentMainScreen extends StatelessWidget {
  final Widget child;

  const StudentMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const StudentBottomNavBar(),
    );
  }
}

class StudentBottomNavBar extends StatelessWidget {
  const StudentBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      currentIndex: _getCurrentIndex(currentLocation),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: 'دوراتي',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up_outlined),
          activeIcon: Icon(Icons.trending_up),
          label: 'التقدم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'الملف الشخصي',
        ),
      ],
    );
  }

  int _getCurrentIndex(String location) {
    if (location.contains('/home')) return 0;
    if (location.contains('/courses')) return 1;
    if (location.contains('/progress')) return 2;
    if (location.contains('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student/home');
        break;
      case 1:
        context.go('/student/courses');
        break;
      case 2:
        context.go('/student/progress');
        break;
      case 3:
        context.go('/student/profile');
        break;
    }
  }
}
