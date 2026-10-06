import 'dart:async';

import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:birthday_reminder/layouts/notifications_settings.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? notificationsEnabled;
  bool? canSendNotifications;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
    NotificationsRegistration.instance.canSendNotifications().then((value) {
      if (!mounted) return;
      setState(() => canSendNotifications = value);
    });
  }

  Future<void> _loadNotificationStatus() async {
    final value =
        await NotificationsRegistration.instance.notificationsEnabled();
    if (!mounted) return;
    setState(() => notificationsEnabled = value);
  }

  Future<bool> toggle(bool value) async {
    bool result = false;
    if (value) {
      result = await NotificationsRegistration.instance.enableNotifications();
    } else {
      result = await NotificationsRegistration.instance.disableNotifications();
    }
    if (!mounted) return result;
    if (result) setState(() => notificationsEnabled = value);
    return result;
  }

  /// Shows a bottom sheet with the signed-in account details.
  void _showAccountDetails(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: RemindraTheme.primaryDeep,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(
                        (user.displayName?.isNotEmpty == true
                                ? user.displayName![0]
                                : user.email?[0] ?? 'R')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 12),

              // Display name
              if (user.displayName?.isNotEmpty == true)
                Text(
                  user.displayName!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

              const SizedBox(height: 4),

              // Email with copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: user.email ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.email ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy, size: 14, color: Colors.grey[500]),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),

              // Sign out button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Confirm then sign out.
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will need to sign in again to access your birthdays.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseAuth.instance.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  /// Confirm then delete data.
  void _confirmDeleteData(BuildContext context, User? user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will send a request to our support team to delete your '
          'account and all your birthday data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(
                'mailto:support.remindra@gmail.com'
                '?subject=Delete%20My%20Account%20%26%20Data'
                '&body=Hi%2C%20I%20want%20to%20delete%20my%20Remindra%20account%20'
                'and%20all%20my%20data.%20My%20registered%20email%20is%3A%20'
                '${Uri.encodeComponent(user?.email ?? '<your email here>')}.'
                '%0A%0AUser%20ID%3A%20${user?.uid ?? ''}',
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final strings = appStrings(context);

    return SettingsList(
      applicationType: ApplicationType.material,
      platform: DevicePlatform.android,
      lightTheme: const SettingsThemeData(
          settingsListBackground: Colors.transparent),
      darkTheme: const SettingsThemeData(
          settingsListBackground: Colors.transparent),
      sections: [
        // ── Account ─────────────────────────────────────────────
        SettingsSection(
          title: Text(strings.account),
          tiles: [
            // Tapping opens the account details bottom sheet
            SettingsTile.navigation(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: RemindraTheme.primaryDeep,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        (user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0]
                                : user?.email?[0] ?? 'R')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(user?.displayName ?? user?.email ?? 'My Account'),
              value: Text(
                user?.email ?? 'Tap to view account details',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: (context) {
                if (user != null) _showAccountDetails(context, user);
              },
            ),

            SettingsTile.navigation(
              leading: const Icon(Icons.exit_to_app_rounded),
              title: Text(strings.sign_out),
              onPressed: (context) => _confirmSignOut(context),
            ),

            SettingsTile(
              leading: const Icon(
                  Icons.delete_forever_rounded, color: Colors.red),
              title: Text(
                strings.delete_all_my_data,
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: (context) => _confirmDeleteData(context, user),
            ),
          ],
        ),

        // ── Notifications ────────────────────────────────────────
        SettingsSection(
          title: Text(strings.notifications),
          tiles: [
            SettingsTile.switchTile(
              leading: Icon(
                notificationsEnabled == true
                    ? Icons.notifications_active_rounded
                    : (notificationsEnabled == null
                        ? Icons.notifications_rounded
                        : Icons.notifications_off_rounded),
              ),
              initialValue: canSendNotifications == true &&
                      notificationsEnabled == null ||
                  notificationsEnabled == true,
              onToggle:
                  (canSendNotifications != null &&
                          notificationsEnabled != null)
                      ? toggle
                      : null,
              title: Text(strings.notifications),
              description: Text(
                notificationsEnabled == true
                    ? 'Birthday reminders are active'
                    : 'Enable to receive birthday reminders',
              ),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.access_time_rounded),
              enabled: notificationsEnabled == true,
              title: Text(strings.configure_notifications),
              description:
                  Text(strings.configure_notifications_description),
              onPressed: notificationsEnabled == true
                  ? (context) {
                      Navigator.of(context).push(
                        CupertinoDialogRoute(
                          builder: (context) =>
                              const NotificationsSettingsPage(),
                          context: context,
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),

        // ── App ──────────────────────────────────────────────────
        SettingsSection(
          title: const Text('App'),
          tiles: [
            SettingsTile.navigation(
              leading: const Icon(Icons.share_rounded),
              title: Text(strings.share),
              onPressed: (context) => Share.share(
                'I use Remindra to never forget a birthday! 🎂\n'
                'Check it out: https://remindra-bc8e5.web.app/',
              ),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: Text(strings.privacy_policy),
              onPressed: (context) => launchUrl(
                Uri.parse('https://remindra-bc8e5.web.app/privacy-policy'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.policy_rounded),
              title: Text(strings.terms_of_use),
              onPressed: (context) => launchUrl(
                Uri.parse('https://remindra-bc8e5.web.app/terms-of-use'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.help_outline_rounded),
              title: Text(strings.help_and_contact),
              description: const Text('support.remindra@gmail.com'),
              onPressed: (context) => launchUrl(
                Uri.parse(
                  'mailto:support.remindra@gmail.com'
                  '?subject=Remindra%20Support'
                  '&body=Hi%2C%20I%20need%20help%20with%20Remindra.%0A%0A'
                  'App%20version%3A%202.0.1%0A'
                  'Device%3A%20Android%0A%0A'
                  'Issue%3A%0A',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),

        // ── About ────────────────────────────────────────────────
        SettingsSection(
          title: const Text('About'),
          tiles: [
            SettingsTile(
              leading: const Icon(Icons.cake_rounded,
                  color: Color(0xFF6A1B9A)),
              title: const Text('Remindra'),
              description: const Text('Moments made timeless.'),
              value: const Text('Version 2.0.1'),
              onPressed: (context) {
                showAboutDialog(
                  context: context,
                  applicationName: 'Remindra',
                  applicationVersion: '2.0.1',
                  applicationIcon: Image.asset(
                    'assets/icon.png',
                    width: 48,
                    height: 48,
                  ),
                  children: [
                    const Text(
                      'Remindra helps you never miss a birthday again. '
                      'Because every year counts.',
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('mailto:support.remindra@gmail.com'),
                      ),
                      child: const Text(
                        'support.remindra@gmail.com',
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
