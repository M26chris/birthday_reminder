import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:birthday_reminder/models/birthday.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:birthday_reminder/helpers/birthday_sound.dart';

class BirthdayNotificationManager {
  static final BirthdayNotificationManager _instance =
      BirthdayNotificationManager._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory BirthdayNotificationManager() => _instance;

  BirthdayNotificationManager._internal();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    await _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final androidImpl =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Schedule a local notification for [birthday] using its per-birthday time.
  ///
  Future<void> scheduleBirthdayNotification(Birthday birthday) async {
    try {
      final now = DateTime.now();
      final birth = birthday.birth;
      final hour = birthday.notificationHour;
      final minute = birthday.notificationMinute;
      final selectedSound = await BirthdaySound.load(birthday.id);
      var customChannelId = selectedSound == null
          ? null
          : _customSoundChannelId(birthday.id, selectedSound.uri);
      if (selectedSound != null &&
          defaultTargetPlatform == TargetPlatform.android) {
        final supported =
            await const MethodChannel('app.remindra/birthday_sound')
                .invokeMethod<bool>('createSoundChannel', {
          'channelId': customChannelId,
          'name': 'Birthday reminder sound',
          'description': 'Custom sound for ${birthday.personName}’s birthday',
          'uri': selectedSound.uri,
        });
        if (supported != true) customChannelId = null;
      }

      // Build the target date for this year at the birthday's chosen time
      var scheduledDate = DateTime(
        now.year,
        birth.month,
        birth.day,
        hour,
        minute,
      );

      // If that moment has already passed, push to next year
      if (scheduledDate.isBefore(now)) {
        scheduledDate = DateTime(
          now.year + 1,
          birth.month,
          birth.day,
          hour,
          minute,
        );
      }

      final tz.TZDateTime tzScheduled =
          tz.TZDateTime.from(scheduledDate, tz.local);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        customChannelId ?? 'birthday_channel_sound_v1',
        'Remindra Birthday Alerts',
        channelDescription: selectedSound == null
            ? 'Remindra birthday notifications with sound'
            : 'Remindra birthday notifications with a chosen sound',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        sound: selectedSound == null
            ? const RawResourceAndroidNotificationSound('birthday_sound')
            : null,
        styleInformation: BigTextStyleInformation(''), // Ensures sound plays
        audioAttributesUsage:
            AudioAttributesUsage.notification, // Proper audio category
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // sound: 'birthday_sound.aiff', // add iOS sound file later
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // FIX: Use exactAllowWhileIdle for on-time delivery on all Android versions.
      // inexactAllowWhileIdle lets Android delay alarms by minutes to save battery.
      // exactAllowWhileIdle fires at the precise time the user chose.
      await _notificationsPlugin.zonedSchedule(
        birthday.id.hashCode,
        '🎂 ${birthday.personName}\'s Birthday!',
        'It\'s ${birthday.personName}\'s special day today! 🎉',
        tzScheduled,
        details,
        payload: birthday.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      if (kDebugMode) {
        print('✅ Notification scheduled for ${birthday.personName} '
            'at $hour:${minute.toString().padLeft(2, '0')} on $scheduledDate');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Error scheduling notification: $e');
        print(stack);
      }
      rethrow;
    }
  }

  static String _customSoundChannelId(String birthdayId, String uri) {
    var hash = 0x811c9dc5;
    for (final unit in uri.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 'birthday_custom_${birthdayId}_$hash';
  }

  /// Send a test notification immediately to verify sound is working
  Future<void> testNotificationSound() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'birthday_channel_sound_v1',
        'Remindra Birthday Alerts',
        channelDescription: 'Remindra birthday notifications with sound',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('birthday_sound'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        999, // test notification ID
        '🎂 Test Birthday Sound',
        'If you hear a sound, everything is working!',
        details,
      );

      if (kDebugMode) {
        print('✅ Test notification sent');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Error sending test notification: $e');
        print(stack);
      }
      rethrow;
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped — payload: ${response.payload}');
    }
  }

  Future<void> cancelBirthdayNotification(String birthdayId) async {
    await _notificationsPlugin.cancel(birthdayId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Reschedule all birthday alarms (call on login and after reboot).
  Future<void> rescheduleAll(List<Birthday> birthdays) async {
    await cancelAllNotifications();
    final failures = <String>[];
    for (final birthday in birthdays) {
      try {
        await scheduleBirthdayNotification(birthday);
      } catch (error, stack) {
        failures.add(birthday.id);
        if (kDebugMode) {
          debugPrint('Could not reschedule birthday ${birthday.id}: $error');
          debugPrintStack(stackTrace: stack);
        }
      }
    }
    if (failures.isNotEmpty) {
      throw BirthdayNotificationRescheduleException(failures);
    }
    if (kDebugMode) print('✅ All birthday notifications rescheduled.');
  }
}

class BirthdayNotificationRescheduleException implements Exception {
  const BirthdayNotificationRescheduleException(this.birthdayIds);

  final List<String> birthdayIds;

  @override
  String toString() =>
      'Could not schedule reminders for ${birthdayIds.length} birthday(s).';
}

// Top-level callback required for background notification handling
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  if (kDebugMode) {
    print('Background notification tapped — payload: ${response.payload}');
  }
}
