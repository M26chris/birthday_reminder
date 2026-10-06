import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:birthday_reminder/helpers/birthday.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class BirthdayNotificationManager {
  static final BirthdayNotificationManager _instance =
      BirthdayNotificationManager._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory BirthdayNotificationManager() => _instance;

  BirthdayNotificationManager._internal();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // FIX: getLocalTimezone() returns String directly — no .identifier needed
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;

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
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    await _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Schedule a local notification for [birthday] using its per-birthday time.
  ///
  /// SOUND SETUP — three steps:
  ///   1. Place your file at: android/app/src/main/res/raw/birthday_sound.mp3
  ///   2. The sound line below is already uncommented — just make sure the
  ///      filename matches (without extension).
  ///   3. Fully uninstall the app then reinstall. Android locks a notification
  ///      channel's sound on first creation — uninstalling resets the channel.
  Future<void> scheduleBirthdayNotification(Birthday birthday) async {
    try {
      final now = DateTime.now();
      final birth = birthday.birth;
      final hour = birthday.notificationHour;
      final minute = birthday.notificationMinute;

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

      // ── Notification channel (v3 = fresh channel with sound baked in) ──
      // IMPORTANT: If you previously installed the app, UNINSTALL it first
      // so Android creates this channel fresh with the sound attached.
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'birthday_channel_sound_v1',       // new channel id — forces fresh channel
        'Birthday Reminders',
        channelDescription: 'Remindra birthday notifications with sound',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        // sound: null,
        sound: RawResourceAndroidNotificationSound('birthday_sound'),
        styleInformation: BigTextStyleInformation(''),  // Ensures sound plays
        audioAttributesUsage: AudioAttributesUsage.notification,  // Proper audio category
        // ↑ File: android/app/src/main/res/raw/birthday_sound.mp3
        // Remove the sound line if you don't have the file yet.
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // sound: 'birthday_sound.aiff', // add iOS sound file later
      );

      const NotificationDetails details = NotificationDetails(
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
      // Report to Crashlytics in release mode
      // FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  /// Send a test notification immediately to verify sound is working
  Future<void> testNotificationSound() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'birthday_channel_sound_v1',
        'Birthday Reminders',
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
    for (final birthday in birthdays) {
      await scheduleBirthdayNotification(birthday);
    }
    if (kDebugMode) print('✅ All birthday notifications rescheduled.');
  }
}

// Top-level callback required for background notification handling
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  if (kDebugMode) {
    print('Background notification tapped — payload: ${response.payload}');
  }
}
