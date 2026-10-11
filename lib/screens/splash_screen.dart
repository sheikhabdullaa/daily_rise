import 'package:daily_rise/auth/login_screen.dart';
import 'package:daily_rise/screens/Bottom_sheet_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      await user.reload();
      user = auth.currentUser;

      if (user != null && user.emailVerified) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DailyRiseNavigation()),
        );
        return;
      }

      await auth.signOut();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forestBackground,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: forestGreen, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.wb_twilight_rounded,
                      size: 60,
                      color: botanicalGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DailyRise',
                    style: TextStyle(
                      color: warmCream,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Rise a Little Every Day.',
                    style: TextStyle(color: softSage, fontSize: 15),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: botanicalGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
