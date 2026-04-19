import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.eyebrow = 'Smart Event Hub',
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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF4EFE6),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -140,
                left: -80,
                child: _GlowOrb(
                  size: 260,
                  color: const Color(0x1F145B52),
                ),
              ),
              Positioned(
                top: 120,
                right: -90,
                child: _GlowOrb(
                  size: 220,
                  color: const Color(0x14C28B36),
                ),
              ),
              Positioned(
                bottom: -110,
                left: 20,
                child: _GlowOrb(
                  size: 240,
                  color: const Color(0x16CC7A00),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFD9D0C3)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A1F1A14),
                            blurRadius: 40,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F0EC),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                eyebrow,
                                style: const TextStyle(
                                  color: Color(0xFF145B52),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.02,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Color(0xFF5E5A54),
                                fontSize: 15,
                                height: 1.55,
                              ),
                            ),
                            if (highlights.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: highlights
                                    .map(
                                      (item) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2ECE1),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: const Color(0xFFE3D9CA),
                                          ),
                                        ),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF403A32),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                            const SizedBox(height: 28),
                            child,
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 18),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE7DDCF)),
                                ),
                              ),
                              child: footer,
                            ),
                          ],
                        ),
                      ),
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
