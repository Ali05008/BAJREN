import 'package:flutter/material.dart';

/// Small blue checkmark shown next to a display name when the user's
/// public profile has isVerified == true (mirrored there by the
/// adminSetVerified Cloud Function — clients can never set this
/// themselves, RTDB rules block it).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: Colors.blue,
    );
  }
}
