import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestNotificationCard extends StatefulWidget {
  const RequestNotificationCard({super.key});

  @override
  State<RequestNotificationCard> createState() =>
      _RequestNotificationCardState();
}

class _RequestNotificationCardState extends State<RequestNotificationCard> {
  bool show = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getNotificationSettings().then((value) {
      if (value.authorizationStatus == AuthorizationStatus.authorized) {
        // Already enabled — don't prompt
        if (mounted) setState(() => show = false);
      } else {
        SharedPreferences.getInstance().then((prefs) {
          if (prefs.getBool('prefer_no_notifications') ?? false) return;
          if (mounted) setState(() => show = true);
        });
      }
    });
  }

  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefer_no_notifications', true);
    if (mounted) setState(() => show = false);
  }

  void enable() {
    NotificationsRegistration.instance.enableNotifications().then((success) {
      if (mounted) setState(() => show = !success);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final strings = appStrings(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFFFC107),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.enbale_notifications,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                strings.enable_notifications_description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: dismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                    child: const Text('Not now'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: enable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'Enable',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
