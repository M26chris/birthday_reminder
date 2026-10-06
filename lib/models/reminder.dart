class Reminder {
  final int id;
  final Duration offset; // e.g. 1 day before = Duration(days: 1)
  final int hour;
  final int minute;
  final int second;

  Reminder({
    required this.id,
    required this.offset,
    required this.hour,
    required this.minute,
    required this.second,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'offset': offset.inSeconds,
        'hour': hour,
        'minute': minute,
        'second': second,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      offset: Duration(seconds: json['offset']),
      hour: json['hour'],
      minute: json['minute'],
      second: json['second'],
    );
  }
}