import 'package:app_settings/app_settings.dart';
import 'package:birthday_reminder/helpers/birthday_notification.dart';
import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool? _notificationsEnabled;
  bool _loading = true;
  bool _testingSound = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final enabled =
          await NotificationsRegistration.instance.notificationsEnabled();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = false;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check reminder status: $error')),
      );
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      final success = value
          ? await NotificationsRegistration.instance.enableNotifications()
          : await NotificationsRegistration.instance.disableNotifications();
      await _loadStatus();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Remindra could not update alerts. Check notification permission.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update alerts: $error')),
      );
    }
  }

  Future<void> _testDefaultSound() async {
    setState(() => _testingSound = true);
    try {
      await BirthdayNotificationManager().testNotificationSound();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test reminder sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send the test reminder: $error')),
      );
    } finally {
      if (mounted) setState(() => _testingSound = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _notificationsEnabled == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Remindra reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Card(
                  child: SwitchListTile.adaptive(
                    secondary: Icon(
                      enabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_rounded,
                    ),
                    title: const Text('Enable Remindra alerts'),
                    subtitle: Text(
                      enabled
                          ? 'Birthday reminders are enabled.'
                          : 'Turn on alerts to receive reminders.',
                    ),
                    value: enabled,
                    onChanged: _toggle,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Personal reminders',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.schedule_rounded),
                        title: Text('Choose a time for each birthday'),
                        subtitle: Text(
                          'Open a birthday and edit its reminder time. '
                          'The alert is scheduled for that person’s next birthday.',
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      const ListTile(
                        leading: Icon(Icons.music_note_rounded),
                        title: Text('Choose a birthday sound'),
                        subtitle: Text(
                          'When adding or editing a birthday, choose an audio '
                          'file on this device (Android 8.0+). Remindra’s default sound is used '
                          'when no custom sound is selected.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Sound check',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send a test using Remindra’s default notification '
                          'sound. Custom sounds are selected separately for '
                          'each birthday.',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: enabled && !_testingSound
                                ? _testDefaultSound
                                : null,
                            icon: _testingSound
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(_testingSound
                                ? 'Sending test'
                                : 'Test default sound'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Device notification settings'),
                    subtitle: const Text(
                      'Review Remindra’s notification permission on Android.',
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () => AppSettings.openAppSettings(
                      type: AppSettingsType.notification,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
