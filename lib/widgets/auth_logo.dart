import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wicket Wars logo',
      image: true,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GameColors.neon.withValues(alpha: 0.18),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/app_logo.png',
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
