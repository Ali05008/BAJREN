import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Branded loading screen shown while [bootstrapFirebase] and the initial
/// auth-state check are in flight. Visually matches the native Android
/// launch_background (same near-black brand color + centered logo mark)
/// so there's no color flash when the Flutter engine takes over from the
/// native launch screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/bajren_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
