import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final tagName = tag != null ? '[$tag]' : '[ScanX AI]';
    final levelName = level.name.toUpperCase();

    final logMessage = '$timestamp $levelName $tagName $message';

    if (kDebugMode) {
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack: $stackTrace');
      }
    }
  }

  static void d(String message, [String? tag]) => log(message, level: LogLevel.debug, tag: tag);
  static void i(String message, [String? tag]) => log(message, level: LogLevel.info, tag: tag);
  static void w(String message, [String? tag]) => log(message, level: LogLevel.warning, tag: tag);
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, tag: tag, error: error, stackTrace: stackTrace);
}
