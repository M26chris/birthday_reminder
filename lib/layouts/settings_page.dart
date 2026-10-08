import 'package:birthday_reminder/helpers/notifications_registration.dart';
import 'package:birthday_reminder/layouts/notifications_settings.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _notificationsEnabled;
  bool? _canSendNotifications;

  @override
  void initState() {
    super.initState();
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    final results = await Future.wait([
      NotificationsRegistration.instance.notificationsEnabled(),
      NotificationsRegistration.instance.canSendNotifications(),
    ]);
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = results[0];
      _canSendNotifications = results[1];
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final success = enabled
        ? await NotificationsRegistration.instance.enableNotifications()
        : await NotificationsRegistration.instance.disableNotifications();
    if (!mounted) return;
    if (success) {
      setState(() => _notificationsEnabled = enabled);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not update notification settings.')),
    );
  }

  Future<void> _openUri(String value) async {
    final uri = Uri.parse(value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  void _showAccountDetails(User user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(user: user, size: 64),
              const SizedBox(height: 14),
              Text(user.displayName ?? 'Your account',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              SelectableText(user.email ?? ''),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: user.email ?? ''));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email copied')),
                    );
                  }
                },
                icon: const Icon(Icons.content_copy_rounded),
                label: const Text('Copy email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content:
            const Text('You can sign back in to see your saved birthdays.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
  }

  Future<void> _confirmDeleteData(User? user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request account deletion?'),
        content: const Text(
          'This opens an email to Remindra support requesting deletion of your '
          'account and birthday data. Your data is not deleted until support '
          'confirms the request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final body = [
      'Hi, I want to delete my Remindra account and all associated data.',
      'Registered email: ${user?.email ?? ''}',
      'User ID: ${user?.uid ?? ''}',
    ].join('\n\n');
    await _openUri(Uri(
      scheme: 'mailto',
      path: 'support.remindra@gmail.com',
      queryParameters: {'subject': 'Delete my Remindra data', 'body': body},
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final strings = appStrings(context);
    final notificationsAvailable = _canSendNotifications == true;
    final notificationsOn = _notificationsEnabled == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Text('Make it yours',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('Your account, reminders and Remindra details.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        _SectionLabel(title: 'YOUR ACCOUNT'),
        const SizedBox(height: 9),
        _SettingsCard(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              leading: _Avatar(user: user, size: 46),
              title: Text(user?.displayName ?? 'Your account'),
              subtitle: Text(user?.email ?? 'Account details'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: user == null ? null : () => _showAccountDetails(user),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ActionTile(
              icon: Icons.logout_rounded,
              title: strings.sign_out,
              onTap: _confirmSignOut,
            ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Request data deletion',
              subtitle: 'Contact Remindra support to remove your account',
              destructive: true,
              onTap: () => _confirmDeleteData(user),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionLabel(title: 'REMINDERS'),
        const SizedBox(height: 9),
        _SettingsCard(
          children: [
            SwitchListTile.adaptive(
              value: notificationsOn,
              onChanged:
                  _canSendNotifications == null ? null : _toggleNotifications,
              secondary: Icon(
                notificationsOn
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
              ),
              title: Text(strings.notifications),
              subtitle: Text(
                _canSendNotifications == null
                    ? 'Checking notification access…'
                    : notificationsAvailable
                        ? notificationsOn
                            ? 'Your birthday reminders are on'
                            : 'Turn on gentle birthday reminders'
                        : 'Notifications are unavailable on this device',
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ActionTile(
              icon: Icons.schedule_rounded,
              title: strings.configure_notifications,
              subtitle: strings.configure_notifications_description,
              enabled: notificationsOn,
              onTap: notificationsOn
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsSettingsPage(),
                        ),
                      )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionLabel(title: 'ABOUT REMINDRA'),
        const SizedBox(height: 9),
        _SettingsCard(
          children: [
            _ActionTile(
              icon: Icons.ios_share_rounded,
              title: strings.share,
              subtitle: 'Tell someone about Remindra',
              onTap: () => SharePlus.instance.share(ShareParams(
                text: 'Remember the moments that matter with Remindra.\n'
                    'https://remindra-bc8e5.web.app/',
              )),
            ),
            _ActionTile(
              icon: Icons.shield_outlined,
              title: strings.privacy_policy,
              onTap: () =>
                  _openUri('https://remindra-bc8e5.web.app/privacy-policy'),
            ),
            _ActionTile(
              icon: Icons.description_outlined,
              title: strings.terms_of_use,
              onTap: () =>
                  _openUri('https://remindra-bc8e5.web.app/terms-of-use'),
            ),
            _ActionTile(
              icon: Icons.mail_outline_rounded,
              title: strings.help_and_contact,
              subtitle: 'support.remindra@gmail.com',
              onTap: () => _openUri(Uri(
                scheme: 'mailto',
                path: 'support.remindra@gmail.com',
                queryParameters: {
                  'subject': 'Remindra support',
                  'body': 'Hi Remindra,\n\nI need help with…',
                },
              ).toString()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/icon.png',
                width: 28,
                height: 28,
              ),
              const SizedBox(height: 6),
              Text('Remindra', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text('Moments made timeless.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('Version 2.0.1',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: RemindraTheme.mutedInk,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.25,
            ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: enabled ? color : null),
      title: Text(title, style: destructive ? TextStyle(color: color) : null),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: enabled ? onTap : null,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dimension = size;
    final name = user?.displayName?.trim();
    final initial = name?.isNotEmpty == true
        ? name![0]
        : user?.email?.isNotEmpty == true
            ? user!.email![0]
            : 'R';
    return CircleAvatar(
      radius: dimension / 2,
      backgroundColor: const Color(0xFFF0E5D8),
      backgroundImage:
          user?.photoURL == null ? null : NetworkImage(user!.photoURL!),
      child: user?.photoURL != null
          ? null
          : Text(initial.toUpperCase(),
              style: TextStyle(
                color: RemindraTheme.plum,
                fontSize: dimension * 0.38,
                fontWeight: FontWeight.w700,
              )),
    );
  }
}
