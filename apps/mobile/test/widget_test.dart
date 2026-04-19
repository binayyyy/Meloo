import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_event_mobile/app/app.dart';
import 'package:smart_event_mobile/app/session/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the mobile scaffold shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final authController = AuthController();
    await authController.restoreSession();

    await tester.pumpWidget(
      SmartEventMobileApp(authController: authController),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Need an account?'), findsOneWidget);
  });
}
