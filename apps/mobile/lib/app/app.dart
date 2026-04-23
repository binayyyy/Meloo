import 'package:flutter/material.dart';
import 'screens/home/event_detail_screen.dart';
import 'screens/home/payment_result_screen.dart';
import 'router.dart';
import 'session/auth_controller.dart';

class SmartEventMobileApp extends StatefulWidget {
  const SmartEventMobileApp({
    required this.authController,
    super.key,
  });

  final AuthController authController;

  @override
  State<SmartEventMobileApp> createState() => _SmartEventMobileAppState();
}

class _SmartEventMobileAppState extends State<SmartEventMobileApp> {
  late final AppRouter _router;
  String? _lastDemoNavigationSignature;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(widget.authController);
    widget.authController.addListener(_handleAuthStateChange);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _handleAuthStateChange());
  }

  @override
  void dispose() {
    widget.authController.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  void _handleAuthStateChange() {
    if (widget.authController.isLoading) {
      return;
    }

    final navigator = _router.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final queryParameters = Uri.base.queryParameters;
    final demoRoute = queryParameters['demo_route'];

    if (!widget.authController.isAuthenticated) {
      final routeName = switch (demoRoute) {
        'signup' => AppRouter.signUp,
        'forgot-password' => AppRouter.forgotPassword,
        _ => AppRouter.login,
      };

      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
      _lastDemoNavigationSignature = routeName;
      return;
    }

    navigator.pushNamedAndRemoveUntil(AppRouter.home, (route) => false);

    final eventId = queryParameters['eventId'];
    final manageMode = queryParameters['manageMode'] == 'true';
    final paymentResult = queryParameters['payment'];
    final paymentSessionId = queryParameters['session_id'];
    final paymentSignature =
        'payment:$paymentResult:$paymentSessionId:$eventId';
    if ((paymentResult == 'success' || paymentResult == 'cancel') &&
        paymentSessionId != null &&
        _lastDemoNavigationSignature != paymentSignature) {
      _lastDemoNavigationSignature = paymentSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentNavigator = _router.navigatorKey.currentState;
        if (!mounted || currentNavigator == null) {
          return;
        }
        currentNavigator.pushNamed(
          AppRouter.paymentResult,
          arguments: PaymentResultScreenArgs(
            checkoutSessionId: paymentSessionId,
            eventId: eventId,
            paymentResult: paymentResult!,
          ),
        );
      });
      return;
    }

    final signature = '$demoRoute:$eventId:$manageMode';
    if (demoRoute == 'event-detail' &&
        eventId != null &&
        _lastDemoNavigationSignature != signature) {
      _lastDemoNavigationSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentNavigator = _router.navigatorKey.currentState;
        if (!mounted || currentNavigator == null) {
          return;
        }
        currentNavigator.pushNamed(
          AppRouter.eventDetail,
          arguments: EventDetailScreenArgs(
            eventId: eventId,
            manageMode: manageMode,
          ),
        );
      });
      return;
    }

    _lastDemoNavigationSignature = AppRouter.home;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF132A4A);
    const secondary = Color(0xFF1AB2C4);
    const tertiary = Color(0xFFD8A548);
    const surface = Color(0xFFFFFBF5);
    const ink = Color(0xFF17263D);
    const canvas = Color(0xFFF3EBDD);
    const outline = Color(0xFFDDD0BF);
    const muted = Color(0xFF686B72);

    return MaterialApp(
      title: 'Meloo',
      debugShowCheckedModeBanner: false,
      navigatorKey: _router.navigatorKey,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          surface: surface,
          error: Color(0xFFA44336),
        ),
        scaffoldBackgroundColor: canvas,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: ink,
              displayColor: ink,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF9F1),
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.84),
          labelStyle: const TextStyle(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: Color(0xFF8A8386)),
          helperStyle: const TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: secondary, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFA44336)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFA44336), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFB7C7D8),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: outline),
            backgroundColor: Colors.white.withValues(alpha: 0.52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF5ECDE),
          selectedColor: const Color(0xFFDFF5F4),
          disabledColor: const Color(0xFFE7DDCF),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          labelStyle: const TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: outline),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF9F2E9),
          indicatorColor: Color(0x1F2B9A84),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primary,
          contentTextStyle: ThemeData.light().textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        dividerColor: outline,
        useMaterial3: true,
      ),
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: AppRouter.root,
    );
  }
}
