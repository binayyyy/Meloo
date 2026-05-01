import 'package:flutter/material.dart';

class PlatformAccessBlockedScreen extends StatelessWidget {
  const PlatformAccessBlockedScreen({
    this.onSignOut,
    super.key,
  });

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE5D6C2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14101A24),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin access is web only',
                  style: TextStyle(
                    color: Color(0xFF14212B),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Use the web admin console for operational access. This app stays focused on attendee, organizer, vendor, and sponsor workflows.',
                  style: TextStyle(
                    color: Color(0xFF5B6772),
                    height: 1.6,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out and switch account'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
