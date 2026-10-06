import 'package:birthday_reminder/helpers/birthday.dart';
import 'package:birthday_reminder/layouts/birthday_view.dart';
import 'package:birthday_reminder/strings.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:birthday_reminder/util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnhancedBirthdayCard extends StatelessWidget {
  const EnhancedBirthdayCard({
    super.key,
    required this.birthday,
  });

  final Birthday birthday;

  bool get isBirthdayToday {
    final now = DateTime.now();
    return now.day == birthday.birth.day && now.month == birthday.birth.month;
  }

  bool get isBirthdayTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return tomorrow.day == birthday.birth.day &&
        tomorrow.month == birthday.birth.month;
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final nextBirthday = birthday.nextBirthday();
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Date format: "Friday 03, April" or with year if next year
    String formatter = 'EEEE dd, MMMM';
    if (nextBirthday.year != now.year) formatter += ' y';

    final difference = birthday.durationToNextBirthday();
    final inDays = (difference.inMilliseconds / 1000 / 60 / 60 / 24).ceil();

    // ── Countdown badge text ───────────────────────────────────────
    final String countdownText;
    if (isBirthdayToday) {
      countdownText = '🎂 ${strings.today}';
    } else if (inDays == 1) {
      countdownText = '🎉 ${strings.tomorrow}';
    } else {
      countdownText = '${strings.in_word} $inDays ${strings.days}';
    }

    // ── Age label ─────────────────────────────────────────────────
    final nextAge = birthday.nextAge();
    final String? ageText =
        nextAge != null ? 'Turns $nextAge ${strings.years}' : null;

    // ── Date string ───────────────────────────────────────────────
    final dateText = DateFormat(formatter, 'en').format(nextBirthday);

    // ── Colours ───────────────────────────────────────────────────
    final avatarColors = generateRandomColor(birthday.personName);
    final bool isSpecial = isBirthdayToday || isBirthdayTomorrow;

    final Color badgeColor = isBirthdayToday
        ? RemindraTheme.accentGold
        : isBirthdayTomorrow
            ? RemindraTheme.accentAmber
            : (isDark
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFFEDE7F6));

    final Color badgeTextColor = isSpecial ? Colors.black : (isDark ? Colors.white70 : const Color(0xFF6A1B9A));

    return GestureDetector(
      onTap: () => showBirthdayView(context, birthday: birthday),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isBirthdayToday
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    RemindraTheme.primaryDeep.withOpacity(0.85),
                    RemindraTheme.primaryLight.withOpacity(0.7),
                  ],
                )
              : null,
          color: isBirthdayToday ? null : Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: isBirthdayToday
                  ? RemindraTheme.primaryDeep.withOpacity(0.3)
                  : Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar ──────────────────────────────────────────
              CircleAvatar(
                radius: 24,
                backgroundColor: isBirthdayToday
                    ? RemindraTheme.accentGold
                    : avatarColors.background,
                foregroundColor:
                    isBirthdayToday ? Colors.black : avatarColors.foreground,
                child: Text(
                  extractInitials(birthday.personName),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 12),

              // ── Name + date + age (vertical, no overflow) ───────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      birthday.personName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isBirthdayToday ? Colors.white : null,
                          ),
                    ),

                    const SizedBox(height: 3),

                    // Date
                    Text(
                      dateText,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isBirthdayToday
                                ? Colors.white.withOpacity(0.85)
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                          ),
                    ),

                    // Age (only if known)
                    if (ageText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        ageText,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isBirthdayToday
                                      ? Colors.white.withOpacity(0.75)
                                      : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                      ),
                    ],

                    // Notes (if any)
                    if (birthday.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        birthday.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: isBirthdayToday
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey,
                                ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Countdown badge (right side, no overflow risk) ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  countdownText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
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
