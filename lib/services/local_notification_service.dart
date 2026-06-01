import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_logger.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    AppLogger.info('Local notifications initialized');
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    AppLogger.info('Notification permission: ${status.name}');
    return status.isGranted;
  }

  Future<void> showTrainingCompleteReminder({
    required String playerName,
  }) async {
    const android = AndroidNotificationDetails(
      'training_events',
      'Training Events',
      channelDescription: 'Player training and reward reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      playerName.hashCode,
      'Training complete',
      '$playerName is ready for selection.',
      details,
    );
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
      9001,
      'Daily reward claimed',
      '+$coins coins · $streak day streak',
      details,
    );
  }
}
