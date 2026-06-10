import 'package:shared_preferences/shared_preferences.dart';

/// Tiny persisted bridge between the foreground app and the background
/// Workmanager isolate.
///
/// The UI records when training energy will be full; the background task reads
/// it (in a *separate isolate*, with no access to Riverpod/Firebase state) to
/// decide whether to fire the "energy full" reminder. It also records run
/// metadata so we can prove the periodic task actually executed.
class TrainingReminderStore {
  TrainingReminderStore._();

  static const String _energyFullAtKey = 'training_energy_full_at_ms';
  static const String _energyPendingKey = 'training_energy_notify_pending';
  static const String _lastRunKey = 'bg_last_run_ms';
  static const String _runCountKey = 'bg_run_count';

  /// Persist the moment training energy becomes full and mark a reminder as due.
  static Future<void> setEnergyFullAt(DateTime fullAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_energyFullAtKey, fullAt.millisecondsSinceEpoch);
    await prefs.setBool(_energyPendingKey, true);
  }

  /// Clear any pending reminder (energy already full / cancelled).
  static Future<void> clearEnergyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_energyFullAtKey);
    await prefs.setBool(_energyPendingKey, false);
  }

  static Future<DateTime?> energyFullAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_energyFullAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<bool> isReminderPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_energyPendingKey) ?? false;
  }

  /// Called by the background task once it has delivered the reminder.
  static Future<void> markEnergyNotified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_energyPendingKey, false);
  }

  /// Records that the background task ran (timestamp + monotonically increasing
  /// counter). Surfaced in the Profile screen as proof the task is alive.
  static Future<int> recordBackgroundRun() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_runCountKey) ?? 0) + 1;
    await prefs.setInt(_runCountKey, count);
    await prefs.setInt(_lastRunKey, DateTime.now().millisecondsSinceEpoch);
    return count;
  }

  static Future<({DateTime? lastRun, int count})> backgroundRunInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastRunKey);
    return (
      lastRun: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      count: prefs.getInt(_runCountKey) ?? 0,
    );
  }
}
