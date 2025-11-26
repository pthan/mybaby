import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Simple local notification service used for feed/water reminders.
class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _waterId = 200;
  static const _milkId = 201;
  // Use a dedicated alarm channel so Android treats the reminder like an alarm
  // (full-screen, loud, and not easily dismissible).
  static const _channelId = 'reminder_alarm_v3';
  static const _iosCategoryId = 'reminder_alarm_actions';
  static const _dismissActionId = 'dismiss_reminder_alarm';

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          _iosCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              _dismissActionId,
              'I got it - Close alarm',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
          options: {DarwinNotificationCategoryOption.allowAnnouncement},
        ),
      ],
    );
    final initSettings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
    await _ensureChannel();
    await _ensurePermissions();
  }

  Future<void> _ensureChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      'Reminder Alarms',
      description: 'Feed and water reminders',
      importance: Importance.max,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      enableVibration: true,
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _ensurePermissions() async {
    // Android
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final enabled = await androidPlugin.areNotificationsEnabled();
    if (enabled != true) {
      await androidPlugin.requestNotificationsPermission();
    }
    final canExact = await androidPlugin.canScheduleExactNotifications() ?? false;
    if (!canExact) {
      await androidPlugin.requestExactAlarmsPermission();
    }

    // iOS
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleWaterReminder(Duration delay) async {
    await _ensurePermissions();
    final when = tz.TZDateTime.now(tz.local).add(delay);
    final mode = await _scheduleMode();
    await _plugin.zonedSchedule(
      _waterId,
      'Drink water',
      'You are behind today. Log some water now.',
      when,
      _alarmDetails(),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> scheduleMilkReminder(DateTime when) async {
    await _ensurePermissions();
    final now = DateTime.now();
    if (!when.isAfter(now)) return;
    final target = tz.TZDateTime.from(when, tz.local);
    final mode = await _scheduleMode();
    await _plugin.zonedSchedule(
      _milkId,
      'Time to feed baby',
      'Based on policy reminder.',
      target,
      _alarmDetails(),
      androidScheduleMode: mode,
      payload: 'milk_alarm',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> showMilkNow() async {
    await _ensurePermissions();
    await _plugin.show(
      _milkId,
      'Time to feed baby',
      'Reminder just reached.',
      _alarmDetails(),
      payload: 'milk_alarm',
    );
  }

  Future<void> cancelWaterReminder() => _plugin.cancel(_waterId);

  Future<void> cancelMilkReminder() => _plugin.cancel(_milkId);

  Future<AndroidScheduleMode> _scheduleMode() async {
    // Use alarmClock to get the system to treat the reminder as a user-visible alarm
    // that survives process death and aggressively wakes the device.
    return AndroidScheduleMode.alarmClock;
  }

  NotificationDetails _alarmDetails() {
    final android = AndroidNotificationDetails(
      _channelId,
      'Reminder Alarms',
      channelDescription: 'Feed and water reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: const BigTextStyleInformation(
        'Reminder just reached.',
        contentTitle: 'Time to feed baby',
        summaryText: 'Alarm',
      ),
      visibility: NotificationVisibility.public,
      ticker: 'Reminder alarm',
      // Keep the alarm sound looping until the user presses the action button.
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
      actions: [
        AndroidNotificationAction(
          _dismissActionId,
          'I got it - Close alarm',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentBanner: true,
      presentList: true,
      categoryIdentifier: _iosCategoryId,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    // Only handle explicit "Close alarm" action; plain dismiss callbacks are not exposed.
    if (response.actionId == _dismissActionId) {
      _plugin.cancel(_milkId);
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  if (response.actionId == ReminderService._dismissActionId) {
    final plugin = FlutterLocalNotificationsPlugin();
    plugin.cancel(ReminderService._milkId);
  }
}

