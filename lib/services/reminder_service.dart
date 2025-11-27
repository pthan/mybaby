import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/db/app_database.dart';
import '../data/repositories/diaper_repository.dart';

/// Simple local notification service used for feed/water reminders.
class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _waterId = 200;
  static const _milkId = 201;
  static const _diaperId = 202;
  // Use a dedicated alarm channel so Android treats the reminder like an alarm
  // (full-screen, loud, and not easily dismissible).
  static const _channelId = 'reminder_alarm_v3';
  static const _iosCategoryId = 'reminder_alarm_actions';
  static const _dismissActionId = 'dismiss_reminder_alarm';
  static const _changeNowActionId = 'change_now_reminder_alarm';

  Future<void> Function()? _onDiaperChangeNow;

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
              'Got it',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              _changeNowActionId,
              'Change Now',
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
      _alarmDetails(
        title: 'Drink water',
        body: 'You are behind today. Log some water now.',
        payload: 'water_alarm',
        includeChangeAction: false,
      ),
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
      _alarmDetails(
        title: 'Time to feed baby',
        body: 'Based on policy reminder.',
        payload: 'milk_alarm',
        includeChangeAction: false,
      ),
      androidScheduleMode: mode,
      payload: 'milk_alarm',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> scheduleDiaperReminder(DateTime when) async {
    await _ensurePermissions();
    final now = DateTime.now();
    if (!when.isAfter(now)) return;
    final target = tz.TZDateTime.from(when, tz.local);
    final mode = await _scheduleMode();
    await _plugin.zonedSchedule(
      _diaperId,
      'Your baby needs a diaper change',
      'Your baby needs to remove diaper now.',
      target,
      _alarmDetails(
        title: 'Your baby needs a diaper change',
        body: 'Change diaper now to keep baby comfy.',
        payload: 'diaper_alarm',
        includeChangeAction: true,
      ),
      androidScheduleMode: mode,
      payload: 'diaper_alarm',
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
      _alarmDetails(
        title: 'Time to feed baby',
        body: 'Reminder just reached.',
        payload: 'milk_alarm',
        includeChangeAction: false,
      ),
      payload: 'milk_alarm',
    );
  }

  Future<void> showDiaperNow() async {
    await _ensurePermissions();
    await _plugin.show(
      _diaperId,
      'Your baby needs a diaper change',
      'Change diaper now to keep baby comfy.',
      _alarmDetails(
        title: 'Your baby needs a diaper change',
        body: 'Change diaper now to keep baby comfy.',
        payload: 'diaper_alarm',
        includeChangeAction: true,
      ),
      payload: 'diaper_alarm',
    );
  }

  Future<void> cancelWaterReminder() => _plugin.cancel(_waterId);

  Future<void> cancelMilkReminder() => _plugin.cancel(_milkId);
  Future<void> cancelDiaperReminder() => _plugin.cancel(_diaperId);

  void registerDiaperChangeHandler(Future<void> Function()? handler) {
    _onDiaperChangeNow = handler;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    // Use alarmClock to get the system to treat the reminder as a user-visible alarm
    // that survives process death and aggressively wakes the device.
    return AndroidScheduleMode.alarmClock;
  }

  NotificationDetails _alarmDetails({
    String title = 'Reminder Alarms',
    required String body,
    required String payload,
    required bool includeChangeAction,
  }) {
    final android = AndroidNotificationDetails(
      _channelId,
      'Reminder Alarms',
      channelDescription: 'Feed, diaper, and water reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Alarm',
      ),
      visibility: NotificationVisibility.public,
      ticker: 'Reminder alarm',
      // Keep the alarm sound looping until the user presses the action button.
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
      actions: [
        AndroidNotificationAction(
          _dismissActionId,
          'Got it',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        if (includeChangeAction)
          AndroidNotificationAction(
            _changeNowActionId,
            'Change Now',
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
    if (response.actionId == _dismissActionId || response.actionId == _changeNowActionId) {
      _plugin.cancel(_milkId);
      _plugin.cancel(_diaperId);
      if (response.actionId == _changeNowActionId) {
        final handler = _onDiaperChangeNow;
        if (handler != null) {
          unawaited(handler());
        } else {
          unawaited(_finishDiaperChangeInDb());
        }
      }
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  if (response.actionId == ReminderService._dismissActionId || response.actionId == ReminderService._changeNowActionId) {
    final plugin = FlutterLocalNotificationsPlugin();
    plugin.cancel(ReminderService._milkId);
    plugin.cancel(ReminderService._diaperId);
    if (response.actionId == ReminderService._changeNowActionId) {
      unawaited(_finishDiaperChangeInDb());
    }
  }
}

Future<void> _finishDiaperChangeInDb() async {
  try {
    final db = AppDatabase();
    final repo = DiaperRepository(db);
    await repo.finishChange(DateTime.now());
  } catch (_) {
    // Silently ignore to avoid crashing background isolate.
  }
}

