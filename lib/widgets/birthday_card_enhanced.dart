import 'package:birthday_reminder/models/birthday.dart';
import 'package:birthday_reminder/layouts/birthday_view.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:birthday_reminder/util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnhancedBirthdayCard extends StatelessWidget {
  const EnhancedBirthdayCard({super.key, required this.birthday});

  final Birthday birthday;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextBirthday = birthday.nextBirthday();
    final nextDay =
        DateTime(nextBirthday.year, nextBirthday.month, nextBirthday.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = nextDay.difference(today).inDays;
    final isToday = days == 0;
    final isTomorrow = days == 1;
    final nextAge = birthday.nextAge();
    const avatarColors = [
      Color(0xFFEAD5C3),
      Color(0xFFD9E3D3),
      Color(0xFFE8D7DF),
      Color(0xFFD8E1E8),
    ];
    final colorSeed =
        birthday.personName.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final avatarColor = avatarColors[colorSeed % avatarColors.length];
    final dateLabel = DateFormat('EEE, MMM d').format(nextBirthday);
    final countdown = isToday
        ? 'Today'
        : isTomorrow
            ? 'Tomorrow'
            : 'In $days days';
    final surface = isToday
        ? const Color(0xFFF6E8E8)
        : Theme.of(context).colorScheme.surface;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showBirthdayView(context, birthday: birthday),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isToday
                  ? RemindraTheme.rose.withValues(alpha: 0.45)
                  : RemindraTheme.line,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isToday ? RemindraTheme.plum : avatarColor,
                foregroundColor: RemindraTheme.plum,
                child: Text(
                  extractInitials(birthday.personName),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      birthday.personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateLabel${nextAge == null ? '' : '  ·  Turns $nextAge'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (birthday.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        birthday.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isToday ? RemindraTheme.plum : const Color(0xFFF0E9E3),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  countdown,
                  style: TextStyle(
                    color: isToday ? Colors.white : RemindraTheme.plum,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
