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

    await _plugin.zonedSchedule(
      id,
      'Dose reminder: $medicationName',
      body,
      _nextInstanceOfTime(hour, minute),
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

  // ─── Per-item dose notifications ─────────────────────────────────────────

  /// Schedule a daily reminder for a single item in a prescription.
  Future<void> scheduleDoseReminderForItem({
    required String prescriptionId,
    required int itemIndex,
    required String medicationName,
    required int hour,
    required int minute,
    String? instructions,
  }) async {
    await cancelDoseReminderForItem(prescriptionId, itemIndex);

    final id = _doseNotificationIdForItem(prescriptionId, itemIndex);
    final body = instructions != null && instructions.isNotEmpty
        ? instructions
        : 'Time to take your medication.';

    await _plugin.zonedSchedule(
      id,
      'Dose reminder: $medicationName',
      body,
      _nextInstanceOfTime(hour, minute),
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

  Future<void> cancelDoseReminderForItem(
      String prescriptionId, int itemIndex) async {
    await _plugin.cancel(_doseNotificationIdForItem(prescriptionId, itemIndex));
  }

  /// Cancels the whole-prescription reminder plus up to [maxItems] per-item reminders.
  Future<void> cancelAllDoseRemindersForPrescription(
      String prescriptionId, {int maxItems = 20}) async {
    await cancelDoseReminder(prescriptionId);
    for (int i = 0; i < maxItems; i++) {
      await cancelDoseReminderForItem(prescriptionId, i);
    }
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

  /// Returns the next occurrence of [hour]:[minute] in local device time,
  /// converted to a [tz.TZDateTime] preserving the correct UTC instant.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    // Convert local DateTime → tz.TZDateTime via epoch ms (preserves offset).
    return tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.local, scheduled.millisecondsSinceEpoch);
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

  int _doseNotificationIdForItem(String prescriptionId, int itemIndex) {
    return ('${prescriptionId}_item_$itemIndex'.hashCode.abs() % 500000 +
            AppConstants.doseNotificationBase)
        .abs();
  }
}
