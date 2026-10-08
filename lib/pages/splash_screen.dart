import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF201B22) : const Color(0xFFFAF6EF);
    final plum = dark ? const Color(0xFFE0B4CF) : const Color(0xFF542B50);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color:
                      dark ? const Color(0xFF332935) : const Color(0xFFF0E5D8),
                  borderRadius: BorderRadius.circular(38),
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset('assets/icon.png'),
              ),
              const SizedBox(height: 25),
              Text(
                'Remindra',
                style: TextStyle(
                  color: plum,
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Remember the moments that matter.',
                style: TextStyle(
                  color: dark ? Colors.white70 : const Color(0xFF766D74),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 38),
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: plum,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
