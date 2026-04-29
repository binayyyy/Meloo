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
      backgroundColor: const Color(0xFFF6F2EC),
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 8,
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F2EC), Color(0xFFEEF2F5)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x144D6278),
                  ),
                ),
              ),
              Positioned(
                left: -70,
                bottom: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x10C89C5D),
                  ),
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
