/// Custom exception types for database operations.
///
/// This file defines a hierarchy of exceptions used throughout the database
/// layer for proper error handling and reporting.

/// Base exception class for all database-related errors.
///
/// This exception includes context about the operation that failed and
/// the underlying cause of the error.
class DatabaseException implements Exception {
  /// Human-readable error message
  final String message;

  /// The database operation that failed (e.g., 'insert', 'update', 'query')
  final String? operation;

  /// The underlying cause of the error (e.g., SQLException)
  final dynamic cause;

  DatabaseException(this.message, {this.operation, this.cause});

  @override
  String toString() =>
      'DatabaseException: $message${operation != null ? ' (operation: $operation)' : ''}';
}

/// Exception thrown when a database migration fails.
///
/// This exception includes information about the migration versions involved
/// to help diagnose migration issues.
class MigrationException extends DatabaseException {
  /// The database version before the migration
  final int fromVersion;

  /// The target database version
  final int toVersion;

  MigrationException(
    String message, {
    required this.fromVersion,
    required this.toVersion,
    dynamic cause,
  }) : super(message, operation: 'migration', cause: cause);
}

/// Exception thrown when data validation fails.
///
/// This exception includes a map of field-specific validation errors
/// to provide detailed feedback about what validation rules were violated.
class ValidationException extends DatabaseException {
  /// Map of field names to validation error messages
  final Map<String, String> errors;

  ValidationException(String message, this.errors)
      : super(message, operation: 'validation');
}

/// Exception thrown when a concurrency conflict occurs.
///
/// This exception is used when multiple operations attempt to modify
/// the same data simultaneously, causing a conflict.
class ConcurrencyException extends DatabaseException {
  ConcurrencyException(String message, {dynamic cause})
      : super(message, operation: 'concurrent_access', cause: cause);
}
