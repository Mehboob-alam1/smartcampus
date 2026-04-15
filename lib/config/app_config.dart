/// Backend API base URL (no trailing slash).
///
/// Android emulator → host machine: `http://10.0.2.2:3000`
/// iOS simulator: `http://127.0.0.1:3000`
/// Production: `https://your-app.vercel.app`
///
/// `flutter run --dart-define=API_BASE_URL=https://xxx.vercel.app`
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
