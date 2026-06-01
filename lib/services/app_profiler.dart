import 'dart:developer';

import 'app_logger.dart';

class AppProfiler {
  const AppProfiler._();

  static Future<T> trace<T>(String label, Future<T> Function() action) async {
    final task = TimelineTask()..start(label);
    final stopwatch = Stopwatch()..start();
    var succeeded = false;
    try {
      final result = await action();
      succeeded = true;
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        '$label failed after ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      stopwatch.stop();
      task.finish();
      if (succeeded) {
        AppLogger.info(
          '$label completed in ${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
  }

  static T traceSync<T>(String label, T Function() action) {
    final task = TimelineTask()..start(label);
    final stopwatch = Stopwatch()..start();
    var succeeded = false;
    try {
      final result = action();
      succeeded = true;
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        '$label failed after ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      stopwatch.stop();
      task.finish();
      if (succeeded) {
        AppLogger.info(
          '$label completed in ${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
  }
}
