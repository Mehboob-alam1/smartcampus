import 'package:flutter_test/flutter_test.dart';
import 'package:smartcampus/main.dart';
import 'package:smartcampus/services/api_service.dart';

void main() {
  testWidgets('App shows login when not authenticated', (WidgetTester tester) async {
    final api = ApiService();
    await api.init();
    await tester.pumpWidget(SmartCampusApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
