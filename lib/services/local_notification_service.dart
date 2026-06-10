import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_logger.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  /// Stable notification ids so re-scheduling replaces the previous one.
  static const int _dailyRewardClaimedId = 9001;
  static const int _dailyRewardUnlockId = 9100;
  static const int _trainingEnergyFullId = 9200;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _tzReady = false;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    if (!kIsWeb) {
      tz_data.initializeTimeZones();
      _tzReady = true;
    }
    AppLogger.info('Local notifications initialized');
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    AppLogger.info('Notification permission: ${status.name}');
    return status.isGranted;
  }

  Future<void> showDailyRewardClaimed({
    required int coins,
    required int streak,
  }) async {
    const android = AndroidNotificationDetails(
      'reward_events',
      'Reward Events',
      channelDescription: 'Daily reward and coin event updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      _dailyRewardClaimedId,
      'Daily reward claimed',
      '+$coins coins · $streak day streak',
      details,
    );
  }

  /// Schedules a reminder for when the next daily reward becomes claimable.
  Future<void> scheduleDailyRewardUnlock({required DateTime unlockAt}) async {
    await _zonedSchedule(
      id: _dailyRewardUnlockId,
      when: unlockAt,
      channelId: 'reward_events',
      channelName: 'Reward Events',
      channelDescription: 'Daily reward and coin event updates',
      title: 'Daily reward ready',
      body: 'Your daily coins are waiting — claim them to keep your streak!',
    );
  }

  /// Schedules a reminder for when training energy is fully recharged.
  Future<void> scheduleTrainingEnergyFull({required DateTime fullAt}) async {
    await _zonedSchedule(
      id: _trainingEnergyFullId,
      when: fullAt,
      channelId: 'training_events',
      channelName: 'Training Events',
      channelDescription: 'Player training and energy reminders',
      title: 'Training energy full',
      body: 'Your squad is rested — spend your energy on some upgrades.',
    );
  }

  /// Fires the "training energy full" notification immediately. Used by the
  /// background task as a backstop when the scheduled alarm may have been lost
  /// (e.g. the app was killed before the exact unlock time).
  Future<void> showTrainingEnergyFullNow() async {
    const android = AndroidNotificationDetails(
      'training_events',
      'Training Events',
      channelDescription: 'Player training and energy reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      _trainingEnergyFullId,
      'Training energy full',
      'Your squad is rested — spend your energy on some upgrades.',
      details,
    );
    AppLogger.info('Training energy full notification shown from background');
  }

  Future<void> cancelTrainingEnergyFull() => _cancel(_trainingEnergyFullId);

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      AppLogger.warning('Cancel notification $id failed', error: e);
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required DateTime when,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_tzReady) return;
    // Don't schedule in the past.
    if (!when.isAfter(DateTime.now())) return;
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      // tz.local defaults to UTC, but TZDateTime.from preserves the absolute
      // instant, so the alarm fires at the correct wall-clock time anyway.
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      AppLogger.info('Scheduled notification $id for $when');
    } catch (e, st) {
      AppLogger.warning(
        'Schedule notification $id failed',
        error: e,
        stackTrace: st,
      );
    }
  }
}
