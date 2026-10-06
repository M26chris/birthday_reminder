import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/widgets/hyperlink.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // User cancelled the sign-in dialog
      if (googleUser == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // On success, auth_wrapper navigates away automatically.
      // Do NOT call setState here — the widget may already be disposed.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: $e'),
          backgroundColor: const Color(0xFF6A1B9A),
        ),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A0533), const Color(0xFF121212)]
                : [const Color(0xFFFFC107), const Color(0xFFFFF8E1)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const Spacer(),

                // ── Logo + Title ─────────────────────────────────
                Column(
                  children: [
                    Hero(
                      tag: 'remindra_logo',
                      child: Image.asset(
                        'assets/icon.png',
                        width: 130,
                        height: 130,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Remindra',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF4A148C),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Because every year counts.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Sign-in card ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 24,
                          color: Colors.black.withOpacity(0.12),
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Welcome back 👋',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to keep track of every special day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Google sign-in button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => signInWithGoogle(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF6A1B9A).withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'More login options coming soon',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── Footer links ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Hyperlink(
                        url: 'https://remindra-bc8e5.web.app/terms-of-use',
                        child: Text(
                          strings.terms_of_use,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF6A1B9A),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Hyperlink(
                        url: 'https://remindra-bc8e5.web.app/privacy-policy',
                        child: Text(
                          strings.privacy_policy,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF6A1B9A),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
