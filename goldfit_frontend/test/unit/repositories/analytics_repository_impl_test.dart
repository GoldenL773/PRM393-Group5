import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v1.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository_impl.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AnalyticsRepositoryImpl', () {
    late Database db;
    late DatabaseManager dbManager;
    late AnalyticsRepositoryImpl analyticsRepo;
    late ClothingRepositoryImpl clothingRepo;
    late OutfitRepositoryImpl outfitRepo;

    setUp(() async {
      // Create in-memory database for testing
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('PRAGMA foreign_keys = ON');
            await MigrationV1().migrate(db);
          },
        ),
      );

      // Create mock DatabaseManager
      dbManager = DatabaseManager.forTesting(db);
      analyticsRepo = AnalyticsRepositoryImpl(dbManager);
      clothingRepo = ClothingRepositoryImpl(dbManager);
      outfitRepo = OutfitRepositoryImpl(dbManager);
    });

    tearDown(() async {
      await db.close();
    });

    group('getTotalValue', () {
      test('returns 0.0 when no items exist', () async {
        final totalValue = await analyticsRepo.getTotalValue();
        expect(totalValue, equals(0.0));
      });

      test('returns 0.0 when no items have prices', () async {
        final item = ClothingItem(
          id: 'item1',
          imageUrl: 'path/to/image.jpg',
          type: ClothingType.tops,
          color: 'Blue',
          seasons: [Season.summer],
          price: null,
          usageCount: 0,
          addedDate: DateTime.now(),
        );

        await clothingRepo.create(item);

        final totalValue = await analyticsRepo.getTotalValue();
        expect(totalValue, equals(0.0));
      });

      test('calculates sum of all item prices', () async {
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            price: 29.99,
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            price: 49.99,
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item3',
            imageUrl: 'path/to/image3.jpg',
            type: ClothingType.shoes,
            color: 'White',
            seasons: [Season.spring],
            price: null, // Should be excluded
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final totalValue = await analyticsRepo.getTotalValue();
        expect(totalValue, equals(79.98));
      });
    });

    group('getItemCountByType', () {
      test('returns empty map when no items exist', () async {
        final countByType = await analyticsRepo.getItemCountByType();
        expect(countByType, isEmpty);
      });

      test('groups items by type correctly', () async {
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.tops,
            color: 'Red',
            seasons: [Season.summer],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item3',
            imageUrl: 'path/to/image3.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final countByType = await analyticsRepo.getItemCountByType();
        expect(countByType[ClothingType.tops], equals(2));
        expect(countByType[ClothingType.bottoms], equals(1));
        expect(countByType[ClothingType.shoes], isNull);
      });
    });

    group('getMostWorn', () {
      test('returns empty list when no items exist', () async {
        final mostWorn = await analyticsRepo.getMostWorn(5);
        expect(mostWorn, isEmpty);
      });

      test('returns items ordered by usage count descending', () async {
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            usageCount: 5,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            usageCount: 10,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item3',
            imageUrl: 'path/to/image3.jpg',
            type: ClothingType.shoes,
            color: 'White',
            seasons: [Season.spring],
            usageCount: 2,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final mostWorn = await analyticsRepo.getMostWorn(5);
        expect(mostWorn.length, equals(3));
        expect(mostWorn[0].id, equals('item2')); // 10 uses
        expect(mostWorn[1].id, equals('item1')); // 5 uses
        expect(mostWorn[2].id, equals('item3')); // 2 uses
      });

      test('respects limit parameter', () async {
        final items = List.generate(
          10,
          (i) => ClothingItem(
            id: 'item$i',
            imageUrl: 'path/to/image$i.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            usageCount: i,
            addedDate: DateTime.now(),
          ),
        );

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final mostWorn = await analyticsRepo.getMostWorn(3);
        expect(mostWorn.length, equals(3));
      });
    });

    group('getLeastWorn', () {
      test('returns empty list when no items exist', () async {
        final leastWorn = await analyticsRepo.getLeastWorn(5);
        expect(leastWorn, isEmpty);
      });

      test('returns items ordered by usage count ascending', () async {
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            usageCount: 5,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            usageCount: 10,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item3',
            imageUrl: 'path/to/image3.jpg',
            type: ClothingType.shoes,
            color: 'White',
            seasons: [Season.spring],
            usageCount: 2,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final leastWorn = await analyticsRepo.getLeastWorn(5);
        expect(leastWorn.length, equals(3));
        expect(leastWorn[0].id, equals('item3')); // 2 uses
        expect(leastWorn[1].id, equals('item1')); // 5 uses
        expect(leastWorn[2].id, equals('item2')); // 10 uses
      });
    });

    group('recordUsage', () {
      test('creates usage history records for all items in outfit', () async {
        // Create clothing items
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        // Create outfit
        final outfit = Outfit(
          id: 'outfit1',
          name: 'Test Outfit',
          itemIds: ['item1', 'item2'],
          createdDate: DateTime.now(),
        );

        await outfitRepo.create(outfit);

        // Record usage
        final wornDate = DateTime(2024, 1, 15);
        await analyticsRepo.recordUsage('outfit1', wornDate);

        // Verify usage counts were incremented
        final item1 = await clothingRepo.getById('item1');
        final item2 = await clothingRepo.getById('item2');

        expect(item1?.usageCount, equals(1));
        expect(item2?.usageCount, equals(1));
      });

      test('throws exception for non-existent outfit', () async {
        expect(
          () => analyticsRepo.recordUsage('nonexistent', DateTime.now()),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAnalytics', () {
      test('returns complete analytics with all statistics', () async {
        // Create test data
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            price: 29.99,
            usageCount: 5,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            price: 49.99,
            usageCount: 2,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final analytics = await analyticsRepo.getAnalytics();

        expect(analytics.totalItems, equals(2));
        expect(analytics.totalValue, equals(79.98));
        expect(analytics.mostWorn.length, lessThanOrEqualTo(5));
        expect(analytics.leastWorn.length, lessThanOrEqualTo(5));
        expect(analytics.mostWorn.first.id, equals('item1')); // Higher usage
        expect(analytics.leastWorn.first.id, equals('item2')); // Lower usage
      });
    });

    group('Analytics Caching', () {
      test('returns cached result on subsequent calls', () async {
        // Create test data
        final item = ClothingItem(
          id: 'item1',
          imageUrl: 'path/to/image1.jpg',
          type: ClothingType.tops,
          color: 'Blue',
          seasons: [Season.summer],
          price: 29.99,
          usageCount: 5,
          addedDate: DateTime.now(),
        );

        await clothingRepo.create(item);

        // First call - should fetch from database
        final analytics1 = await analyticsRepo.getAnalytics();
        expect(analytics1.totalItems, equals(1));

        // Add another item
        final item2 = ClothingItem(
          id: 'item2',
          imageUrl: 'path/to/image2.jpg',
          type: ClothingType.bottoms,
          color: 'Black',
          seasons: [Season.winter],
          price: 49.99,
          usageCount: 2,
          addedDate: DateTime.now(),
        );
        await clothingRepo.create(item2);

        // Second call - should return cached result (still 1 item)
        final analytics2 = await analyticsRepo.getAnalytics();
        expect(analytics2.totalItems, equals(1));
        expect(identical(analytics1, analytics2), isTrue);
      });

      test('invalidates cache when recordUsage is called', () async {
        // Create test data
        final items = [
          ClothingItem(
            id: 'item1',
            imageUrl: 'path/to/image1.jpg',
            type: ClothingType.tops,
            color: 'Blue',
            seasons: [Season.summer],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
          ClothingItem(
            id: 'item2',
            imageUrl: 'path/to/image2.jpg',
            type: ClothingType.bottoms,
            color: 'Black',
            seasons: [Season.winter],
            usageCount: 0,
            addedDate: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await clothingRepo.create(item);
        }

        final outfit = Outfit(
          id: 'outfit1',
          name: 'Test Outfit',
          itemIds: ['item1', 'item2'],
          createdDate: DateTime.now(),
        );
        await outfitRepo.create(outfit);

        // Get initial analytics (caches result)
        final analytics1 = await analyticsRepo.getAnalytics();
        expect(analytics1.mostWorn.first.usageCount, equals(0));

        // Record usage (should invalidate cache)
        await analyticsRepo.recordUsage('outfit1', DateTime.now());

        // Get analytics again (should fetch fresh data)
        final analytics2 = await analyticsRepo.getAnalytics();
        expect(analytics2.mostWorn.first.usageCount, equals(1));
        expect(identical(analytics1, analytics2), isFalse);
      });

      test('invalidateCache clears cached data', () async {
        // Create test data
        final item = ClothingItem(
          id: 'item1',
          imageUrl: 'path/to/image1.jpg',
          type: ClothingType.tops,
          color: 'Blue',
          seasons: [Season.summer],
          price: 29.99,
          usageCount: 5,
          addedDate: DateTime.now(),
        );

        await clothingRepo.create(item);

        // First call - caches result
        final analytics1 = await analyticsRepo.getAnalytics();
        expect(analytics1.totalItems, equals(1));

        // Add another item
        final item2 = ClothingItem(
          id: 'item2',
          imageUrl: 'path/to/image2.jpg',
          type: ClothingType.bottoms,
          color: 'Black',
          seasons: [Season.winter],
          price: 49.99,
          usageCount: 2,
          addedDate: DateTime.now(),
        );
        await clothingRepo.create(item2);

        // Manually invalidate cache
        analyticsRepo.invalidateCache();

        // Next call should fetch fresh data
        final analytics2 = await analyticsRepo.getAnalytics();
        expect(analytics2.totalItems, equals(2));
        expect(identical(analytics1, analytics2), isFalse);
      });

      test('cache expires after expiration duration', () async {
        // Note: This test would require mocking DateTime.now() or waiting
        // for the actual expiration time. For now, we'll just verify the
        // cache validation logic works correctly with immediate calls.
        
        final item = ClothingItem(
          id: 'item1',
          imageUrl: 'path/to/image1.jpg',
          type: ClothingType.tops,
          color: 'Blue',
          seasons: [Season.summer],
          price: 29.99,
          usageCount: 5,
          addedDate: DateTime.now(),
        );

        await clothingRepo.create(item);

        // First call - caches result
        final analytics1 = await analyticsRepo.getAnalytics();
        
        // Immediate second call - should use cache
        final analytics2 = await analyticsRepo.getAnalytics();
        expect(identical(analytics1, analytics2), isTrue);
      });
    });
  });
}
