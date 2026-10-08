import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/helpers/birthday_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BirthdayFormData {
  const BirthdayFormData({
    required this.name,
    required this.day,
    required this.month,
    required this.year,
    required this.notes,
    this.notificationHour = 9,
    this.notificationMinute = 0,
    this.soundUri,
    this.soundName,
  });

  final String name;
  final int day;
  final int month;
  final int year;
  final String notes;
  final int notificationHour;
  final int notificationMinute;
  final String? soundUri;
  final String? soundName;

  BirthdayFormData copyWith({
    String? name,
    int? day,
    int? month,
    int? year,
    String? notes,
    int? notificationHour,
    int? notificationMinute,
    String? soundUri,
    String? soundName,
    bool clearSound = false,
  }) =>
      BirthdayFormData(
        name: name ?? this.name,
        day: day ?? this.day,
        month: month ?? this.month,
        year: year ?? this.year,
        notes: notes ?? this.notes,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        soundUri: clearSound ? null : soundUri ?? this.soundUri,
        soundName: clearSound ? null : soundName ?? this.soundName,
      );
}

class BirthdayFormView extends StatelessWidget {
  const BirthdayFormView({
    super.key,
    required this.data,
    required this.onDataChange,
  });

  final BirthdayFormData data;
  final ValueChanged<BirthdayFormData> onDataChange;

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final months = List.generate(
      12,
      (index) => DateFormat('MMMM', 'en').format(DateTime(2000, index + 1, 1)),
    );
    final time = TimeOfDay(
      hour: data.notificationHour,
      minute: data.notificationMinute,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E5D8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cake_outlined,
                  color: Color(0xFF542B50), size: 26),
              const SizedBox(height: 12),
              Text('Make it memorable',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Add the little details now. We’ll help you remember the day.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _FieldLabel(title: 'THE PERSON'),
        const SizedBox(height: 9),
        TextFormField(
          key: const ValueKey('birthday-name-field'),
          initialValue: data.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: strings.name_of_person,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          onChanged: (value) => onDataChange(data.copyWith(name: value)),
        ),
        const SizedBox(height: 22),
        _FieldLabel(title: 'THE DATE'),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _NumberPicker(
                label: strings.month,
                value: data.month,
                items: months,
                onChanged: (value) => onDataChange(data.copyWith(month: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberPicker(
                label: strings.day,
                value: data.day,
                items: List.generate(31, (index) => '${index + 1}'),
                onChanged: (value) => onDataChange(data.copyWith(day: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BirthYearPicker(
          value: data.year,
          onChanged: (value) {
            if (value != null) onDataChange(data.copyWith(year: value));
          },
        ),
        const SizedBox(height: 22),
        _FieldLabel(title: 'A NOTE FOR LATER'),
        const SizedBox(height: 9),
        TextFormField(
          initialValue: data.notes,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.notes,
            hintText: 'A favourite cake, a gift idea, a little reminder…',
            alignLabelWithHint: true,
          ),
          onChanged: (value) => onDataChange(data.copyWith(notes: value)),
        ),
        const SizedBox(height: 22),
        _FieldLabel(title: 'THE REMINDER'),
        const SizedBox(height: 9),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final selected = await showTimePicker(
                context: context,
                initialTime: time,
                helpText: 'Choose when to be reminded',
              );
              if (selected == null) return;
              onDataChange(data.copyWith(
                notificationHour: selected.hour,
                notificationMinute: selected.minute,
              ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.notification_time,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text('A gentle nudge on their birthday',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(time.format(context),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _FieldLabel(title: 'THE SOUND'),
        const SizedBox(height: 9),
        Card(
          child: ListTile(
            leading: const Icon(Icons.music_note_rounded),
            title: Text(data.soundName ?? 'Remindra default sound'),
            subtitle: Text(
              data.soundName == null
                  ? 'Choose an audio file on this device for this birthday.'
                  : 'This audio plays for this birthday’s reminder only.',
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Choose birthday sound',
              onSelected: (choice) async {
                try {
                  if (choice == 'default') {
                    onDataChange(data.copyWith(clearSound: true));
                    return;
                  }
                  final selection = await BirthdaySound.pick();
                  if (!context.mounted) return;
                  if (selection != null) {
                    onDataChange(data.copyWith(
                      soundUri: selection.uri,
                      soundName: selection.name,
                    ));
                  }
                } on UnsupportedError catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message ?? 'Not supported.')),
                  );
                } on PlatformException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.message ?? 'Could not open the audio library.',
                      ),
                    ),
                  );
                } on FormatException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'choose',
                  child: Text('Choose audio file'),
                ),
                if (data.soundUri != null)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Use default sound'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF766D74),
            ),
      );
}

class _NumberPicker extends StatelessWidget {
  const _NumberPicker({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<String> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        initialValue: value - 1,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var index = 0; index < items.length; index++)
            DropdownMenuItem(value: index, child: Text(items[index])),
        ],
        onChanged: (index) {
          if (index != null) onChanged(index + 1);
        },
      );
}

class BirthYearPicker extends StatelessWidget {
  const BirthYearPicker({
    super.key,
    required this.onChanged,
    required this.value,
  });

  final ValueChanged<int?> onChanged;
  final int value;

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: strings.year_of_birth,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      items: [
        DropdownMenuItem(value: 0, child: Text(strings.not_specified)),
        for (var year = currentYear; year >= currentYear - 130; year--)
          DropdownMenuItem(value: year, child: Text('$year')),
      ],
      onChanged: onChanged,
    );
  }
}
