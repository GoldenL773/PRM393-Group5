import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/database_exceptions.dart'
    as db_exceptions;
import 'package:goldfit_frontend/shared/models/wardrobe_collection.dart';
import 'package:goldfit_frontend/shared/utils/error_logger.dart';
import 'package:goldfit_frontend/shared/repositories/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final DatabaseManager _dbManager;

  CollectionRepositoryImpl(this._dbManager);

  @override
  Future<WardrobeCollection> create(WardrobeCollection collection) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseConstants.tableCollections,
          _toMap(collection),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final itemId in collection.itemIds) {
          await txn.insert(
            DatabaseConstants.tableCollectionItems,
            {
              DatabaseConstants.columnCollectionId: collection.id,
              DatabaseConstants.columnClothingItemId: itemId,
              DatabaseConstants.columnCreatedAt:
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return collection;
    } catch (e, stackTrace) {
      debugPrint('SQL ERROR creating collection: $e');
      await ErrorLogger.log(
        'Failed to create collection: $e',
        context: 'CollectionRepository.insert',
        error: e,
        stackTrace: stackTrace,
      );
      throw db_exceptions.DatabaseException(
        'Failed to create collection: $e',
        operation: 'insert',
        cause: e,
      );
    }
  }

  @override
  Future<WardrobeCollection?> getById(String id) async {
    final db = await _dbManager.database;

    try {
      final collectionRows = await db.query(
        DatabaseConstants.tableCollections,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );

      if (collectionRows.isEmpty) {
        return null;
      }

      final itemRows = await db.query(
        DatabaseConstants.tableCollectionItems,
        where: '${DatabaseConstants.columnCollectionId} = ?',
        whereArgs: [id],
      );

      final itemIds = itemRows
          .map((row) => row[DatabaseConstants.columnClothingItemId] as String)
          .toList();

      return _fromMap(collectionRows.first, itemIds);
    } catch (e, stackTrace) {
      ErrorLogger.log(
        'Failed to get collection by id: $e',
        context: 'CollectionRepository.query',
        error: e,
        stackTrace: stackTrace,
      );
      throw db_exceptions.DatabaseException(
        'Failed to get collection by id: $e',
        operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<List<WardrobeCollection>> getAll() async {
    final db = await _dbManager.database;

    try {
      final collectionRows = await db.query(
        DatabaseConstants.tableCollections,
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      final collections = <WardrobeCollection>[];
      for (final row in collectionRows) {
        final id = row[DatabaseConstants.columnId] as String;
        final itemRows = await db.query(
          DatabaseConstants.tableCollectionItems,
          where: '${DatabaseConstants.columnCollectionId} = ?',
          whereArgs: [id],
        );

        final itemIds = itemRows
            .map(
              (itemRow) =>
                  itemRow[DatabaseConstants.columnClothingItemId] as String,
            )
            .toList();
        collections.add(_fromMap(row, itemIds));
      }

      return collections;
    } catch (e, stackTrace) {
      ErrorLogger.log(
        'Failed to get collections: $e',
        context: 'CollectionRepository.query',
        error: e,
        stackTrace: stackTrace,
      );
      throw db_exceptions.DatabaseException(
        'Failed to get collections: $e',
        operation: 'query',
        cause: e,
      );
    }
  }

  @override
  Future<WardrobeCollection> update(WardrobeCollection collection) async {
    final db = await _dbManager.database;

    try {
      await db.transaction((txn) async {
        final rows = await txn.update(
          DatabaseConstants.tableCollections,
          _toMap(collection),
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [collection.id],
        );

        if (rows == 0) {
          throw db_exceptions.DatabaseException(
            'Collection with id ${collection.id} not found',
            operation: 'update',
          );
        }

        await txn.delete(
          DatabaseConstants.tableCollectionItems,
          where: '${DatabaseConstants.columnCollectionId} = ?',
          whereArgs: [collection.id],
        );

        for (final itemId in collection.itemIds) {
          await txn.insert(
            DatabaseConstants.tableCollectionItems,
            {
              DatabaseConstants.columnCollectionId: collection.id,
              DatabaseConstants.columnClothingItemId: itemId,
              DatabaseConstants.columnCreatedAt:
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return collection;
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) {
        rethrow;
      }
      ErrorLogger.log(
        'Failed to update collection: $e',
        context: 'CollectionRepository.update',
        error: e,
        stackTrace: stackTrace,
      );
      throw db_exceptions.DatabaseException(
        'Failed to update collection: $e',
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
        await txn.delete(
          DatabaseConstants.tableCollectionItems,
          where: '${DatabaseConstants.columnCollectionId} = ?',
          whereArgs: [id],
        );

        final rows = await txn.delete(
          DatabaseConstants.tableCollections,
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [id],
        );

        if (rows == 0) {
          throw db_exceptions.DatabaseException(
            'Collection with id $id not found',
            operation: 'delete',
          );
        }
      });
    } catch (e, stackTrace) {
      if (e is db_exceptions.DatabaseException) {
        rethrow;
      }
      ErrorLogger.log(
        'Failed to delete collection: $e',
        context: 'CollectionRepository.delete',
        error: e,
        stackTrace: stackTrace,
      );
      throw db_exceptions.DatabaseException(
        'Failed to delete collection: $e',
        operation: 'delete',
        cause: e,
      );
    }
  }

  Map<String, dynamic> _toMap(WardrobeCollection collection) {
    return {
      DatabaseConstants.columnId: collection.id,
      DatabaseConstants.columnName: collection.name,
      DatabaseConstants.columnCreatedAt:
          collection.createdAt.millisecondsSinceEpoch,
      DatabaseConstants.columnUpdatedAt:
          collection.updatedAt.millisecondsSinceEpoch,
    };
  }

  WardrobeCollection _fromMap(Map<String, dynamic> map, List<String> itemIds) {
    return WardrobeCollection(
      id: map[DatabaseConstants.columnId] as String,
      name: map[DatabaseConstants.columnName] as String,
      itemIds: itemIds,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.columnCreatedAt] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.columnUpdatedAt] as int,
      ),
    );
  }
}
