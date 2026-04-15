import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.init();
  runApp(SmartCampusApp(api: api));
}

class SmartCampusApp extends StatelessWidget {
  final ApiService api;

  const SmartCampusApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: api,
      child: Builder(
        builder: (context) {
          final router = createRouter(context.read<ApiService>());
          return MaterialApp.router(
            title: 'Smart Campus',
            theme: appTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
