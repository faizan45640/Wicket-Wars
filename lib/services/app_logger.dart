import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    _write('DEBUG', message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _write('INFO', message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _write('WARN', message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _write('ERROR', message, error: error, stackTrace: stackTrace);
  }

  static void event(String name, [Map<String, Object?> data = const {}]) {
    final suffix =
        data.isEmpty
            ? ''
            : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    info('event:$name$suffix');
  }

  static void _write(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final text = '[$level] $message';
    developer.log(
      text,
      name: 'WicketWars',
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) debugPrint(text);
  }
}
