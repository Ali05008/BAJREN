import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live verification status for [uid], read from the public
/// `public_profiles/{uid}/isVerified` field. This field is admin-only —
/// RTDB rules block clients from ever writing it themselves (see
/// docs/firebase_database.rules.json) — so a `true` here always came
/// from `adminSetVerified`, never from the user.
final isVerifiedProvider =
    StreamProvider.family<bool, String>((ref, uid) {
  return FirebaseDatabase.instance
      .ref('public_profiles/$uid/isVerified')
      .onValue
      .map((event) => event.snapshot.value == true);
});

/// Small blue checkmark shown next to a display name when the user is
/// verified. Renders nothing (zero size) while unverified or loading, so
/// it's safe to drop next to any name without reserving layout space.
class VerifiedBadge extends ConsumerWidget {
  const VerifiedBadge({super.key, required this.uid, this.size = 16});

  final String uid;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = ref.watch(isVerifiedProvider(uid)).valueOrNull ?? false;
    if (!isVerified) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(Icons.verified, size: size, color: Colors.blue.shade600),
    );
  }
}
