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
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuthStateChange());
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
    final paymentSignature = 'payment:$paymentResult:$paymentSessionId:$eventId';
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
    const brand = Color(0xFF145B52);
    const accent = Color(0xFFBA7B2F);
    const surface = Color(0xFFFFFCF7);
    const ink = Color(0xFF1F1B17);

    return MaterialApp(
      title: 'Smart Event Hub',
      debugShowCheckedModeBanner: false,
      navigatorKey: _router.navigatorKey,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: brand,
          secondary: accent,
          surface: surface,
          error: Color(0xFFAF3D31),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4EFE6),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: ink,
              displayColor: ink,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F2E8),
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Color(0xFF60584D),
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: Color(0xFF958B7E)),
          helperStyle: const TextStyle(color: Color(0xFF6D665A)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD7CCBC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD7CCBC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: brand, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFAF3D31)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFAF3D31), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFB5C8C1),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: Color(0xFFD7CCBC)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF2ECE1),
          selectedColor: const Color(0xFFE3F0EC),
          disabledColor: const Color(0xFFE7E1D8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          side: const BorderSide(color: Color(0xFFE2D6C6)),
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
            side: const BorderSide(color: Color(0xFFE2D7C9)),
          ),
        ),
        useMaterial3: true,
      ),
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: AppRouter.root,
    );
  }
}
