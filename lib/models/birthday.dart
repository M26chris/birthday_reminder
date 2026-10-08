class Birthday {
  const Birthday({
    required this.id,
    required this.personName,
    required this.birth,
    required this.notes,
    required this.noYear,
    this.notificationHour = 9,
    this.notificationMinute = 0,
  });

  final String id;
  final String personName;
  final DateTime birth;
  final String notes;
  final bool noYear;
  final int notificationHour;
  final int notificationMinute;

  Birthday copyWith({
    String? id,
    String? personName,
    DateTime? birth,
    String? notes,
    bool? noYear,
    int? notificationHour,
    int? notificationMinute,
  }) =>
      Birthday(
        id: id ?? this.id,
        personName: personName ?? this.personName,
        birth: birth ?? this.birth,
        notes: notes ?? this.notes,
        noYear: noYear ?? this.noYear,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
      );

  factory Birthday.fromMap(Map<String, dynamic> map, {required String id}) {
    final rawBirth = map['birth'];
    final DateTime birth;
    if (rawBirth is DateTime) {
      birth = rawBirth;
    } else if (rawBirth is num) {
      birth = DateTime.fromMillisecondsSinceEpoch(rawBirth.toInt());
    } else if (rawBirth is String) {
      birth = DateTime.parse(rawBirth);
    } else {
      throw FormatException(
          'Birthday record has no valid birth date.', rawBirth);
    }

    final rawName = map['personName'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw FormatException(
          'Birthday record has no valid person name.', rawName);
    }

    return Birthday(
      id: id,
      personName: rawName,
      birth: birth,
      notes: map['notes'] as String? ?? '',
      noYear: map['noYear'] as bool? ?? false,
      notificationHour: map['notif_hour'] as int? ?? 9,
      notificationMinute: map['notif_minute'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap({required String owner, required DateTime now}) =>
      {
        'personName': personName.trim(),
        'birth': birth,
        'notes': notes.trim(),
        'noYear': noYear,
        'notif_hour': notificationHour,
        'notif_minute': notificationMinute,
        'owner': owner,
        'app_version': '2.0.1',
        'updated_at': now,
      };

  DateTime nextBirthday({DateTime? from}) {
    final reference = from ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final candidate = DateTime(today.year, birth.month, birth.day);
    if (!candidate.isBefore(today)) return candidate;
    return DateTime(today.year + 1, birth.month, birth.day);
  }

  Duration durationToNextBirthday({DateTime? from}) {
    final reference = from ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    return nextBirthday(from: today).difference(today);
  }

  int? nextAge({DateTime? from}) {
    if (noYear) return null;
    return nextBirthday(from: from).year - birth.year;
  }
}
