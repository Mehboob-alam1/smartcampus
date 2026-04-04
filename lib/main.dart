import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'app_router.dart';
import 'services/auth_service.dart';
import 'services/complaint_service.dart';
import 'services/attendance_service.dart';
import 'services/notification_service.dart';

// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(NotificationService.onMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(NotificationService.onMessageOpenedApp);
  runApp(const SmartCampusApp());
}

class SmartCampusApp extends StatelessWidget {
  const SmartCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ComplaintService()),
        Provider(create: (_) => AttendanceService()),
        Provider(create: (_) => NotificationService()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Smart Campus',
            locale: const Locale('en'),
            theme: appTheme,
            routerConfig: createRouter(context),
          );
        },
      ),
    );
  }
}
