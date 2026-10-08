import 'package:birthday_reminder/models/birthday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Birthday', () {
    test('uses today when the birthday falls today', () {
      final birthday = Birthday(
        id: '1',
        personName: 'Riley',
        birth: DateTime(1995, 10, 8),
        notes: '',
        noYear: false,
      );

      expect(
        birthday.nextBirthday(from: DateTime(2026, 10, 8, 18)),
        DateTime(2026, 10, 8),
      );
    });

    test('moves a passed birthday to the following year', () {
      final birthday = Birthday(
        id: '2',
        personName: 'Morgan',
        birth: DateTime(2000, 2, 14),
        notes: '',
        noYear: false,
      );

      expect(
        birthday.nextBirthday(from: DateTime(2026, 2, 15)),
        DateTime(2027, 2, 14),
      );
      expect(birthday.nextAge(from: DateTime(2026, 2, 15)), 27);
    });

    test('observes February 29 birthdays on March 1 in non-leap years', () {
      final birthday = Birthday(
        id: 'leap-day',
        personName: 'Jordan',
        birth: DateTime(2000, 2, 29),
        notes: '',
        noYear: false,
      );

      expect(
        birthday.nextBirthday(from: DateTime(2025, 1, 1)),
        DateTime(2025, 3, 1),
      );
      expect(
        birthday.nextBirthday(from: DateTime(2025, 3, 2)),
        DateTime(2026, 3, 1),
      );
    });

    test('writes the current app version to birthday records', () {
      final birthday = Birthday(
        id: 'version',
        personName: 'Riley',
        birth: DateTime(1995, 10, 8),
        notes: '',
        noYear: false,
      );

      expect(
        birthday.toMap(owner: 'user', now: DateTime(2026)),
        containsPair('app_version', '2.0.1'),
      );
    });

    test('does not guess an age when birth year is unknown', () {
      final birthday = Birthday(
        id: '3',
        personName: 'Taylor',
        birth: DateTime(2000, 7, 9),
        notes: '',
        noYear: true,
      );

      expect(birthday.nextAge(from: DateTime(2026, 1, 1)), isNull);
    });

    test('rejects malformed persisted records', () {
      expect(
        () => Birthday.fromMap({'personName': 'Riley'}, id: '4'),
        throwsFormatException,
      );
    });
  });
}
