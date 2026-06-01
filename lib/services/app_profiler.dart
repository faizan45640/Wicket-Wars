import 'dart:developer';

import 'app_logger.dart';

class AppProfiler {
  const AppProfiler._();

  static Future<T> trace<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final task = TimelineTask()..start(label);
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      task.finish();
      AppLogger.info('$label completed in ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}
