// Path: lib/main.dart
// Path: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
import 'screens/update_screen.dart';
import 'utils/version_helper.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/user.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version; // Reads "1.2.3" from pubspec.yaml
});

/// Provider that caches the version string once loaded (for sync access)
final cachedAppVersionProvider = StateProvider<String?>((ref) => null);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await StorageService.init();

  // 1. Firebase
  await Firebase.initializeApp();
  await FcmService.instance.init(navigatorKey);

  // 2. Local notifications init (permissions requested inside)
  await NotificationService.instance.init();

  // 3. scheduleAll() now internally checks permissions before scheduling
  await NotificationService.instance.scheduleAll();

  // 4. Dependency injection, orientation, etc.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MarkazAlFurqanApp(),
    ),
  );
}

class MarkazAlFurqanApp extends ConsumerStatefulWidget {
  const MarkazAlFurqanApp({super.key});

  @override
  ConsumerState<MarkazAlFurqanApp> createState() => _MarkazAlFurqanAppState();
}

class _MarkazAlFurqanAppState extends ConsumerState<MarkazAlFurqanApp>
    with WidgetsBindingObserver {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.scheduleAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.scheduleAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX 2: Listen for auth state changes and force the router to refresh
    ref.listen(authServiceProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        _router?.refresh();
      }
    });

    final versionAsync = ref.watch(appVersionProvider);

    return versionAsync.when(
      data: (currentAppVersion) {
        // FIX 1: Delay the provider modification until after the build phase
        Future.microtask(() {
          if (ref.read(cachedAppVersionProvider) != currentAppVersion) {
            ref.read(cachedAppVersionProvider.notifier).state =
                currentAppVersion;
          }
        });

        // Notice we no longer pass authState here!
        _router ??= _createRouter(currentAppVersion);

        return MaterialApp.router(
          title: 'مركز الفرقان لتحفيظ القرآن',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router!,
        );
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF071A14),
          body: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFC4973A),
            ),
          ),
        ),
      ),
      error: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF071A14),
          body: Center(
            child: Text(
              'حدث خطأ في تحميل التطبيق',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Removed AuthState parameter so we don't trap a stale state in a closure
  GoRouter _createRouter(String currentAppVersion) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        // FIX 2 (Cont.): Always read the freshest auth state directly inside the redirect!
        final authState = ref.read(authServiceProvider);

        final requiredVersion = authState.minimumRequiredVersion;

        if (requiredVersion != null && requiredVersion.isNotEmpty) {
          final needsUpdate = VersionHelper.isUpdateRequired(
            currentAppVersion,
            requiredVersion,
          );

          if (needsUpdate) {
            if (state.matchedLocation != '/update') {
              return '/update';
            }
            return null;
          }
        }

        if (state.matchedLocation == '/update') {
          return '/splash';
        }

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
          path: '/update',
          builder: (context, state) => const UpdateScreen(),
        ),
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
        ShellRoute(
          builder: (context, state, child) => StudentMainScreen(child: child),
          routes: [
            GoRoute(
              path: '/student/home',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              ),
            ),
            GoRoute(
              path: '/student/progress',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProgressScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              ),
            ),
            GoRoute(
              path: '/student/profile',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              ),
            ),
            GoRoute(
              path: '/student/courses',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const MyCoursesScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor =
        isDark ? const Color(0xFF0C1E16) : const Color(0xFFFFFFFF);
    final navBarIconBrightness = isDark ? Brightness.light : Brightness.dark;

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

class StudentBottomNavBar extends StatelessWidget {
  const StudentBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0C1E16) : Colors.white;
    final activeColor =
        isDark ? const Color(0xFFC4973A) : const Color(0xFF0E5A38);
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
    Color activeColor,
  ) {
    final isSelected = index == currentIndex;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: isSelected ? 4.0 : 0.0,
          top: isSelected ? 0.0 : 4.0,
        ),
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
