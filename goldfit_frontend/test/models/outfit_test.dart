import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/models/outfit.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';

void main() {
  group('Outfit', () {
    test('creates instance with all required properties', () {
      final createdDate = DateTime.now();
      final assignedDate = DateTime.now().add(Duration(days: 1));
      final outfit = Outfit(
        id: 'test-outfit-id',
        name: 'Summer Casual',
        itemIds: ['item1', 'item2', 'item3'],
        assignedDate: assignedDate,
        vibe: 'Casual',
        createdDate: createdDate,
      );

      expect(outfit.id, 'test-outfit-id');
      expect(outfit.name, 'Summer Casual');
      expect(outfit.itemIds, ['item1', 'item2', 'item3']);
      expect(outfit.assignedDate, assignedDate);
      expect(outfit.vibe, 'Casual');
      expect(outfit.createdDate, createdDate);
    });

    test('creates instance with optional fields as null', () {
      final createdDate = DateTime.now();
      final outfit = Outfit(
        id: 'test-outfit-id',
        name: 'Basic Outfit',
        itemIds: ['item1'],
        createdDate: createdDate,
      );

      expect(outfit.assignedDate, null);
      expect(outfit.vibe, null);
    });

    test('getItems resolves item IDs to ClothingItem objects', () {
      final outfit = Outfit(
        id: 'test-outfit',
        name: 'Test Outfit',
        itemIds: ['item1', 'item2', 'item3'],
        createdDate: DateTime.now(),
      );

      final mockItems = {
        'item1': ClothingItem(
          id: 'item1',
          imageUrl: 'assets/item1.png',
          type: ClothingType.tops,
          color: 'blue',
          seasons: [Season.summer],
          addedDate: DateTime.now(),
        ),
        'item2': ClothingItem(
          id: 'item2',
          imageUrl: 'assets/item2.png',
          type: ClothingType.bottoms,
          color: 'black',
          seasons: [Season.summer],
          addedDate: DateTime.now(),
        ),
        'item3': ClothingItem(
          id: 'item3',
          imageUrl: 'assets/item3.png',
          type: ClothingType.shoes,
          color: 'white',
          seasons: [Season.summer],
          addedDate: DateTime.now(),
        ),
      };

      final items = outfit.getItems((id) => mockItems[id]);

      expect(items.length, 3);
      expect(items[0].id, 'item1');
      expect(items[1].id, 'item2');
      expect(items[2].id, 'item3');
    });

    test('getItems excludes items that cannot be found', () {
      final outfit = Outfit(
        id: 'test-outfit',
        name: 'Test Outfit',
        itemIds: ['item1', 'missing-item', 'item2'],
        createdDate: DateTime.now(),
      );

      final mockItems = {
        'item1': ClothingItem(
          id: 'item1',
          imageUrl: 'assets/item1.png',
          type: ClothingType.tops,
          color: 'blue',
          seasons: [Season.summer],
          addedDate: DateTime.now(),
        ),
        'item2': ClothingItem(
          id: 'item2',
          imageUrl: 'assets/item2.png',
          type: ClothingType.bottoms,
          color: 'black',
          seasons: [Season.summer],
          addedDate: DateTime.now(),
        ),
      };

      final items = outfit.getItems((id) => mockItems[id]);

      expect(items.length, 2);
      expect(items[0].id, 'item1');
      expect(items[1].id, 'item2');
    });

    test('getItems returns empty list when no items can be found', () {
      final outfit = Outfit(
        id: 'test-outfit',
        name: 'Test Outfit',
        itemIds: ['missing1', 'missing2'],
        createdDate: DateTime.now(),
      );

      final items = outfit.getItems((id) => null);

      expect(items, isEmpty);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Outfit(
        id: 'test-outfit',
        name: 'Original Name',
        itemIds: ['item1', 'item2'],
        assignedDate: DateTime.now(),
        vibe: 'Casual',
        createdDate: DateTime.now(),
      );

      final newDate = DateTime.now().add(Duration(days: 7));
      final updated = original.copyWith(
        name: 'Updated Name',
        vibe: 'Work',
        assignedDate: newDate,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated Name');
      expect(updated.itemIds, original.itemIds);
      expect(updated.assignedDate, newDate);
      expect(updated.vibe, 'Work');
      expect(updated.createdDate, original.createdDate);
    });

    test('copyWith preserves original fields when not specified', () {
      final original = Outfit(
        id: 'test-outfit',
        name: 'Original Name',
        itemIds: ['item1', 'item2'],
        assignedDate: DateTime.now(),
        vibe: 'Casual',
        createdDate: DateTime.now(),
      );

      final updated = original.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.itemIds, original.itemIds);
      expect(updated.assignedDate, original.assignedDate);
      expect(updated.vibe, original.vibe);
    });

    test('toJson serializes all fields correctly', () {
      final createdDate = DateTime.now();
      final assignedDate = DateTime.now().add(Duration(days: 1));
      final outfit = Outfit(
        id: 'test-outfit-id',
        name: 'Work Outfit',
        itemIds: ['item1', 'item2', 'item3'],
        assignedDate: assignedDate,
        vibe: 'Work',
        createdDate: createdDate,
      );

      final json = outfit.toJson();

      expect(json['id'], 'test-outfit-id');
      expect(json['name'], 'Work Outfit');
      expect(json['itemIds'], ['item1', 'item2', 'item3']);
      expect(json['assignedDate'], assignedDate.toIso8601String());
      expect(json['vibe'], 'Work');
      expect(json['createdDate'], createdDate.toIso8601String());
    });

    test('toJson handles null optional fields', () {
      final createdDate = DateTime.now();
      final outfit = Outfit(
        id: 'test-outfit-id',
        name: 'Simple Outfit',
        itemIds: ['item1'],
        createdDate: createdDate,
      );

      final json = outfit.toJson();

      expect(json['assignedDate'], null);
      expect(json['vibe'], null);
    });

    test('fromJson deserializes all fields correctly', () {
      final createdDate = DateTime.now();
      final assignedDate = DateTime.now().add(Duration(days: 1));
      final json = {
        'id': 'test-outfit-id',
        'name': 'Date Night',
        'itemIds': ['item1', 'item2', 'item3'],
        'assignedDate': assignedDate.toIso8601String(),
        'vibe': 'Date Night',
        'createdDate': createdDate.toIso8601String(),
      };

      final outfit = Outfit.fromJson(json);

      expect(outfit.id, 'test-outfit-id');
      expect(outfit.name, 'Date Night');
      expect(outfit.itemIds, ['item1', 'item2', 'item3']);
      expect(outfit.assignedDate, assignedDate);
      expect(outfit.vibe, 'Date Night');
      expect(outfit.createdDate, createdDate);
    });

    test('fromJson handles null optional fields', () {
      final createdDate = DateTime.now();
      final json = {
        'id': 'test-outfit-id',
        'name': 'Simple Outfit',
        'itemIds': ['item1'],
        'assignedDate': null,
        'vibe': null,
        'createdDate': createdDate.toIso8601String(),
      };

      final outfit = Outfit.fromJson(json);

      expect(outfit.assignedDate, null);
      expect(outfit.vibe, null);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = Outfit(
        id: 'round-trip-test',
        name: 'Round Trip Outfit',
        itemIds: ['item1', 'item2', 'item3', 'item4'],
        assignedDate: DateTime.now().add(Duration(days: 5)),
        vibe: 'Casual',
        createdDate: DateTime.now(),
      );

      final json = original.toJson();
      final restored = Outfit.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.itemIds, original.itemIds);
      expect(restored.assignedDate, original.assignedDate);
      expect(restored.vibe, original.vibe);
      expect(restored.createdDate, original.createdDate);
    });

    test('toJson and fromJson round-trip with null optional fields', () {
      final original = Outfit(
        id: 'round-trip-test-null',
        name: 'Minimal Outfit',
        itemIds: ['item1'],
        createdDate: DateTime.now(),
      );

      final json = original.toJson();
      final restored = Outfit.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.itemIds, original.itemIds);
      expect(restored.assignedDate, null);
      expect(restored.vibe, null);
      expect(restored.createdDate, original.createdDate);
    });

    test('handles empty itemIds list', () {
      final outfit = Outfit(
        id: 'empty-outfit',
        name: 'Empty Outfit',
        itemIds: [],
        createdDate: DateTime.now(),
      );

      expect(outfit.itemIds, isEmpty);

      final items = outfit.getItems((id) => null);
      expect(items, isEmpty);

      final json = outfit.toJson();
      expect(json['itemIds'], isEmpty);

      final restored = Outfit.fromJson(json);
      expect(restored.itemIds, isEmpty);
    });
  });
}
