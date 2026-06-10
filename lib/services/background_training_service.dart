import 'package:workmanager/workmanager.dart';

import 'app_logger.dart';
import 'local_notification_service.dart';
import 'training_reminder_store.dart';

const String kTrainingRefreshTask = 'wicket_wars_training_refresh';

/// Entry point for the background isolate spawned by Workmanager.
///
/// This runs in a *separate isolate* with no access to the app's Riverpod
/// providers or live Firebase state, so it communicates with the foreground
/// app through [TrainingReminderStore] (SharedPreferences). On each run it:
///   1. Records that it executed (timestamp + counter) for proof/observability.
///   2. Checks whether training energy has finished recharging and, if a
///      reminder is still pending, delivers the notification itself — acting as
///      a backstop for the exact-time alarm that may be dropped if the app was
///      killed.
@pragma('vm:entry-point')
void backgroundTrainingCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final runCount = await TrainingReminderStore.recordBackgroundRun();
      final fullAt = await TrainingReminderStore.energyFullAt();
      final pending = await TrainingReminderStore.isReminderPending();
      AppLogger.event('bg_task_run', {
        'task': task,
        'run': runCount,
        'pending': pending,
        'fullAt': fullAt?.toIso8601String() ?? 'none',
      });

      final due =
          pending && fullAt != null && !fullAt.isAfter(DateTime.now());
      if (due) {
        await LocalNotificationService.instance.initialize();
        await LocalNotificationService.instance.showTrainingEnergyFullNow();
        await TrainingReminderStore.markEnergyNotified();
        AppLogger.event('bg_energy_notified', {'run': runCount});
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background task failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  });
}

class BackgroundTrainingService {
  const BackgroundTrainingService._();

  static Future<void> initialize() async {
    await Workmanager().initialize(
      backgroundTrainingCallbackDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      kTrainingRefreshTask,
      kTrainingRefreshTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
    AppLogger.info('Background training refresh task registered');
  }
}
