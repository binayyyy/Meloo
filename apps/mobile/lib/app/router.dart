import 'package:flutter/material.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home/event_detail_screen.dart';
import 'screens/home/payment_result_screen.dart';
import 'screens/home/role_home_screen.dart';
import 'screens/loading_screen.dart';
import 'session/auth_controller.dart';
import 'session/auth_scope.dart';

class AppRouter {
  AppRouter(this.authController);

  static const root = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const eventDetail = '/events/detail';
  static const paymentResult = '/payments/result';

  final AuthController authController;
  final navigatorKey = GlobalKey<NavigatorState>();

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? root;

    if (routeName == home && !authController.isAuthenticated) {
      return _build(const LoginScreen(), login);
    }

    if ((routeName == login ||
            routeName == signUp ||
            routeName == forgotPassword) &&
        authController.isAuthenticated) {
      return _build(const RoleHomeScreen(), home);
    }

    switch (routeName) {
      case root:
        return _build(const LoadingScreen(), root);
      case login:
        return _build(const LoginScreen(), login);
      case signUp:
        return _build(const SignUpScreen(), signUp);
      case forgotPassword:
        return _build(const ForgotPasswordScreen(), forgotPassword);
      case home:
        return _build(const RoleHomeScreen(), home);
      case eventDetail:
        final args = settings.arguments as EventDetailScreenArgs;
        return _build(EventDetailScreen(args: args), eventDetail);
      case paymentResult:
        final args = settings.arguments as PaymentResultScreenArgs;
        return _build(PaymentResultScreen(args: args), paymentResult);
      default:
        return _build(const LoginScreen(), login);
    }
  }

  MaterialPageRoute<void> _build(Widget page, String name) {
    return MaterialPageRoute<void>(
      builder: (_) => AuthScope(
        controller: authController,
        child: page,
      ),
      settings: RouteSettings(name: name),
    );
  }
}
