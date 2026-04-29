import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/screens/platform_access_blocked_screen.dart';
import 'app/session/auth_controller.dart';
import 'app/session/auth_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PlatformAccessBlockedScreen(),
      ),
    );
    return;
  }

  final authController = AuthController();
  final entrySessionB64 = Uri.base.queryParameters['entry_session_b64'];
  if (entrySessionB64 != null && entrySessionB64.isNotEmpty) {
    final decoded = utf8.decode(base64.decode(entrySessionB64));
    authController.bootstrapSession(
      AuthSession.fromJson(jsonDecode(decoded) as Map<String, dynamic>),
    );
  } else {
    await authController.restoreSession();
  }
  runApp(SmartEventMobileApp(authController: authController));
}
