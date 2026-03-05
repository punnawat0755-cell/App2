import 'package:flutter/material.dart';

class SplashScreenpage extends StatelessWidget {
  const SplashScreenpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 40,
            child: const Text(
              'HOW ARE YOU',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4489D7),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
