class AgeCalculator {
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  static bool isBirthdayToday(DateTime birthDate) {
    final now = DateTime.now();
    return now.day == birthDate.day && now.month == birthDate.month;
  }

  static bool isBirthdayTomorrow(DateTime birthDate) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return tomorrow.day == birthDate.day &&
        tomorrow.month == birthDate.month;
  }

  static int daysUntilBirthday(DateTime birthDate) {
    final now = DateTime.now();
    DateTime upcomingBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    
    if (upcomingBirthday.isBefore(now)) {
      upcomingBirthday = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }
    
    return upcomingBirthday.difference(now).inDays;
  }
}