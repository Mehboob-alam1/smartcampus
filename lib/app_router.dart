import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'models/app_user.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/complaints_screen.dart';
import 'screens/complaint_submit_screen.dart';
import 'screens/complaint_detail_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/face_register_screen.dart';
import 'screens/admin/admin_complaints_screen.dart';
import 'screens/admin/admin_complaint_detail_screen.dart';
import 'screens/admin/admin_attendance_screen.dart';
import 'services/auth_service.dart';

/// Notifies [GoRouter] when auth session changes so redirects run again.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final _authRefreshNotifier = _AuthRefreshNotifier();

GoRouter createRouter(BuildContext context) {
  final auth = context.read<AuthService>();
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _authRefreshNotifier,
    redirect: (context, state) async {
      final user = auth.currentUser;
      AppUser? appUser;
      try {
        appUser = user != null ? await auth.getCurrentAppUser() : null;
      } catch (e, st) {
        debugPrint('getCurrentAppUser failed: $e\n$st');
        return '/login';
      }
      final path = state.matchedLocation;
      final isLogin = path == '/login';
      final isSplash = path == '/';

      if (isSplash) {
        return user != null && appUser != null ? '/home' : '/login';
      }
      if (user == null) {
        return isLogin ? null : '/login';
      }
      if (appUser == null) {
        return isLogin ? null : '/login';
      }
      if (isLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) {
          return FutureBuilder<AppUser?>(
            future: auth.getCurrentAppUser(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load profile: ${snap.error}', textAlign: TextAlign.center),
                    ),
                  ),
                );
              }
              final u = snap.data;
              if (u == null) {
                return const Scaffold(
                  body: Center(child: Text('No profile available. Please sign in again.')),
                );
              }
              return HomeScreen(user: u);
            },
          );
        },
      ),
      GoRoute(
        path: '/complaints',
        builder: (_, __) => const ComplaintsScreen(),
        routes: [
          GoRoute(
            path: 'submit',
            builder: (_, __) => const ComplaintSubmitScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return ComplaintDetailScreen(complaintId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/attendance',
        builder: (_, __) => const AttendanceScreen(),
        routes: [
          GoRoute(
            path: 'register-face',
            builder: (_, __) => const FaceRegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/complaints',
        builder: (_, __) => const AdminComplaintsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return AdminComplaintDetailScreen(complaintId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/attendance',
        builder: (_, __) => const AdminAttendanceScreen(),
      ),
    ],
  );
}
