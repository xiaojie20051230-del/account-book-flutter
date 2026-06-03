import 'dart:developer' as developer;

enum LogLevel { verbose, debug, info, warning, error }

class AppLogger {
  static LogLevel _minLevel = LogLevel.verbose;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void v(String message, {String tag = 'APP', Map<String, dynamic>? data}) {
    _log(LogLevel.verbose, message, tag: tag, data: data);
  }

  static void d(String message, {String tag = 'APP', Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  static void i(String message, {String tag = 'APP', Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  static void w(String message, {String tag = 'APP', Map<String, dynamic>? data, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, data: data, error: error);
  }

  static void e(String message, {
    String tag = 'APP',
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final time = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln('[$time] [$levelStr] [$tag] $message');
    if (data != null) buffer.writeln('    DATA: $data');
    if (error != null) buffer.writeln('    ERROR: $error');
    if (stackTrace != null) buffer.writeln('    STACK: $stackTrace');

    developer.log(
      buffer.toString(),
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
