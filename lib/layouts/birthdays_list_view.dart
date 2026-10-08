import 'package:birthday_reminder/data.dart';
import 'package:birthday_reminder/models/birthday.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:birthday_reminder/widgets/birthday_card_enhanced.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class BirthdaysListView extends StatelessWidget {
  const BirthdaysListView({
    super.key,
    required this.stream,
    required this.insertChildren,
    this.filter,
  });

  final Stream<List<Birthday>> stream;
  final String? filter;
  final List<Widget> insertChildren;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Birthday>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          final errorCode =
              error is FirebaseException ? error.code : 'data-error';
          final message = switch (errorCode) {
            'permission-denied' =>
              'Firestore denied access to these birthdays. Sign out and back in, then try again.',
            'unavailable' =>
              'Firestore is temporarily unavailable. Check your connection and try again.',
            'failed-precondition' =>
              'Firestore needs an index for this query. Contact support.',
            _ => 'Could not read birthday data ($errorCode).',
          };
          return _MessageState(
            icon: Icons.cloud_off_rounded,
            title: 'Your birthdays could not load',
            message: kDebugMode ? '$message\n$error' : message,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final birthdays = snapshot.data ?? const <Birthday>[];
        final filtered = filter == null || filter!.trim().isEmpty
            ? birthdays
            : filterBirthdays(birthdays, filter!).toList();

        if (birthdays.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: [
              const _WelcomePanel(),
              ...insertChildren,
              const SizedBox(height: 42),
              const _MessageStateContent(
                icon: Icons.cake_outlined,
                title: 'Start your people list',
                message:
                    'Add a birthday and Remindra will help you remember the day.',
              ),
            ],
          );
        }

        if (filtered.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: const [
              _WelcomePanel(),
              SizedBox(height: 56),
              _MessageStateContent(
                icon: Icons.search_off_rounded,
                title: 'No birthdays found',
                message: 'Try another name or clear your search.',
              ),
            ],
          );
        }

        final nextBirthday = filtered.first;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            _WelcomePanel(birthdayCount: birthdays.length),
            if (filter == null || filter!.trim().isEmpty) ...[
              ...insertChildren,
              const SizedBox(height: 24),
              _NextUpPanel(birthday: nextBirthday),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    filter == null || filter!.trim().isEmpty
                        ? 'Your people'
                        : 'Search results',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${filtered.length} ${filtered.length == 1 ? 'birthday' : 'birthdays'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final birthday in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EnhancedBirthdayCard(birthday: birthday),
              ),
          ],
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({this.birthdayCount = 0});

  final int birthdayCount;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E5D8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: RemindraTheme.plum,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  birthdayCount == 0
                      ? 'Make room for more moments.'
                      : 'Remember the moments that matter.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 23,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  birthdayCount == 0
                      ? 'Keep your favourite people close.'
                      : '$birthdayCount ${birthdayCount == 1 ? 'person' : 'people'} in your Remindra circle',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: RemindraTheme.paper.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(3),
            child: Image.asset('assets/icon.png'),
          ),
        ],
      ),
    );
  }
}

class _NextUpPanel extends StatelessWidget {
  const _NextUpPanel({required this.birthday});

  final Birthday birthday;

  @override
  Widget build(BuildContext context) {
    final nextDay = birthday.nextBirthday();
    final today = DateTime.now();
    final days = DateTime(nextDay.year, nextDay.month, nextDay.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final label = days == 0
        ? 'Today is their day'
        : days == 1
            ? 'Tomorrow'
            : 'In $days days';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RemindraTheme.plum,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.cake_rounded,
                color: Color(0xFFF4D49A), size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT CELEBRATION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 5),
                Text(
                  birthday.personName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('MMMM d').format(nextDay),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState(
      {required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child:
              _MessageStateContent(icon: icon, title: title, message: message),
        ),
      );
}

class _MessageStateContent extends StatelessWidget {
  const _MessageStateContent(
      {required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: RemindraTheme.rose),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 7),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}
