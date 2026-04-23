import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.eyebrow = 'Meloo network',
    this.highlights = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;
  final String eyebrow;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F1E6),
              Color(0xFFF2E5D5),
              Color(0xFFF9F7F2),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -170,
                left: -130,
                child: _GlowOrb(size: 360, color: Color(0x22D8A548)),
              ),
              const Positioned(
                top: 80,
                right: -90,
                child: _GlowOrb(size: 300, color: Color(0x181AB2C4)),
              ),
              const Positioned(
                bottom: -140,
                left: 20,
                child: _GlowOrb(size: 320, color: Color(0x14132A4A)),
              ),
              const Positioned(
                bottom: 120,
                right: -80,
                child: _GlowOrb(size: 240, color: Color(0x1AD8A548)),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 820;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(38),
                            border: Border.all(color: const Color(0x1F5C4530)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x241F160F),
                                blurRadius: 50,
                                offset: Offset(0, 24),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 20 : 28),
                            child: Flex(
                              direction: compact ? Axis.vertical : Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, _) {
                                      return DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(32),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF0F1F3C),
                                              Color(0xFF163C64),
                                              Color(0xFF5D5A4F),
                                            ],
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x261F160F),
                                              blurRadius: 38,
                                              offset: Offset(0, 20),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(compact ? 22 : 28),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const _BrandLockup(),
                                              SizedBox(
                                                height: compact ? 96 : 180,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.12),
                                                  ),
                                                ),
                                                child: Text(
                                                  eyebrow,
                                                  style: const TextStyle(
                                                    color: Color(0xFFF8F3EA),
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              const Text(
                                                'Live events,\ncleanly connected.',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 34,
                                                  height: 1.02,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.9,
                                                ),
                                              ),
                                              if (highlights.isNotEmpty) ...[
                                                const SizedBox(height: 20),
                                                Wrap(
                                                  spacing: 10,
                                                  runSpacing: 10,
                                                  children: highlights
                                                      .take(compact ? 2 : 4)
                                                      .map(
                                                        (item) => _FeatureChip(
                                                          label: item,
                                                        ),
                                                      )
                                                      .toList(growable: false),
                                                ),
                                              ],
                                              const SizedBox(height: 20),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: compact ? 0 : 26,
                                  height: compact ? 20 : 0,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: compact ? 0 : 4,
                                      top: compact ? 2 : 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.displaySmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.1,
                                            color: const Color(0xFF18161F),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          subtitle,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: const Color(0xFF625867),
                                            height: 1.68,
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        child,
                                        const SizedBox(height: 24),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.only(top: 18),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: Color(0x1F5C4530),
                                              ),
                                            ),
                                          ),
                                          child: footer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                                      },
                                    ),
                                  ),
                                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/branding/meloo-logo-v1.png',
          height: 52,
          fit: BoxFit.contain,
          semanticLabel: 'Meloo',
        ),
        const SizedBox(height: 10),
        const Text(
          'Live event discovery and operations',
          style: TextStyle(
            color: Color(0xFFD8E2E6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
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
