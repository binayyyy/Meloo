import 'package:flutter/material.dart';

class MelooRemoteImage extends StatelessWidget {
  const MelooRemoteImage({
    required this.imageUrl,
    required this.fallbackLabel,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.fontSize = 24,
    this.fallbackGradient,
    this.fallbackColor,
    this.fallbackIcon,
    super.key,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double fontSize;
  final Gradient? fallbackGradient;
  final Color? fallbackColor;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: hasImage
            ? Image.network(
                url,
                fit: fit,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return _FallbackMedia(
                    label: fallbackLabel,
                    fontSize: fontSize,
                    gradient: fallbackGradient,
                    color: fallbackColor,
                    icon: fallbackIcon,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _FallbackMedia(
                    label: fallbackLabel,
                    fontSize: fontSize,
                    gradient: fallbackGradient,
                    color: fallbackColor,
                    icon: fallbackIcon,
                  );
                },
              )
            : _FallbackMedia(
                label: fallbackLabel,
                fontSize: fontSize,
                gradient: fallbackGradient,
                color: fallbackColor,
                icon: fallbackIcon,
              ),
      ),
    );
  }
}

class _FallbackMedia extends StatelessWidget {
  const _FallbackMedia({
    required this.label,
    required this.fontSize,
    this.gradient,
    this.color,
    this.icon,
    this.child,
  });

  final String label;
  final double fontSize;
  final Gradient? gradient;
  final Color? color;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? 'M' : trimmed.characters.first.toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFEAF0F5),
        gradient: gradient,
      ),
      child: child ??
          Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: fontSize,
                    color: const Color(0xFF44515D),
                  )
                : Text(
                    initial,
                    style: TextStyle(
                      color: gradient == null && color == null
                          ? const Color(0xFF44515D)
                          : Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
    );
  }
}
