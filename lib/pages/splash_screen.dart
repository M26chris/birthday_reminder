import 'package:flutter/material.dart';

/// Remindra Splash Screen
///
/// Kept deliberately simple — no AnimationController, no Hero tags.
/// R8 can strip animation internals in release builds causing blank screens.
/// A simple static layout with a built-in AnimatedOpacity (framework-level,
/// always preserved by R8) gives us the fade without risk.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A0533), const Color(0xFF121212)]
                : [const Color(0xFFFFC107), const Color(0xFFFFF8E1)],
          ),
        ),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/icon.png',
                width: 150,
                height: 150,
              ),

              const SizedBox(height: 24),

              // App name
              Text(
                'Remindra',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF4A148C),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              // Slogan
              Text(
                'Because every year counts.',
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF6A1B9A),
                ),
              ),

              const SizedBox(height: 52),

              // Loading indicator
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark
                        ? const Color(0xFFFFC107)
                        : const Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
