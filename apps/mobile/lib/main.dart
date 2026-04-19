import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'app/app.dart';
import 'app/session/auth_controller.dart';
import 'app/session/auth_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authController = AuthController();
  final demoSessionB64 = Uri.base.queryParameters['demo_session_b64'];
  if (demoSessionB64 != null && demoSessionB64.isNotEmpty) {
    final decoded = utf8.decode(base64.decode(demoSessionB64));
    authController.bootstrapDemoSession(
      AuthSession.fromJson(jsonDecode(decoded) as Map<String, dynamic>),
    );
  } else {
    await authController.restoreSession();
  }
  runApp(SmartEventMobileApp(authController: authController));
}
