import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:birthday_reminder/helpers/birthday_notification.dart';
import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends State<NotificationsSettingsPage> {
  bool? _notificationsEnabled;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final enabled =
        await NotificationsRegistration.instance.notificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    if (value) {
      await NotificationsRegistration.instance.enableNotifications();
    } else {
      await NotificationsRegistration.instance.disableNotifications();
    }
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Push notifications toggle ────────────────────
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Enable push notifications'),
                  subtitle: const Text(
                    'Receive birthday reminders even when the app is closed.',
                  ),
                  value: _notificationsEnabled ?? false,
                  onChanged: _toggle,
                ),

                const Divider(),

                // ── Per-birthday time info card ──────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Per-birthday notification times',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Each birthday has its own notification time. '
                            'When you add or edit a birthday, tap the '
                            '"Notification time" field to pick exactly when '
                            'you want to be reminded for that person.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Sound info card ──────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.music_note_outlined,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Birthday sound',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'To use a custom birthday sound, place your audio '
                            'file at:\n\n'
                            'android/app/src/main/res/raw/birthday_sound.mp3\n\n'
                            'Then uncomment the sound line in '
                            'birthday_notification.dart and rebuild.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
