import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/database_exceptions.dart' as db_exceptions;
import 'package:goldfit_frontend/shared/utils/error_logger.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';

/// Concrete implementation of OutfitRepository using SQLite.
///
/// This class handles all database operations for outfits including:
/// - CRUD operations (create, read, update, delete)
/// - Multi-table operations with outfit_items junction table
/// - Calendar assignments and queries
/// - Data transformation between domain models and database records
///
/// All multi-table operations use transactions to ensure atomicity.
class OutfitRepositoryImpl implements OutfitRepository {
  final DatabaseManager _dbManager;

  OutfitRepositoryImpl(this._dbManager);

  @override
  Future<Outfit> create(Outfit outfit) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        // Insert outfit record
        await txn.insert(
          DatabaseConstants.tableOutfits,
          _toMap(outfit),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert outfit_items junction records
        for (int i = 0; i < outfit.itemIds.length; i++) {
          await txn.insert(
            DatabaseConstants.tableOutfitItems,
            {
              DatabaseConstants.columnOutfitId: outfit.id,
              DatabaseConstants.columnClothingItemId: outfit.itemIds[i],
              DatabaseConstants.columnLayerOrder: i,
              DatabaseConstants.columnCreatedAt:
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return outfit;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to create outfit: $e', context: 'OutfitRepository.insert', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to create outfit: $e',
      operation: 'insert',
        cause: e,
      );
    }
  }

  @override
  Future<Outfit?> getById(String id) async {
    final db = await _dbManager.database;

    try {
      // Query outfit record
      final outfitResults = await db.query(
        DatabaseConstants.tableOutfits,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );

      if (outfitResults.isEmpty) return null;

      // Query outfit_items junction records
      final itemResults = await db.query(
        DatabaseConstants.tableOutfitItems,
        where: '${DatabaseConstants.columnOutfitId} = ?',
        whereArgs: [id],
        orderBy: DatabaseConstants.columnLayerOrder,
      );

      final itemIds = itemResults
          .map((row) => row[DatabaseConstants.columnClothingItemId] as String)
          .toList();

      return _fromMap(outfitResults.first, itemIds);
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get outfit by id: $e', context: 'OutfitRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get outfit by id: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<Outfit>> getAll() async {
    final db = await _dbManager.database;

    try {
      final outfitResults = await db.query(
        DatabaseConstants.tableOutfits,
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final outfits = <Outfit>[];
      for (final outfitMap in outfitResults) {
        final outfitId = outfitMap[DatabaseConstants.columnId] as String;

        // Query outfit_items for this outfit
        final itemResults = await db.query(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [outfitId],
          orderBy: DatabaseConstants.columnLayerOrder,
        );

        final itemIds = itemResults
            .map((row) => row[DatabaseConstants.columnClothingItemId] as String)
            .toList();

        outfits.add(_fromMap(outfitMap, itemIds));
      }

      return outfits;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get all outfits: $e', context: 'OutfitRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get all outfits: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<Outfit>> getByVibe(String vibe) async {
    final db = await _dbManager.database;

    try {
      final outfitResults = await db.query(
        DatabaseConstants.tableOutfits,
        where: '${DatabaseConstants.columnVibe} = ?',
        whereArgs: [vibe],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final outfits = <Outfit>[];
      for (final outfitMap in outfitResults) {
        final outfitId = outfitMap[DatabaseConstants.columnId] as String;

        // Query outfit_items for this outfit
        final itemResults = await db.query(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [outfitId],
          orderBy: DatabaseConstants.columnLayerOrder,
        );

        final itemIds = itemResults
            .map((row) => row[DatabaseConstants.columnClothingItemId] as String)
            .toList();

        outfits.add(_fromMap(outfitMap, itemIds));
      }

      return outfits;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get outfits by vibe: $e', context: 'OutfitRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get outfits by vibe: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<Outfit> update(Outfit outfit) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        // Update outfit record
        final rowsAffected = await txn.update(
          DatabaseConstants.tableOutfits,
          _toMap(outfit),
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [outfit.id],
        );

        if (rowsAffected == 0) {
          throw db_exceptions.DatabaseException(
            'Outfit with id ${outfit.id} not found',
            operation: 'update',
          );
        }

        // Synchronize outfit_items junction table
        // Delete existing items
        await txn.delete(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [outfit.id],
        );

        // Insert updated items
        for (int i = 0; i < outfit.itemIds.length; i++) {
          await txn.insert(
            DatabaseConstants.tableOutfitItems,
            {
              DatabaseConstants.columnOutfitId: outfit.id,
              DatabaseConstants.columnClothingItemId: outfit.itemIds[i],
              DatabaseConstants.columnLayerOrder: i,
              DatabaseConstants.columnCreatedAt:
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return outfit;
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) rethrow;
      ErrorLogger.log('Failed to update outfit: $e', context: 'OutfitRepository.update', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to update outfit: $e',
      operation: 'update',
        cause: e,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        // Delete from outfit_items junction table (cascade)
        await txn.delete(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [id],
        );

        // Delete from outfit_calendar table (cascade)
        await txn.delete(
          DatabaseConstants.tableOutfitCalendar,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [id],
        );

        // Delete the outfit
        final rowsAffected = await txn.delete(
          DatabaseConstants.tableOutfits,
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [id],
        );

        if (rowsAffected == 0) {
          throw db_exceptions.DatabaseException(
            'Outfit with id $id not found',
            operation: 'delete',
          );
        }
      });
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) rethrow;
      ErrorLogger.log('Failed to delete outfit: $e', context: 'OutfitRepository.delete', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to delete outfit: $e',
      operation: 'delete',
        cause: e,
      );
    }
  }

  @override
  Future<void> assignToDate(String outfitId, DateTime date, String timeSlot, {String? eventName, String? startTime}) async {
    final db = await _dbManager.database;

    try {
      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await db.transaction((txn) async {
        // Insert calendar assignment
        await txn.insert(
          DatabaseConstants.tableOutfitCalendar,
          {
            DatabaseConstants.columnId: '${outfitId}_${normalizedDate.millisecondsSinceEpoch}_$timeSlot',
            DatabaseConstants.columnOutfitId: outfitId,
            DatabaseConstants.columnAssignedDate: normalizedDate.millisecondsSinceEpoch,
            DatabaseConstants.columnTimeSlot: timeSlot,
            DatabaseConstants.columnEventName: eventName,
            DatabaseConstants.columnStartTime: startTime,
            DatabaseConstants.columnCreatedAt: DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // If the date is in the past, record usage
        if (normalizedDate.isBefore(today)) {
          await recordUsage(outfitId, normalizedDate, txn: txn);
        }
      });
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to assign outfit to date: $e', context: 'OutfitRepository.insert', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to assign outfit to date: $e',
      operation: 'insert',
        cause: e,
      );
    }
  }

  /// Records usage history for all clothing items in an outfit.
  ///
  /// This method:
  /// - Creates usage_history records for each clothing item in the outfit
  /// - Increments the usage_count for each clothing item
  ///
  /// Parameters:
  /// - outfitId: The ID of the outfit being worn
  /// - date: The date the outfit was worn
  /// - txn: Optional transaction to use (for atomic operations)
  Future<void> recordUsage(
    String outfitId,
    DateTime date, {
    Transaction? txn,
  }) async {
    final db = txn ?? await _dbManager.database;

    try {
      // Get all clothing items in the outfit
      final itemResults = await db.query(
        DatabaseConstants.tableOutfitItems,
        where: '${DatabaseConstants.columnOutfitId} = ?',
        whereArgs: [outfitId],
      );

      final now = DateTime.now();

      // For each clothing item, create usage history and increment usage count
      for (final itemRow in itemResults) {
        final clothingItemId = itemRow[DatabaseConstants.columnClothingItemId] as String;

        // Insert usage history record
        await db.insert(
          DatabaseConstants.tableUsageHistory,
          {
            DatabaseConstants.columnId: '${clothingItemId}_${outfitId}_${date.millisecondsSinceEpoch}',
            DatabaseConstants.columnClothingItemId: clothingItemId,
            DatabaseConstants.columnOutfitId: outfitId,
            DatabaseConstants.columnWornDate: date.millisecondsSinceEpoch,
            DatabaseConstants.columnCreatedAt: now.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Increment usage count
        await db.rawUpdate('''
          UPDATE ${DatabaseConstants.tableClothingItems}
          SET ${DatabaseConstants.columnUsageCount} = ${DatabaseConstants.columnUsageCount} + 1,
              ${DatabaseConstants.columnUpdatedAt} = ?
          WHERE ${DatabaseConstants.columnId} = ?
        ''', [now.millisecondsSinceEpoch, clothingItemId]);
      }
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to record usage: $e', context: 'OutfitRepository.insert', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to record usage: $e',
      operation: 'insert',
        cause: e,
      );
    }
  }

  @override
  Future<void> unassignFromDate(DateTime date, String timeSlot) async {
    final db = await _dbManager.database;

    try {
      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      await db.delete(
        DatabaseConstants.tableOutfitCalendar,
        where: '${DatabaseConstants.columnAssignedDate} = ? AND ${DatabaseConstants.columnTimeSlot} = ?',
        whereArgs: [normalizedDate.millisecondsSinceEpoch, timeSlot],
      );
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to unassign outfit from date: $e', context: 'OutfitRepository.delete', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to unassign outfit from date: $e',
      operation: 'delete',
        cause: e,
      );
    }
  }

  @override
  Future<List<Outfit>> getByDate(DateTime date) async {
    final db = await _dbManager.database;

    try {
      // Normalize date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Join outfit_calendar and outfits tables
      final results = await db.rawQuery('''
        SELECT o.* FROM ${DatabaseConstants.tableOutfits} o
        INNER JOIN ${DatabaseConstants.tableOutfitCalendar} oc
        ON o.${DatabaseConstants.columnId} = oc.${DatabaseConstants.columnOutfitId}
        WHERE oc.${DatabaseConstants.columnAssignedDate} = ?
      ''', [normalizedDate.millisecondsSinceEpoch]);

      final outfits = <Outfit>[];
      for (final outfitMap in results) {
        final outfitId = outfitMap[DatabaseConstants.columnId] as String;

        // Query outfit_items for this outfit
        final itemResults = await db.query(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [outfitId],
          orderBy: DatabaseConstants.columnLayerOrder,
        );

        final itemIds = itemResults
            .map((row) => row[DatabaseConstants.columnClothingItemId] as String)
            .toList();

        outfits.add(_fromMap(outfitMap, itemIds));
      }

      return outfits;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get outfits by date: $e', context: 'OutfitRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get outfits by date: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<Outfit>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbManager.database;

    try {
      // Normalize dates to midnight
      final normalizedStart = DateTime(start.year, start.month, start.day);
      final normalizedEnd = DateTime(end.year, end.month, end.day);

      // Join outfit_calendar and outfits tables
      final results = await db.rawQuery('''
        SELECT o.*, oc.${DatabaseConstants.columnAssignedDate}, oc.${DatabaseConstants.columnTimeSlot}, oc.${DatabaseConstants.columnEventName}, oc.${DatabaseConstants.columnStartTime}
        FROM ${DatabaseConstants.tableOutfits} o
        INNER JOIN ${DatabaseConstants.tableOutfitCalendar} oc
        ON o.${DatabaseConstants.columnId} = oc.${DatabaseConstants.columnOutfitId}
        WHERE oc.${DatabaseConstants.columnAssignedDate} >= ?
        AND oc.${DatabaseConstants.columnAssignedDate} <= ?
        ORDER BY oc.${DatabaseConstants.columnAssignedDate} ASC
      ''', [normalizedStart.millisecondsSinceEpoch, normalizedEnd.millisecondsSinceEpoch]);

      final outfits = <Outfit>[];
      for (final outfitMap in results) {
        final outfitId = outfitMap[DatabaseConstants.columnId] as String;

        // Query outfit_items for this outfit
        final itemResults = await db.query(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [outfitId],
          orderBy: DatabaseConstants.columnLayerOrder,
        );

        final itemIds = itemResults
            .map((row) => row[DatabaseConstants.columnClothingItemId] as String)
            .toList();

        // Get assigned date and optional fields from the join result
        final assignedDate = DateTime.fromMillisecondsSinceEpoch(
          outfitMap[DatabaseConstants.columnAssignedDate] as int,
        );
        final timeSlot = outfitMap[DatabaseConstants.columnTimeSlot] as String?;
        final eventName = outfitMap[DatabaseConstants.columnEventName] as String?;
        final startTime = outfitMap[DatabaseConstants.columnStartTime] as String?;

        outfits.add(_fromMap(outfitMap, itemIds, assignedDate: assignedDate, timeSlot: timeSlot, eventName: eventName, startTime: startTime));
      }

      return outfits;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get outfits by date range: $e', context: 'OutfitRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get outfits by date range: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Stream<List<Outfit>> watchAll() async* {
    // For real-time updates, we'd use a StreamController
    // and trigger updates when data changes
    // For now, just yield the current state
    yield await getAll();
  }

  /// Converts an Outfit domain model to a database map.
  ///
  /// This method handles:
  /// - Converting DateTime to milliseconds since epoch
  /// - Setting updated_at timestamp to current time
  /// - Handling optional fields (vibe, thumbnailPath, weatherContext)
  ///
  /// Note: itemIds are stored in the outfit_items junction table, not in this map.
  Map<String, dynamic> _toMap(Outfit outfit) {
    return {
      DatabaseConstants.columnId: outfit.id,
      DatabaseConstants.columnName: outfit.name,
      DatabaseConstants.columnVibe: outfit.vibe,
      DatabaseConstants.columnThumbnailPath: null, // Future feature
      DatabaseConstants.columnWeatherContext: null, // Future feature
      DatabaseConstants.columnIsFavorite: outfit.isFavorite ? 1 : 0,
      DatabaseConstants.columnModelImagePath: outfit.modelImagePath,
      DatabaseConstants.columnResultImagePath: outfit.resultImagePath,
      DatabaseConstants.columnCreatedAt: outfit.createdDate.millisecondsSinceEpoch,
      DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Converts a database map to an Outfit domain model.
  ///
  /// This method handles:
  /// - Converting milliseconds since epoch to DateTime
  /// - Handling optional fields
  /// - Accepting itemIds from the junction table query
  ///
  /// Parameters:
  /// - map: The database row from the outfits table
  /// - itemIds: The list of clothing item IDs from the outfit_items junction table
  /// - assignedDate: Optional assigned date from outfit_calendar join
  Outfit _fromMap(
    Map<String, dynamic> map,
    List<String> itemIds, {
    DateTime? assignedDate,
    String? timeSlot,
    String? eventName,
    String? startTime,
  }) {
    return Outfit(
      id: map[DatabaseConstants.columnId] as String,
      name: map[DatabaseConstants.columnName] as String,
      itemIds: itemIds,
      assignedDate: assignedDate,
      timeSlot: timeSlot,
      eventName: eventName,
      startTime: startTime,
      vibe: map[DatabaseConstants.columnVibe] as String?,
      createdDate: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.columnCreatedAt] as int,
      ),
      isFavorite: (map[DatabaseConstants.columnIsFavorite] as int?) == 1,
      modelImagePath: map[DatabaseConstants.columnModelImagePath] as String?,
      resultImagePath: map[DatabaseConstants.columnResultImagePath] as String?,
    );
  }
}
