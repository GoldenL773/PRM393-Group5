import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/database_exceptions.dart' as db_exceptions;
import 'package:goldfit_frontend/shared/utils/error_logger.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';

/// Concrete implementation of AnalyticsRepository using SQLite.
///
/// This class handles all analytics and aggregation queries including:
/// - Wardrobe statistics (total items, total value)
/// - Usage tracking and history
/// - Most/least worn items analysis
/// - Item count by type aggregation
///
/// Implements in-memory caching for analytics results to improve performance.
/// Cache is invalidated when clothing items or outfits are modified.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final DatabaseManager _dbManager;

  // Cache for analytics results
  WardrobeAnalytics? _cachedAnalytics;
  DateTime? _cacheTimestamp;
  
  // Cache expiration duration (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  AnalyticsRepositoryImpl(this._dbManager);

  @override
  Future<WardrobeAnalytics> getAnalytics() async {
    try {
      // Check if cache is valid
      if (_isCacheValid()) {
        return _cachedAnalytics!;
      }

      // Execute all analytics queries in parallel for better performance
      final results = await Future.wait([
        _getTotalItemCount(),
        getTotalValue(),
        getMostWorn(5),
        getLeastWorn(5),
      ]);

      final analytics = WardrobeAnalytics(
        totalItems: results[0] as int,
        totalValue: results[1] as double,
        mostWorn: results[2] as List<ClothingItem>,
        leastWorn: results[3] as List<ClothingItem>,
      );

      // Update cache
      _cachedAnalytics = analytics;
      _cacheTimestamp = DateTime.now();

      return analytics;
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) rethrow;
      ErrorLogger.log('Failed to get analytics: $e', context: 'AnalyticsRepository.analytics_query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get analytics: $e',
      operation: 'analytics_query',
        cause: e,
      );
    }
  }

  @override
  Future<void> recordUsage(String outfitId, DateTime date) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        // Get all clothing items in the outfit
        final outfitItems = await txn.query(
          DatabaseConstants.tableOutfitItems,
          columns: [DatabaseConstants.columnClothingItemId],
          where: '${DatabaseConstants.columnOutfitId} = ?',
          whereArgs: [outfitId],
        );

        if (outfitItems.isEmpty) {
          throw db_exceptions.DatabaseException(
            'Outfit with id $outfitId has no items',
            operation: 'record_usage',
          );
        }

        final batch = txn.batch();

        for (final item in outfitItems) {
          final clothingItemId = item[DatabaseConstants.columnClothingItemId] as String;

          // Insert usage history record
          batch.insert(
            DatabaseConstants.tableUsageHistory,
            {
              DatabaseConstants.columnId: '${DateTime.now().millisecondsSinceEpoch}_$clothingItemId',
              DatabaseConstants.columnClothingItemId: clothingItemId,
              DatabaseConstants.columnOutfitId: outfitId,
              DatabaseConstants.columnWornDate: date.millisecondsSinceEpoch,
              DatabaseConstants.columnCreatedAt: DateTime.now().millisecondsSinceEpoch,
            },
          );

          // Increment usage count
          batch.rawUpdate(
            '''
            UPDATE ${DatabaseConstants.tableClothingItems}
            SET ${DatabaseConstants.columnUsageCount} = ${DatabaseConstants.columnUsageCount} + 1
            WHERE ${DatabaseConstants.columnId} = ?
            ''',
            [clothingItemId],
          );
        }

        await batch.commit(noResult: true);
      });

      // Invalidate cache after data changes
      invalidateCache();
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) rethrow;
      ErrorLogger.log('Failed to record usage: $e', context: 'AnalyticsRepository.record_usage', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to record usage: $e',
      operation: 'record_usage',
        cause: e,
      );
    }
  }

  @override
  Future<List<ClothingItem>> getMostWorn(int limit) async {
    final db = await _dbManager.database;

    try {
      // Query clothing items ordered by usage_count descending
      final results = await db.query(
        DatabaseConstants.tableClothingItems,
        orderBy: '${DatabaseConstants.columnUsageCount} DESC',
        limit: limit,
      );

      // Use ClothingRepositoryImpl's _fromMap method by creating a helper
      return results.map((map) => _fromMap(map)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get most worn items: $e', context: 'AnalyticsRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get most worn items: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<ClothingItem>> getLeastWorn(int limit) async {
    final db = await _dbManager.database;

    try {
      // Query clothing items ordered by usage_count ascending
      final results = await db.query(
        DatabaseConstants.tableClothingItems,
        orderBy: '${DatabaseConstants.columnUsageCount} ASC',
        limit: limit,
      );

      return results.map((map) => _fromMap(map)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get least worn items: $e', context: 'AnalyticsRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get least worn items: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<Map<ClothingType, int>> getItemCountByType() async {
    final db = await _dbManager.database;

    try {
      // Use GROUP BY to count items by type
      final results = await db.rawQuery(
        '''
        SELECT ${DatabaseConstants.columnType}, COUNT(*) as count
        FROM ${DatabaseConstants.tableClothingItems}
        GROUP BY ${DatabaseConstants.columnType}
        ''',
      );

      final countByType = <ClothingType, int>{};

      for (final row in results) {
        final typeName = row[DatabaseConstants.columnType] as String;
        final count = row['count'] as int;

        // Convert string type name to ClothingType enum
        try {
          final type = ClothingType.values.firstWhere((e) => e.name == typeName);
          countByType[type] = count;
        } catch (e) {
          // Skip unknown types
          continue;
        }
      }

      return countByType;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get item count by type: $e', context: 'AnalyticsRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get item count by type: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<double> getTotalValue() async {
    final db = await _dbManager.database;

    try {
      // Use SUM to calculate total value
      final results = await db.rawQuery(
        '''
        SELECT SUM(${DatabaseConstants.columnPrice}) as total
        FROM ${DatabaseConstants.tableClothingItems}
        WHERE ${DatabaseConstants.columnPrice} IS NOT NULL
        ''',
      );

      if (results.isEmpty || results.first['total'] == null) {
        return 0.0;
      }

      return (results.first['total'] as num).toDouble();
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get total value: $e', context: 'AnalyticsRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get total value: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  /// Helper method to get total item count
  Future<int> _getTotalItemCount() async {
    final db = await _dbManager.database;

    try {
      final results = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableClothingItems}',
      );

      return Sqflite.firstIntValue(results) ?? 0;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get total item count: $e', context: 'AnalyticsRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get total item count: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  /// Checks if the cached analytics data is still valid.
  ///
  /// Cache is considered valid if:
  /// - Cache exists (_cachedAnalytics is not null)
  /// - Cache timestamp exists
  /// - Cache has not expired (less than _cacheExpiration old)
  bool _isCacheValid() {
    if (_cachedAnalytics == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);

    return cacheAge < _cacheExpiration;
  }

  /// Invalidates the analytics cache.
  ///
  /// This should be called whenever data changes that would affect
  /// analytics results, such as:
  /// - Adding, updating, or deleting clothing items
  /// - Adding, updating, or deleting outfits
  /// - Recording usage history
  @override
  void invalidateCache() {
    _cachedAnalytics = null;
    _cacheTimestamp = null;
  }

  /// Converts a database map to a ClothingItem domain model.
  ///
  /// This method handles:
  /// - Converting string names back to enums
  /// - Deserializing JSON to lists
  /// - Converting milliseconds since epoch to DateTime
  ///
  /// Note: This duplicates logic from ClothingRepositoryImpl._fromMap
  /// to avoid tight coupling between repositories.
  ClothingItem _fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map[DatabaseConstants.columnId] as String,
      imageUrl: map[DatabaseConstants.columnImagePath] as String,
      type: ClothingType.values.firstWhere(
        (e) => e.name == map[DatabaseConstants.columnType],
        orElse: () => ClothingType.tops,
      ),
      color: map[DatabaseConstants.columnColor] as String,
      seasons: (jsonDecode(map[DatabaseConstants.columnSeasons]) as List<dynamic>)
          .map((s) => Season.values.firstWhere(
            (e) => e.name == s,
            orElse: () => Season.spring,
          ))
          .toList(),
      price: map[DatabaseConstants.columnPrice] as double?,
      usageCount: map[DatabaseConstants.columnUsageCount] as int,
      isFavorite: (map[DatabaseConstants.columnIsFavorite] as int?) == 1,
      addedDate: DateTime.fromMillisecondsSinceEpoch(
          map[DatabaseConstants.columnCreatedAt] as int),
    );
  }
}
