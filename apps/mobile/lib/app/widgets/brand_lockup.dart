import 'package:flutter/material.dart';

class MelooBrandMark extends StatelessWidget {
  const MelooBrandMark({
    this.size = 36,
    this.padding = 8,
    this.backgroundColor = const Color(0xFFEAF0F5),
    this.borderRadius = 12,
    this.showBorder = false,
    super.key,
  });

  final double size;
  final double padding;
  final Color backgroundColor;
  final double borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: const Color(0xFFDCE3E8))
            : null,
      ),
      child: Image.asset(
        'assets/branding/meloo-mark-v1.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class MelooBrandLockup extends StatelessWidget {
  const MelooBrandLockup({
    this.compact = false,
    this.showCaption = true,
    this.caption = 'Live event operations',
    super.key,
  });

  final bool compact;
  final bool showCaption;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MelooBrandMark(
          size: compact ? 34 : 42,
          padding: compact ? 7 : 8,
          borderRadius: compact ? 11 : 14,
          backgroundColor: compact
              ? const Color(0xFFF4F7F9)
              : const Color(0xFFEAF0F5),
          showBorder: compact,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Meloo',
              style: TextStyle(
                color: const Color(0xFF17212B),
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
            ),
            if (showCaption) ...[
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  color: const Color(0xFF68737D),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
