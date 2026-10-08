import 'dart:async';

import 'package:birthday_reminder/models/birthday.dart';
import 'package:birthday_reminder/helpers/birthday_notification.dart';
import 'package:birthday_reminder/helpers/birthday_sound.dart';
import 'package:birthday_reminder/repositories/birthday_repository.dart';
import 'package:birthday_reminder/layouts/birthday_form_view.dart';
import 'package:birthday_reminder/layouts/birthdays_list_view.dart';
import 'package:birthday_reminder/layouts/settings_page.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/widgets/request_notification_card.dart';
import 'package:birthday_reminder/widgets/search_appbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final BirthdayRepository _repository = BirthdayRepository();
  late final Stream<List<Birthday>> _birthdays;
  StreamSubscription<List<Birthday>>? _notificationSubscription;
  Future<void> _notificationSync = Future<void>.value();
  int _selectedTab = 0;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _birthdays = _repository.watchBirthdays();
    _notificationSubscription = _birthdays.listen(
      _queueNotificationSync,
      onError: (Object error, StackTrace stack) {
        if (kDebugMode) {
          debugPrint('Could not load birthdays for reminder sync: $error');
          debugPrintStack(stackTrace: stack);
        }
      },
    );
  }

  void _queueNotificationSync(List<Birthday> birthdays) {
    _notificationSync = _notificationSync.then((_) async {
      try {
        await BirthdayNotificationManager().rescheduleAll(birthdays);
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('Could not synchronize birthday reminders: $error');
          debugPrintStack(stackTrace: stack);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Some reminders could not be scheduled. Check notification permissions.',
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }

  Future<void> _openAddBirthday() async {
    final reminderScheduled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddBirthdayPage(onSave: _saveBirthday),
      ),
    );
    if (reminderScheduled == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reminderScheduled
            ? 'Birthday saved and reminder set.'
            : 'Birthday saved, but its reminder could not be scheduled.'),
      ),
    );
  }

  Future<bool> _saveBirthday(
    BirthdayFormData data, {
    String? retryId,
  }) async {
    final name = data.name.trim();
    if (name.isEmpty) throw ArgumentError('Enter a name to continue.');

    final date =
        DateTime(data.year == 0 ? 2000 : data.year, data.month, data.day);
    if (date.month != data.month || date.day != data.day) {
      throw ArgumentError('That date is not valid.');
    }

    final saved = await _repository.create(
      Birthday(
        id: '',
        personName: name,
        birth: date,
        noYear: data.year == 0,
        notes: data.notes.trim(),
        notificationHour: data.notificationHour,
        notificationMinute: data.notificationMinute,
      ),
      id: retryId ?? _repository.newBirthdayId(),
    );
    await BirthdaySound.save(
      saved.id,
      data.soundUri,
      data.soundName,
    );
    try {
      await BirthdayNotificationManager().scheduleBirthdayNotification(saved);
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Birthday saved but reminder scheduling failed: $error');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final isBirthdaysTab = _selectedTab == 0;

    return Scaffold(
      appBar: SearchAppBar(
        title: isBirthdaysTab
            ? Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Image.asset('assets/icon.png'),
                  ),
                  const SizedBox(width: 10),
                  const Text('Remindra'),
                ],
              )
            : Text(strings.settings),
        searchEnabled: isBirthdaysTab,
        onCancel: () => setState(() => _filter = ''),
        onSearch: (query) => setState(() => _filter = query),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          BirthdaysListView(
            stream: _birthdays,
            filter: _filter,
            insertChildren: const [RequestNotificationCard()],
          ),
          const SettingsPage(),
        ],
      ),
      floatingActionButton: isBirthdaysTab
          ? FloatingActionButton.extended(
              onPressed: _openAddBirthday,
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.add_birthday),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.cake_outlined),
            selectedIcon: const Icon(Icons.cake_rounded),
            label: strings.birthdays,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: strings.settings,
          ),
        ],
      ),
    );
  }
}

class AddBirthdayPage extends StatefulWidget {
  const AddBirthdayPage({super.key, required this.onSave});

  final Future<bool> Function(
    BirthdayFormData data, {
    String? retryId,
  }) onSave;

  @override
  State<AddBirthdayPage> createState() => _AddBirthdayPageState();
}

class _AddBirthdayPageState extends State<AddBirthdayPage> {
  late BirthdayFormData _data;
  bool _saving = false;
  String? _pendingBirthdayId;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _data = BirthdayFormData(
      name: '',
      day: today.day,
      month: today.month,
      year: 0,
      notes: '',
      notificationHour: 9,
      notificationMinute: 0,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final reminderScheduled = await widget.onSave(
        _data,
        retryId: _pendingBirthdayId,
      );
      if (mounted) Navigator.of(context).pop(reminderScheduled);
    } catch (error) {
      if (!mounted) return;
      if (error is BirthdayWriteTimeoutException) {
        _pendingBirthdayId = error.birthdayId;
      }
      final message = switch (error) {
        ArgumentError() => error.message.toString(),
        BirthdayWriteTimeoutException() =>
          'The save is still syncing. Check your connection and retry; the same birthday record will be reused.',
        _ => 'Could not save this birthday. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '$message${kDebugMode && error is! ArgumentError ? '\n$error' : ''}')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A new celebration'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BirthdayFormView(
          data: _data,
          onDataChange: (data) => setState(() => _data = data),
        ),
      ),
    );
  }
}
