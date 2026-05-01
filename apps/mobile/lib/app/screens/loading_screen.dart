import 'package:flutter/material.dart';
import '../widgets/brand_lockup.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6F8FA),
              Color(0xFFF0F4F7),
              Color(0xFFE9EEF2),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -120,
                right: -80,
                child: _GlowOrb(size: 280, color: Color(0x14355C7D)),
              ),
              const Positioned(
                bottom: -110,
                left: -60,
                child: _GlowOrb(size: 260, color: Color(0x102E4A62)),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final turn = _controller.value * 6.28318;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 156,
                          height: 156,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: turn,
                                child: Container(
                                  width: 148,
                                  height: 148,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0x22355C7D),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: -turn * 0.72,
                                child: Container(
                                  width: 118,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0x1E2E4A62),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12101828),
                                      blurRadius: 18,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Image.asset(
                                  'assets/branding/meloo-mark-v1.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const MelooBrandLockup(
                          showCaption: false,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Loading',
                          style: TextStyle(
                            color: Color(0xFF68737D),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
