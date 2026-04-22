// Path: lib/main.dart

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

      // Themes from AppThemes class
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

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
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: '/student/courses',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const MyCoursesScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: '/student/progress',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProgressScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
            GoRoute(
              path: '/student/profile',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Student Main Screen with AnnotatedRegion ────────────────────────────────
class StudentMainScreen extends StatelessWidget {
  final Widget child;

  const StudentMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // الألوان المستقاة من الستايل الخاص بك (Deep Forest للداكن والبيج للفاتح)
    final navBarColor =
        isDark ? const Color(0xFF0C1E16) : const Color(0xFFFFFFFF);
    final navBarIconBrightness = isDark ? Brightness.light : Brightness.dark;

    // AnnotatedRegion تضمن تطبيق ألوان الـ System Bar مباشرة وتتغير فوراً عند تبديل الثيم
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: navBarIconBrightness,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: navBarIconBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        body: child,
        bottomNavigationBar: const StudentBottomNavBar(),
      ),
    );
  }
}

// ─── Animated Bottom Nav Bar ───────────────────────────────────────────────
class StudentBottomNavBar extends StatelessWidget {
  const StudentBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // استخراج ألوانك المميزة
    final bgColor = isDark ? const Color(0xFF0C1E16) : Colors.white;
    final activeColor = isDark
        ? const Color(0xFFC4973A)
        : const Color(0xFF0E5A38); // ذهبي في الداكن، غابة في الفاتح
    final inactiveColor =
        isDark ? const Color(0x77F0E6C8) : const Color(0xFF88A090);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        currentIndex: _getCurrentIndex(currentLocation),
        onTap: (index) => _onItemTapped(context, index),
        items: [
          _buildNavItem(0, _getCurrentIndex(currentLocation),
              Icons.home_rounded, Icons.home_outlined, 'الرئيسية', activeColor),
          _buildNavItem(
              1,
              _getCurrentIndex(currentLocation),
              Icons.menu_book_rounded,
              Icons.book_outlined,
              'دوراتي',
              activeColor),
          _buildNavItem(
              2,
              _getCurrentIndex(currentLocation),
              Icons.trending_up_rounded,
              Icons.trending_up_outlined,
              'التقدم',
              activeColor),
          _buildNavItem(
              3,
              _getCurrentIndex(currentLocation),
              Icons.person_rounded,
              Icons.person_outline_rounded,
              'حسابي',
              activeColor),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      int index,
      int currentIndex,
      IconData activeIcon,
      IconData inactiveIcon,
      String label,
      Color activeColor) {
    final isSelected = index == currentIndex;

    return BottomNavigationBarItem(
      // استخدام AnimatedContainer داخل الأيقونة لإضافة حركة عند التبديل
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
            bottom: isSelected ? 4.0 : 0.0, top: isSelected ? 0.0 : 4.0),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          size: isSelected ? 26 : 24,
        ),
      ),
      label: label,
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
