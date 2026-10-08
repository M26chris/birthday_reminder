import 'package:birthday_reminder/models/birthday.dart';
import 'package:birthday_reminder/util.dart';

Iterable<Birthday> filterBirthdays(
    Iterable<Birthday> birthdays, String filter) {
  final filterLower = removeDiacritics(filter.toLowerCase()).trim();
  if (filterLower.isEmpty) return birthdays;
  return birthdays.where((birthday) => removeDiacritics(birthday.personName)
      .toLowerCase()
      .contains(filterLower));
}
