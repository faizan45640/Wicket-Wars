import 'package:workmanager/workmanager.dart';

import 'app_logger.dart';

const String kTrainingRefreshTask = 'wicket_wars_training_refresh';

@pragma('vm:entry-point')
void backgroundTrainingCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.info('Background task executed: $task');
    return Future.value(true);
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
