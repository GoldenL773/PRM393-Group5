import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogSeverity { info, warning, error, critical }

/// Service responsible for logging errors to a persistent file.
/// 
/// Validates Requirements: 16.2, 16.4
class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  File? _logFile;
  static const int _maxLogSizeBytes = 1 * 1024 * 1024; // 1MB

  Future<void> _initLogFile() async {
    if (_logFile != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/goldfit_errors.log');
  }

  /// Logs a message to the persistent file.
  static Future<void> log(
    String message, {
    LogSeverity severity = LogSeverity.error,
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    await _instance._logInternal(message, severity, context, error, stackTrace);
  }

  Future<void> _logInternal(
    String message,
    LogSeverity severity,
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await _initLogFile();
    if (_logFile == null) return;

    final timestamp = DateTime.now().toIso8601String();
    final severityStr = severity.name.toUpperCase();
    final contextStr = context != null ? '[$context] ' : '';
    
    final StringBuffer logBuilder = StringBuffer();
    logBuilder.writeln('[$timestamp] [$severityStr] $contextStr$message');
    
    if (error != null) {
      logBuilder.writeln('Error: $error');
    }
    
    if (stackTrace != null) {
      logBuilder.writeln('StackTrace: $stackTrace');
    }
    logBuilder.writeln('---');

    final logEntry = logBuilder.toString();
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint(logEntry);
    }

    try {
      // Check file size for rotation
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > _maxLogSizeBytes) {
          await _rotateLogFile();
        }
      }
      
      await _logFile!.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  Future<void> _rotateLogFile() async {
    if (_logFile == null || !await _logFile!.exists()) return;
    
    final directory = await getApplicationDocumentsDirectory();
    final backupPath = '${directory.path}/goldfit_errors_backup.log';
    final backupFile = File(backupPath);
    
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    
    await _logFile!.rename(backupPath);
    _logFile = File('${directory.path}/goldfit_errors.log');
  }

  /// Reads all log entries from the persistent file.
  static Future<String> readLogs() async {
    await _instance._initLogFile();
    if (_instance._logFile == null || !await _instance._logFile!.exists()) {
      return 'No logs available.';
    }
    
    try {
      return await _instance._logFile!.readAsString();
    } catch (e) {
      return 'Failed to read logs: $e';
    }
  }

  /// Clears the log file.
  static Future<void> clearLogs() async {
    await _instance._initLogFile();
    if (_instance._logFile != null && await _instance._logFile!.exists()) {
      await _instance._logFile!.writeAsString('');
    }
  }
}
