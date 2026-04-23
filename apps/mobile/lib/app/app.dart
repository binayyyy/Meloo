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
    const primary = Color(0xFF102844);
    const secondary = Color(0xFF0FA6B8);
    const tertiary = Color(0xFFD39B3C);
    const surface = Color(0xFFFFFAF2);
    const surfaceSoft = Color(0xFFF7EFDF);
    const ink = Color(0xFF17263D);
    const canvas = Color(0xFFF1E7D7);
    const outline = Color(0xFFD8C7AF);
    const muted = Color(0xFF6D706F);
    final base = ThemeData.light();
    final textTheme = base.textTheme.copyWith(
      displayLarge: const TextStyle(
        color: ink,
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.4,
        height: 0.94,
      ),
      displayMedium: const TextStyle(
        color: ink,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.1,
        height: 0.98,
      ),
      headlineLarge: const TextStyle(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.9,
      ),
      headlineMedium: const TextStyle(
        color: ink,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: const TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
      ),
      titleMedium: const TextStyle(
        color: ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: const TextStyle(
        color: ink,
        fontSize: 15,
        height: 1.55,
      ),
      bodyMedium: const TextStyle(
        color: ink,
        fontSize: 14,
        height: 1.5,
      ),
      labelLarge: const TextStyle(
        color: ink,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      ),
    );

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
          surfaceContainerHighest: surfaceSoft,
          error: Color(0xFFA44336),
        ),
        scaffoldBackgroundColor: canvas,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F0E2),
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.88),
          labelStyle: const TextStyle(
            color: muted,
            fontWeight: FontWeight.w700,
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
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: outline),
            backgroundColor: Colors.white.withValues(alpha: 0.64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF6ECDC),
          selectedColor: const Color(0xFFD8F0EF),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF102844),
          foregroundColor: Colors.white,
          shape: StadiumBorder(),
          extendedTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: ink,
            backgroundColor: Colors.white.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF6EDDF),
          indicatorColor: Color(0x26249097),
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
          contentTextStyle: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: secondary,
          linearTrackColor: Color(0x33D39B3C),
          circularTrackColor: Color(0x33102844),
        ),
        dividerColor: outline,
        useMaterial3: true,
      ),
      onGenerateRoute: _router.onGenerateRoute,
      initialRoute: AppRouter.root,
    );
  }
}
