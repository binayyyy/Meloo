import 'package:flutter/material.dart';
import 'brand_lockup.dart';

class WorkflowPageScaffold extends StatelessWidget {
  const WorkflowPageScaffold({
    required this.child,
    this.trailing,
    super.key,
  });

  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 8,
        backgroundColor: const Color(0xFFF5F1EA),
        title: const MelooBrandLockup(
          compact: true,
          showCaption: false,
        ),
        actions: [
          if (trailing != null) trailing!,
          const SizedBox(width: 10),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F2EC), Color(0xFFEEF2F5)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -60,
                child: _ScaffoldOrb(
                  size: 240,
                  color: Color(0x184D6278),
                ),
              ),
              Positioned(
                left: -80,
                bottom: -90,
                child: _ScaffoldOrb(
                  size: 260,
                  color: Color(0x14C89C5D),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaffoldOrb extends StatelessWidget {
  const _ScaffoldOrb({
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
