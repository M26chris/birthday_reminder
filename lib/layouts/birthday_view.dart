import 'package:birthday_reminder/helpers/birthday_notification.dart';
import 'package:birthday_reminder/helpers/birthday_sound.dart';
import 'package:birthday_reminder/layouts/birthday_form_view.dart';
import 'package:birthday_reminder/layouts/bottom_popup.dart';
import 'package:birthday_reminder/models/birthday.dart';
import 'package:birthday_reminder/repositories/birthday_repository.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/widgets/confirm_dialog.dart';
import 'package:birthday_reminder/widgets/share_modal.dart';
import 'package:flutter/material.dart';

class BirthdayView extends StatefulWidget {
  const BirthdayView({super.key, required this.birthday});

  final Birthday birthday;

  @override
  State<BirthdayView> createState() => _BirthdayViewState();
}

class _BirthdayViewState extends State<BirthdayView> {
  late BirthdayFormData _data;
  int _resetId = 0;
  bool _saving = false;
  bool _permitClose = false;
  bool _soundLoaded = false;
  BirthdaySoundSelection? _originalSound;

  @override
  void initState() {
    super.initState();
    _resetForm();
    _loadSound();
  }

  Future<void> _loadSound() async {
    final sound = await BirthdaySound.load(widget.birthday.id);
    if (!mounted) return;
    setState(() {
      _originalSound = sound;
      _soundLoaded = true;
      _data = _data.copyWith(
        soundUri: sound?.uri,
        soundName: sound?.name,
        clearSound: sound == null,
      );
    });
  }

  void _resetForm() {
    _data = BirthdayFormData(
      name: widget.birthday.personName,
      day: widget.birthday.birth.day,
      month: widget.birthday.birth.month,
      year: widget.birthday.noYear ? 0 : widget.birthday.birth.year,
      notes: widget.birthday.notes,
      notificationHour: widget.birthday.notificationHour,
      notificationMinute: widget.birthday.notificationMinute,
      soundUri: _originalSound?.uri,
      soundName: _originalSound?.name,
    );
  }

  bool get _hasChanges =>
      widget.birthday.personName != _data.name ||
      widget.birthday.birth.day != _data.day ||
      widget.birthday.birth.month != _data.month ||
      (widget.birthday.noYear ? 0 : widget.birthday.birth.year) != _data.year ||
      widget.birthday.notes != _data.notes ||
      widget.birthday.notificationHour != _data.notificationHour ||
      widget.birthday.notificationMinute != _data.notificationMinute ||
      _originalSound?.uri != _data.soundUri;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final noYear = _data.year == 0;
      final birthDate =
          DateTime(noYear ? 2000 : _data.year, _data.month, _data.day);
      if (birthDate.month != _data.month || birthDate.day != _data.day) {
        throw ArgumentError('That date is not valid.');
      }
      if (_data.name.trim().isEmpty) {
        throw ArgumentError('Enter a name to continue.');
      }

      final updated = widget.birthday.copyWith(
        personName: _data.name.trim(),
        birth: birthDate,
        noYear: noYear,
        notes: _data.notes.trim(),
        notificationHour: _data.notificationHour,
        notificationMinute: _data.notificationMinute,
      );
      await BirthdayRepository().update(updated);
      await BirthdaySound.save(
        widget.birthday.id,
        _data.soundUri,
        _data.soundName,
      );
      await BirthdayNotificationManager()
          .cancelBirthdayNotification(widget.birthday.id);
      await BirthdayNotificationManager().scheduleBirthdayNotification(updated);
      await _closeAfterAllowingPop();
    } catch (error) {
      if (!mounted) return;
      final message = error is ArgumentError
          ? error.message.toString()
          : error is BirthdayWriteTimeoutException
              ? 'The save is still syncing. Check your connection and retry.'
              : 'Could not save changes. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() => _saving = false);
    }
  }

  Future<void> _requestClose() async {
    if (!await _confirmClose() || !mounted) return;
    await _closeAfterAllowingPop();
  }

  Future<void> _closeAfterAllowingPop() async {
    if (!mounted) return;
    setState(() => _permitClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmClose() async {
    if (!_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard your changes?'),
        content: const Text('Your edits have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _delete() async {
    final strings = appStrings(context);
    final shouldDelete = await confirm(
      context,
      onInput: (_) {},
      title: Text(strings.are_you_sure),
      content: Text(
        'This will permanently delete ${widget.birthday.personName}’s birthday.',
      ),
    );
    if (!shouldDelete) return;

    try {
      await BirthdayRepository().delete(widget.birthday.id);
      await BirthdaySound.clear(widget.birthday.id);
      await BirthdayNotificationManager()
          .cancelBirthdayNotification(widget.birthday.id);
      await _closeAfterAllowingPop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not delete this birthday. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return PopScope<void>(
      canPop: !_hasChanges || _permitClose,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges && !_permitClose) _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(_hasChanges ? 'Edit birthday' : widget.birthday.personName),
          actions: [
            IconButton(
              tooltip: 'Delete birthday',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: BirthdayFormView(
          key: ValueKey('birthday-form-$_resetId'),
          data: _data,
          onDataChange: (value) => setState(() => _data = value),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            children: [
              if (_hasChanges) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _resetId++;
                              _resetForm();
                            }),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving || !_soundLoaded ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving' : strings.save),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showShareModal(context, widget.birthday),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(strings.share),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void showBirthdayView(BuildContext context, {required Birthday birthday}) {
  Navigator.of(context).push(
    BottomPopupRoute(
      height: 660,
      builder: (context) => BirthdayView(birthday: birthday),
    ),
  );
}
