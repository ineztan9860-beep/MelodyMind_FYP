import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isPostAuth = args?['isPostAuth'] ?? false;

      if (isPostAuth) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/'); // Transitions to Auth
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Image.asset('assets/images/logo.png', width: 160, height: 160, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeInText(
              text: 'MelodyMind',
              style: theme.textTheme.displayLarge!.copyWith(
                fontSize: 32, // Controlled splash size
              ),
              delay: 400,
            ),
            const SizedBox(height: 12),
            FadeInText(
              text: 'Train Your Ear. Master the Music.',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
              delay: 800,
            ),
          ],
        ),
      ),
    );
  }
}

class FadeInText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int delay;

  const FadeInText({
    super.key,
    required this.text,
    required this.style,
    required this.delay,
  });

  @override
  State<FadeInText> createState() => _FadeInTextState();
}

class _FadeInTextState extends State<FadeInText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(widget.text, style: widget.style),
    );
  }
}
