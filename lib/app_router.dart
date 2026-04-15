import 'package:go_router/go_router.dart';

import 'screens/attendance_screen.dart';
import 'screens/complaint_list_screen.dart';
import 'screens/complaint_submit_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_complaints_screen.dart';
import 'services/api_service.dart';

GoRouter createRouter(ApiService api) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: api,
    redirect: (context, state) {
      final loggedIn = api.isLoggedIn;
      final loc = state.matchedLocation;
      final isAuth = loc == '/login' || loc == '/register';
      if (!loggedIn && !isAuth) return '/login';
      if (loggedIn && isAuth) return '/home';
      if (loc.startsWith('/admin') && !(api.user?.isAdmin ?? false)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/complaints/submit', builder: (_, __) => const ComplaintSubmitScreen()),
      GoRoute(path: '/complaints/list', builder: (_, __) => const ComplaintListScreen()),
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/admin/complaints', builder: (_, __) => const AdminComplaintsScreen()),
    ],
  );
}
