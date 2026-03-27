import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:medshelf/core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── Expiry notifications ────────────────────────────────────────────────

  /// Schedule expiry notifications for [AppConstants.expiryWarningDays].
  Future<void> scheduleExpiryNotifications({
    required String medicationId,
    required String medicationName,
    required DateTime expiryDate,
  }) async {
    await cancelExpiryNotifications(medicationId);

    for (final days in AppConstants.expiryWarningDays) {
      final notifyAt = expiryDate.subtract(Duration(days: days));
      final now = DateTime.now();
      if (notifyAt.isBefore(now)) continue;

      final id = _expiryNotificationId(medicationId, days);
      final title = days == 0
          ? '$medicationName expires today!'
          : '$medicationName expires in $days day${days == 1 ? '' : 's'}';

      await _scheduleNotification(
        id: id,
        title: title,
        body: 'Check your MedShelf and restock if needed.',
        scheduledDate: tz.TZDateTime.from(notifyAt, tz.local),
        channelId: 'expiry_channel',
        channelName: 'Expiry Reminders',
      );
    }
  }

  Future<void> cancelExpiryNotifications(String medicationId) async {
    for (final days in AppConstants.expiryWarningDays) {
      await _plugin.cancel(_expiryNotificationId(medicationId, days));
    }
  }

  // ─── Per-batch expiry notifications ──────────────────────────────────────

  /// Schedule expiry notifications for a single box (batch).
  Future<void> scheduleExpiryNotificationsForBatch({
    required String batchId,
    required String medicationName,
    required DateTime expiryDate,
  }) async {
    await cancelExpiryNotificationsForBatch(batchId);

    for (final days in AppConstants.expiryWarningDays) {
      final notifyAt = expiryDate.subtract(Duration(days: days));
      if (notifyAt.isBefore(DateTime.now())) continue;

      final id = _expiryNotificationId(batchId, days);
      final title = days == 0
          ? '$medicationName expires today!'
          : '$medicationName expires in $days day${days == 1 ? '' : 's'}';

      await _scheduleNotification(
        id: id,
        title: title,
        body: 'Check your MedShelf and restock if needed.',
        scheduledDate: tz.TZDateTime.from(notifyAt, tz.local),
        channelId: 'expiry_channel',
        channelName: 'Expiry Reminders',
      );
    }
  }

  Future<void> cancelExpiryNotificationsForBatch(String batchId) async {
    for (final days in AppConstants.expiryWarningDays) {
      await _plugin.cancel(_expiryNotificationId(batchId, days));
    }
  }

  // ─── Dose notifications ──────────────────────────────────────────────────

  /// Schedule a daily dose reminder at [hour]:[minute].
  Future<void> scheduleDoseReminder({
    required String prescriptionId,
    required String medicationName,
    required int hour,
    required int minute,
    String? instructions,
  }) async {
    await cancelDoseReminder(prescriptionId);

    final id = _doseNotificationId(prescriptionId);
    final body = instructions != null && instructions.isNotEmpty
        ? instructions
        : 'Time to take your medication.';

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'Dose reminder: $medicationName',
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_channel',
          'Dose Reminders',
          channelDescription: 'Daily medication dose reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFDC2626),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDoseReminder(String prescriptionId) async {
    await _plugin.cancel(_doseNotificationId(prescriptionId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String channelId,
    required String channelName,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _expiryNotificationId(String medicationId, int days) {
    // 100 000-slot space per base — ~100× less collision risk than 10 000.
    return (AppConstants.expiryNotificationBase +
            medicationId.hashCode.abs() % 100000 +
            days)
        .abs();
  }

  int _doseNotificationId(String prescriptionId) {
    return (AppConstants.doseNotificationBase +
            prescriptionId.hashCode.abs() % 100000)
        .abs();
  }
}
