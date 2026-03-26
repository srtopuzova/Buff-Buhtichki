import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_theme.dart';
import 'package:medshelf/features/auth/providers/auth_provider.dart';
import 'package:medshelf/features/auth/screens/login_screen.dart';
import 'package:medshelf/features/auth/screens/signup_screen.dart';
import 'package:medshelf/features/home/screens/home_screen.dart';
import 'package:medshelf/features/med_shelf/screens/add_medication_screen.dart';
import 'package:medshelf/features/med_shelf/screens/medication_detail_screen.dart';
import 'package:medshelf/features/red_shelf/screens/add_prescription_screen.dart';
import 'package:medshelf/features/red_shelf/screens/prescription_detail_screen.dart';

class MedShelfApp extends StatefulWidget {
  const MedShelfApp({super.key});

  @override
  State<MedShelfApp> createState() => _MedShelfAppState();
}

class _MedShelfAppState extends State<MedShelfApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.status == AuthStatus.authenticated;
        final isOnAuthPage = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (auth.status == AuthStatus.unknown) return null;
        if (!isAuth && !isOnAuthPage) return '/login';
        if (isAuth && isOnAuthPage) return '/home';
        return null;
      },
      refreshListenable: Provider.of<AuthProvider>(
        // ignore: use_build_context_synchronously
        navigatorKey.currentContext ?? context,
        listen: false,
      ),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'med-shelf/add',
              builder: (context, state) => const AddMedicationScreen(),
            ),
            GoRoute(
              path: 'med-shelf/:id',
              builder: (context, state) => MedicationDetailScreen(
                medicationId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'red-shelf/add',
              builder: (context, state) => const AddPrescriptionScreen(),
            ),
            GoRoute(
              path: 'red-shelf/:id',
              builder: (context, state) => PrescriptionDetailScreen(
                prescriptionId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedShelf',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Stable router — GoRouter created once in initState to avoid rebuild crashes
class MedShelfAppRouter extends StatefulWidget {
  const MedShelfAppRouter({super.key});

  @override
  State<MedShelfAppRouter> createState() => _MedShelfAppRouterState();
}

class _MedShelfAppRouterState extends State<MedShelfAppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuth = authProvider.status == AuthStatus.authenticated;
        final isUnknown = authProvider.status == AuthStatus.unknown;
        final isOnAuthPage = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (isUnknown) return null;
        if (!isAuth && !isOnAuthPage) return '/login';
        if (isAuth && isOnAuthPage) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'med-shelf/add',
              builder: (context, state) => const AddMedicationScreen(),
            ),
            GoRoute(
              path: 'med-shelf/:id',
              builder: (context, state) => MedicationDetailScreen(
                medicationId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'red-shelf/add',
              builder: (context, state) => const AddPrescriptionScreen(),
            ),
            GoRoute(
              path: 'red-shelf/:id',
              builder: (context, state) => PrescriptionDetailScreen(
                prescriptionId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedShelf',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
