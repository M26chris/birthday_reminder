import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/theme.dart';
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
  bool _show = false;
  bool _enabling = false;

  @override
  void initState() {
    super.initState();
    _loadPromptState();
  }

  Future<void> _loadPromptState() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    if (authorized) {
      if (mounted) {
        setState(() => _show = false);
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
          () => _show = !(prefs.getBool('prefer_no_notifications') ?? false));
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefer_no_notifications', true);
    if (mounted) setState(() => _show = false);
  }

  Future<void> _enable() async {
    if (_enabling) return;
    setState(() => _enabling = true);
    try {
      final enabled =
          await NotificationsRegistration.instance.enableNotifications();
      if (!mounted) return;
      setState(() {
        _show = !enabled;
        _enabling = false;
      });
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Notifications could not be enabled. Check device permissions and try again.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _enabling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not enable notifications. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final strings = appStrings(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E5D8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.notifications_active_outlined,
                        color: RemindraTheme.plum),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(strings.enbale_notifications,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(strings.enable_notifications_description,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _dismiss, child: const Text('Not now')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _enabling ? null : _enable,
                    icon: _enabling
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(_enabling ? 'Enabling' : 'Enable reminders'),
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
