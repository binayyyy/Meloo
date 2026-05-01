import 'package:flutter/material.dart';
import 'brand_lockup.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.eyebrow = 'Meloo access',
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
              Color(0xFFF7F9FA),
              Color(0xFFF1F4F7),
              Color(0xFFEAEFF3),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -110,
                left: -60,
                child: _SoftOrb(size: 220, color: Color(0x14355C7D)),
              ),
              const Positioned(
                right: -80,
                bottom: -60,
                child: _SoftOrb(size: 260, color: Color(0x102E4A62)),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 860;
                        final brandPanel = _AuthBrandPanel(
                          eyebrow: eyebrow,
                          highlights: highlights,
                          compact: compact,
                        );
                        final contentPanel = Container(
                          padding: EdgeInsets.all(compact ? 4 : 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (subtitle.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF66717D),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              child,
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(top: 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Color(0xFFDCE3E8)),
                                  ),
                                ),
                                child: footer,
                              ),
                            ],
                          ),
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFDCE3E8)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14101828),
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 18 : 22),
                            child: compact
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      brandPanel,
                                      const SizedBox(height: 18),
                                      contentPanel,
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: brandPanel),
                                      const SizedBox(width: 20),
                                      Expanded(child: contentPanel),
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

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel({
    required this.eyebrow,
    required this.highlights,
    required this.compact,
  });

  final String eyebrow;
  final List<String> highlights;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E4A62),
            Color(0xFF496479),
          ],
        ),
      ),
      padding: EdgeInsets.all(compact ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MelooBrandMark(
                size: 42,
                padding: 8,
                borderRadius: 14,
                backgroundColor: Color(0x1FFFFFFF),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meloo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: compact ? 28 : 36),
          const Text(
            'Live events,\nclear operations.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'One product for attendees, organizers, vendors, and sponsors.',
            style: TextStyle(
              color: Color(0xFFDCE5EC),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (eyebrow.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                eyebrow,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: highlights
                  .map((item) => _BrandChip(label: item))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
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
