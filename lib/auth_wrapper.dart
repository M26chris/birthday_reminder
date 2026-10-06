import 'dart:async';

import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:birthday_reminder/pages/home.dart';
import 'package:birthday_reminder/pages/login.dart';
import 'package:birthday_reminder/pages/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppAuthWrapper extends StatefulWidget {
  const AppAuthWrapper({super.key});

  @override
  State<AppAuthWrapper> createState() => _AppAuthWrapperState();
}

class _AppAuthWrapperState extends State<AppAuthWrapper> {
  late Stream<User?> stream;
  StreamSubscription<User?>? subscription;

  // Show splash for at least this long so the animation completes nicely
  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    stream = FirebaseAuth.instance.authStateChanges();
    subscription = stream.listen(_onAuthChange);

    // Minimum splash duration (matches animation length + small buffer)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _minSplashElapsed = true);
    });
  }

  void _onAuthChange(User? user) async {
    await NotificationsRegistration.instance.updateUserInformation();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: stream,
      builder: (context, snapshot) {
        // Show splash while:
        //  • waiting for the first auth event (ConnectionState.waiting), OR
        //  • minimum splash duration hasn't elapsed yet
        final authReady = snapshot.connectionState != ConnectionState.waiting;

        if (!authReady || !_minSplashElapsed) {
          return const SplashScreen();
        }

        final user = snapshot.data;

        if (user != null) {
          return const Home();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
