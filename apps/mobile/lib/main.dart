import 'dart:convert';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/session/auth_controller.dart';
import 'app/session/auth_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
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
  } catch (error, stackTrace) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF8F3ED),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Color(0xFF17212B),
                    fontSize: 14,
                    height: 1.45,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App startup failed',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(error.toString()),
                      const SizedBox(height: 18),
                      Text(
                        stackTrace.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF55626E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
