import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final logoSize = (constraints.maxWidth * 0.64).clamp(160.0, 250.0);
            final bottomSpacing = constraints.maxHeight < 650 ? 18.0 : 40.0;

            return Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: bottomSpacing,
                  child: Text(
                    'HOW ARE YOU',
                    style: GoogleFonts.mitr(
                      fontSize: scale.rf(28, min: 24, max: 28),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4489D7),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
