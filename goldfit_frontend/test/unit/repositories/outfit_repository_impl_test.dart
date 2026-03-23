import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v1.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseManager dbManager;
  late OutfitRepositoryImpl outfitRepository;
  late ClothingRepositoryImpl clothingRepository;

  setUp(() async {
    // Create in-memory database for testing
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await MigrationV1().migrate(db);
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    // Create mock database manager
    dbManager = DatabaseManager.forTesting(db);
    final analyticsRepository = AnalyticsRepositoryImpl(dbManager);
    outfitRepository = OutfitRepositoryImpl(dbManager, analyticsRepository);
    clothingRepository = ClothingRepositoryImpl(dbManager, analyticsRepository);
  });

  tearDown(() async {
    await db.close();
  });

  group('Usage Tracking', () {
    test('recordUsage creates usage_history records for all items in outfit',
        () async {
      // Create test clothing items
      final item1 = ClothingItem(
        id: 'item1',
        imageUrl: '/path/to/image1.jpg',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      final item2 = ClothingItem(
        id: 'item2',
        imageUrl: '/path/to/image2.jpg',
        type: ClothingType.bottoms,
        color: 'Black',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      await clothingRepository.create(item1);
      await clothingRepository.create(item2);

      // Create test outfit
      final outfit = Outfit(
        id: 'outfit1',
        name: 'Test Outfit',
        itemIds: ['item1', 'item2'],
        createdDate: DateTime.now(),
      );

      await outfitRepository.create(outfit);

      // Record usage
      final wornDate = DateTime(2024, 1, 15);
      await outfitRepository.recordUsage('outfit1', wornDate);

      // Verify usage_history records were created
      final usageRecords = await db.query(
        DatabaseConstants.tableUsageHistory,
        where: '${DatabaseConstants.columnOutfitId} = ?',
        whereArgs: ['outfit1'],
      );

      expect(usageRecords.length, equals(2));
      expect(
        usageRecords.any((r) =>
            r[DatabaseConstants.columnClothingItemId] == 'item1' &&
            r[DatabaseConstants.columnWornDate] ==
                wornDate.millisecondsSinceEpoch),
        isTrue,
      );
      expect(
        usageRecords.any((r) =>
            r[DatabaseConstants.columnClothingItemId] == 'item2' &&
            r[DatabaseConstants.columnWornDate] ==
                wornDate.millisecondsSinceEpoch),
        isTrue,
      );
    });

    test('recordUsage increments usage_count for all items in outfit',
        () async {
      // Create test clothing items
      final item1 = ClothingItem(
        id: 'item1',
        imageUrl: '/path/to/image1.jpg',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      final item2 = ClothingItem(
        id: 'item2',
        imageUrl: '/path/to/image2.jpg',
        type: ClothingType.bottoms,
        color: 'Black',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      await clothingRepository.create(item1);
      await clothingRepository.create(item2);

      // Create test outfit
      final outfit = Outfit(
        id: 'outfit1',
        name: 'Test Outfit',
        itemIds: ['item1', 'item2'],
        createdDate: DateTime.now(),
      );

      await outfitRepository.create(outfit);

      // Record usage
      final wornDate = DateTime(2024, 1, 15);
      await outfitRepository.recordUsage('outfit1', wornDate);

      // Verify usage_count was incremented
      final item1Record = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: ['item1'],
      );

      final item2Record = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: ['item2'],
      );

      expect(item1Record.first[DatabaseConstants.columnUsageCount], equals(1));
      expect(item2Record.first[DatabaseConstants.columnUsageCount], equals(1));
    });

    test('assignToDate records usage for past dates', () async {
      // Create test clothing items
      final item1 = ClothingItem(
        id: 'item1',
        imageUrl: '/path/to/image1.jpg',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      await clothingRepository.create(item1);

      // Create test outfit
      final outfit = Outfit(
        id: 'outfit1',
        name: 'Test Outfit',
        itemIds: ['item1'],
        createdDate: DateTime.now(),
      );

      await outfitRepository.create(outfit);

      // Assign to past date
      final pastDate = DateTime.now().subtract(const Duration(days: 7));
      await outfitRepository.assignToDate('outfit1', pastDate, 'morning');

      // Verify usage_history record was created
      final usageRecords = await db.query(
        DatabaseConstants.tableUsageHistory,
        where: '${DatabaseConstants.columnOutfitId} = ?',
        whereArgs: ['outfit1'],
      );

      expect(usageRecords.length, equals(1));
      expect(usageRecords.first[DatabaseConstants.columnClothingItemId],
          equals('item1'));

      // Verify usage_count was incremented
      final itemRecord = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: ['item1'],
      );

      expect(itemRecord.first[DatabaseConstants.columnUsageCount], equals(1));
    });

    test('assignToDate does not record usage for future dates', () async {
      // Create test clothing items
      final item1 = ClothingItem(
        id: 'item1',
        imageUrl: '/path/to/image1.jpg',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      await clothingRepository.create(item1);

      // Create test outfit
      final outfit = Outfit(
        id: 'outfit1',
        name: 'Test Outfit',
        itemIds: ['item1'],
        createdDate: DateTime.now(),
      );

      await outfitRepository.create(outfit);

      // Assign to future date
      final futureDate = DateTime.now().add(const Duration(days: 7));
      await outfitRepository.assignToDate('outfit1', futureDate, 'morning');

      // Verify no usage_history record was created
      final usageRecords = await db.query(
        DatabaseConstants.tableUsageHistory,
        where: '${DatabaseConstants.columnOutfitId} = ?',
        whereArgs: ['outfit1'],
      );

      expect(usageRecords.length, equals(0));

      // Verify usage_count was not incremented
      final itemRecord = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: ['item1'],
      );

      expect(itemRecord.first[DatabaseConstants.columnUsageCount], equals(0));
    });

    test('assignToDate does not record usage for today', () async {
      // Create test clothing items
      final item1 = ClothingItem(
        id: 'item1',
        imageUrl: '/path/to/image1.jpg',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      await clothingRepository.create(item1);

      // Create test outfit
      final outfit = Outfit(
        id: 'outfit1',
        name: 'Test Outfit',
        itemIds: ['item1'],
        createdDate: DateTime.now(),
      );

      await outfitRepository.create(outfit);

      // Assign to today
      final today = DateTime.now();
      await outfitRepository.assignToDate('outfit1', today, 'morning');

      // Verify no usage_history record was created
      final usageRecords = await db.query(
        DatabaseConstants.tableUsageHistory,
        where: '${DatabaseConstants.columnOutfitId} = ?',
        whereArgs: ['outfit1'],
      );

      expect(usageRecords.length, equals(0));

      // Verify usage_count was not incremented
      final itemRecord = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: ['item1'],
      );

      expect(itemRecord.first[DatabaseConstants.columnUsageCount], equals(0));
    });

    test('recordUsage handles multiple usage records for same item', () async {
      // Create test clothing item
      final item1 = ClothingItem(
        id: 'item1',
        imageUrl: '/path/to/image1.jpg',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      );

      await clothingRepository.create(item1);

      // Create test outfit
      final outfit = Outfit(
        id: 'outfit1',
        name: 'Test Outfit',
        itemIds: ['item1'],
        createdDate: DateTime.now(),
      );

      await outfitRepository.create(outfit);

      // Record usage multiple times
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 1, 20);
      final date3 = DateTime(2024, 1, 25);

      await outfitRepository.recordUsage('outfit1', date1);
      await outfitRepository.recordUsage('outfit1', date2);
      await outfitRepository.recordUsage('outfit1', date3);

      // Verify all usage_history records were created
      final usageRecords = await db.query(
        DatabaseConstants.tableUsageHistory,
        where: '${DatabaseConstants.columnClothingItemId} = ?',
        whereArgs: ['item1'],
      );

      expect(usageRecords.length, equals(3));

      // Verify usage_count was incremented correctly
      final itemRecord = await db.query(
        DatabaseConstants.tableClothingItems,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: ['item1'],
      );

      expect(itemRecord.first[DatabaseConstants.columnUsageCount], equals(3));
    });
  });
}
