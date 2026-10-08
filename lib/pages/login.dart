import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:birthday_reminder/widgets/hyperlink.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed. Please try again.\n$error')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: RemindraTheme.paper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/icon.png'),
                  ),
                ),
                const SizedBox(height: 54),
                Text(
                  'A little more\nthoughtful, every year.',
                  style: theme.textTheme.headlineLarge?.copyWith(fontSize: 38),
                ),
                const SizedBox(height: 14),
                Text(
                  'Keep birthdays close, add the details you want to remember, '
                  'and let Remindra give you a gentle nudge when the day arrives.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E5D8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      _MomentIcon(icon: Icons.cake_outlined),
                      SizedBox(width: 10),
                      _MomentIcon(icon: Icons.favorite_border_rounded),
                      SizedBox(width: 10),
                      _MomentIcon(icon: Icons.notifications_none_rounded),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Remember the day.\nMake someone feel seen.',
                          style: TextStyle(
                            color: RemindraTheme.plum,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      _isLoading ? 'Connecting…' : 'Continue with Google',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: RemindraTheme.plum,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your birthdays are private to your account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  children: [
                    Hyperlink(
                      url: 'https://remindra-bc8e5.web.app/terms-of-use',
                      child: Text(strings.terms_of_use,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: RemindraTheme.plum)),
                    ),
                    Hyperlink(
                      url: 'https://remindra-bc8e5.web.app/privacy-policy',
                      child: Text(strings.privacy_policy,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: RemindraTheme.plum)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MomentIcon extends StatelessWidget {
  const _MomentIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: RemindraTheme.paper,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: RemindraTheme.plum, size: 20),
      );
}
