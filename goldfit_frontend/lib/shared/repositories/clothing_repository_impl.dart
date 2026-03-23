import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/database_exceptions.dart' as db_exceptions;
import 'package:goldfit_frontend/shared/utils/error_logger.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';

/// Concrete implementation of ClothingRepository using SQLite.
///
/// This class handles all database operations for clothing items including:
/// - CRUD operations (create, read, update, delete)
/// - Filtering and querying
/// - Batch operations
/// - Data transformation between domain models and database records
class ClothingRepositoryImpl implements ClothingRepository {
  final DatabaseManager _dbManager;
  final AnalyticsRepository _analyticsRepo;

  ClothingRepositoryImpl(this._dbManager, this._analyticsRepo) {
    debugPrint('DEBUG: ClothingRepositoryImpl initialized. _analyticsRepo is ${_analyticsRepo.runtimeType}');
  }

  @override
  Future<ClothingItem> create(ClothingItem item) async {
    final db = await _dbManager.database;

    try {
      await db.insert(
        DatabaseConstants.tableClothingItems,
        _toMap(item),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('DEBUG: Calling _analyticsRepo.invalidateCache()...');
      _analyticsRepo.invalidateCache();
      debugPrint('DEBUG: Called _analyticsRepo.invalidateCache() successfully.');
      
      return item;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to create clothing item: $e', context: 'ClothingRepository.insert', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to create clothing item: $e',
      operation: 'insert',
        cause: e,
      );
    }
  }

  @override
  Future<ClothingItem?> getById(String id) async {
    final db = await _dbManager.database;

    try {
      final results = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;
      return _fromMap(results.first);
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get clothing item by id: $e', context: 'ClothingRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get clothing item by id: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<ClothingItem>> getAll() async {
    final db = await _dbManager.database;

    try {
      final results = await db.query(
        DatabaseConstants.tableClothingItems,
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      return results.map(_fromMap).toList();
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get all clothing items: $e', context: 'ClothingRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get all clothing items: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<ClothingItem>> getByType(ClothingType type) async {
    final db = await _dbManager.database;

    try {
      final results = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnType} = ?',
        whereArgs: [type.toString().split('.').last],
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      return results.map(_fromMap).toList();
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get clothing items by type: $e', context: 'ClothingRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get clothing items by type: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<ClothingItem>> getByFilters(FilterState filters) async {
    final db = await _dbManager.database;

    try {
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      // Filter by colors if specified
      if (filters.colors.isNotEmpty) {
        final placeholders = filters.colors.map((_) => '?').join(',');
        whereConditions.add('${DatabaseConstants.columnColor} IN ($placeholders)');
        whereArgs.addAll(filters.colors);
      }

      // Filter by seasons if specified
      // JSON array contains check for seasons
      if (filters.seasons.isNotEmpty) {
        for (final season in filters.seasons) {
          whereConditions.add('${DatabaseConstants.columnSeasons} LIKE ?');
          whereArgs.add('%"${season.toString().split('.').last}"%');
        }
      }

      final results = await db.query(
        DatabaseConstants.tableClothingItems,
        where: whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      return results.map(_fromMap).toList();
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to get clothing items by filters: $e', context: 'ClothingRepository.query', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to get clothing items by filters: $e',
      operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<ClothingItem> update(ClothingItem item) async {
    final db = await _dbManager.database;

    try {
      final rowsAffected = await db.update(
        DatabaseConstants.tableClothingItems,
        _toMap(item),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [item.id],
      );

      if (rowsAffected == 0) {
        throw db_exceptions.DatabaseException(
          'Clothing item with id ${item.id} not found',
          operation: 'update',
        );
      }

      debugPrint('DEBUG: Calling _analyticsRepo.invalidateCache() in update...');
      _analyticsRepo.invalidateCache();
      return item;
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) rethrow;
      ErrorLogger.log('Failed to update clothing item: $e', context: 'ClothingRepository.update', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to update clothing item: $e',
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
        // Delete from clothing_tags junction table (cascade)
        await txn.delete(
          DatabaseConstants.tableClothingTags,
          where: '${DatabaseConstants.columnClothingItemId} = ?',
          whereArgs: [id],
        );

        // Delete from outfit_items junction table (cascade)
        await txn.delete(
          DatabaseConstants.tableOutfitItems,
          where: '${DatabaseConstants.columnClothingItemId} = ?',
          whereArgs: [id],
        );

        // Delete the clothing item
        final rowsAffected = await txn.delete(
          DatabaseConstants.tableClothingItems,
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [id],
        );

        if (rowsAffected == 0) {
          throw db_exceptions.DatabaseException(
            'Clothing item with id $id not found',
            operation: 'delete',
          );
        }
      });
      debugPrint('DEBUG: Calling _analyticsRepo.invalidateCache() in delete...');
      _analyticsRepo.invalidateCache();
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) rethrow;
      ErrorLogger.log('Failed to delete clothing item: $e', context: 'ClothingRepository.delete', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to delete clothing item: $e',
      operation: 'delete',
        cause: e,
      );
    }
  }

  @override
  Future<List<ClothingItem>> batchCreate(List<ClothingItem> items) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final item in items) {
          batch.insert(
            DatabaseConstants.tableClothingItems,
            _toMap(item),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      debugPrint('DEBUG: Calling _analyticsRepo.invalidateCache() in batchCreate...');
      _analyticsRepo.invalidateCache();
      return items;
    } catch (e, stackTrace) {
      ErrorLogger.log('Failed to batch create clothing items: $e', context: 'ClothingRepository.batch_insert', error: e, stackTrace: stackTrace);
      throw db_exceptions.DatabaseException(
      'Failed to batch create clothing items: $e',
      operation: 'batch_insert',
        cause: e,
      );
    }
  }

  @override
  Stream<List<ClothingItem>> watchAll() async* {
    yield await getAll();
  }

  /// Converts a ClothingItem domain model to a database map.
  Map<String, dynamic> _toMap(ClothingItem item) {
    return {
      DatabaseConstants.columnId: item.id,
      DatabaseConstants.columnImagePath: item.imageUrl,
      DatabaseConstants.columnCleanedImagePath: item.cleanedImageUrl,
      DatabaseConstants.columnType: item.type.toString().split('.').last,
      DatabaseConstants.columnColor: item.color,
      DatabaseConstants.columnSeasons:
          jsonEncode(item.seasons.map((s) => s.toString().split('.').last).toList()),
      DatabaseConstants.columnPrice: item.price,
      DatabaseConstants.columnUsageCount: item.usageCount,
      DatabaseConstants.columnIsFavorite: item.isFavorite ? 1 : 0,
      DatabaseConstants.columnAiTags: null,
      DatabaseConstants.columnCreatedAt: item.addedDate.millisecondsSinceEpoch,
      DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Converts a database map to a ClothingItem domain model.
  ClothingItem _fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map[DatabaseConstants.columnId] as String,
      imageUrl: map[DatabaseConstants.columnImagePath] as String,
      cleanedImageUrl: map[DatabaseConstants.columnCleanedImagePath] as String?,
      type: ClothingType.values.firstWhere(
        (e) => e.toString().split('.').last == map[DatabaseConstants.columnType],
        orElse: () => ClothingType.tops,
      ),
      color: map[DatabaseConstants.columnColor] as String,
      seasons: (jsonDecode(map[DatabaseConstants.columnSeasons] as String) as List<dynamic>)
          .map((s) => Season.values.firstWhere(
                (e) => e.toString().split('.').last == s,
                orElse: () => Season.summer,
              ))
          .toList(),
      price: map[DatabaseConstants.columnPrice] as double?,
      usageCount: map[DatabaseConstants.columnUsageCount] as int,
      addedDate: DateTime.fromMillisecondsSinceEpoch(
          map[DatabaseConstants.columnCreatedAt] as int),
      isFavorite: (map[DatabaseConstants.columnIsFavorite] as int?) == 1,
    );
  }
}
