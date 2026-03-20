import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';

void main() {
  group('ClothingItem', () {
    test('creates instance with all required properties', () {
      final now = DateTime.now();
      final item = ClothingItem(
        id: 'test-id',
        imageUrl: 'assets/test.png',
        type: ClothingType.tops,
        color: 'blue',
        seasons: [Season.spring, Season.summer],
        price: 49.99,
        usageCount: 5,
        addedDate: now,
      );

      expect(item.id, 'test-id');
      expect(item.imageUrl, 'assets/test.png');
      expect(item.type, ClothingType.tops);
      expect(item.color, 'blue');
      expect(item.seasons, [Season.spring, Season.summer]);
      expect(item.price, 49.99);
      expect(item.usageCount, 5);
      expect(item.addedDate, now);
    });

    test('creates instance with default usageCount of 0', () {
      final item = ClothingItem(
        id: 'test-id',
        imageUrl: 'assets/test.png',
        type: ClothingType.bottoms,
        color: 'black',
        seasons: [Season.fall],
        addedDate: DateTime.now(),
      );

      expect(item.usageCount, 0);
      expect(item.price, null);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ClothingItem(
        id: 'test-id',
        imageUrl: 'assets/original.png',
        type: ClothingType.tops,
        color: 'red',
        seasons: [Season.summer],
        price: 29.99,
        usageCount: 3,
        addedDate: DateTime.now(),
      );

      final updated = original.copyWith(
        color: 'blue',
        usageCount: 5,
      );

      expect(updated.id, original.id);
      expect(updated.imageUrl, original.imageUrl);
      expect(updated.type, original.type);
      expect(updated.color, 'blue');
      expect(updated.seasons, original.seasons);
      expect(updated.price, original.price);
      expect(updated.usageCount, 5);
      expect(updated.addedDate, original.addedDate);
    });

    test('toJson serializes all fields correctly', () {
      final now = DateTime.now();
      final item = ClothingItem(
        id: 'test-id',
        imageUrl: 'assets/test.png',
        type: ClothingType.outerwear,
        color: 'green',
        seasons: [Season.fall, Season.winter],
        price: 99.99,
        usageCount: 10,
        addedDate: now,
      );

      final json = item.toJson();

      expect(json['id'], 'test-id');
      expect(json['imageUrl'], 'assets/test.png');
      expect(json['type'], 'outerwear');
      expect(json['color'], 'green');
      expect(json['seasons'], ['fall', 'winter']);
      expect(json['price'], 99.99);
      expect(json['usageCount'], 10);
      expect(json['addedDate'], now.toIso8601String());
    });

    test('fromJson deserializes all fields correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-id',
        'imageUrl': 'assets/test.png',
        'type': 'shoes',
        'color': 'white',
        'seasons': ['spring', 'summer'],
        'price': 79.99,
        'usageCount': 7,
        'addedDate': now.toIso8601String(),
      };

      final item = ClothingItem.fromJson(json);

      expect(item.id, 'test-id');
      expect(item.imageUrl, 'assets/test.png');
      expect(item.type, ClothingType.shoes);
      expect(item.color, 'white');
      expect(item.seasons, [Season.spring, Season.summer]);
      expect(item.price, 79.99);
      expect(item.usageCount, 7);
      expect(item.addedDate, now);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = ClothingItem(
        id: 'round-trip-test',
        imageUrl: 'assets/roundtrip.png',
        type: ClothingType.accessories,
        color: 'gold',
        seasons: [Season.spring, Season.summer, Season.fall, Season.winter],
        price: 19.99,
        usageCount: 15,
        addedDate: DateTime.now(),
      );

      final json = original.toJson();
      final restored = ClothingItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.type, original.type);
      expect(restored.color, original.color);
      expect(restored.seasons, original.seasons);
      expect(restored.price, original.price);
      expect(restored.usageCount, original.usageCount);
      expect(restored.addedDate, original.addedDate);
    });

    test('handles null price correctly', () {
      final item = ClothingItem(
        id: 'no-price',
        imageUrl: 'assets/test.png',
        type: ClothingType.tops,
        color: 'purple',
        seasons: [Season.spring],
        addedDate: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['price'], null);

      final restored = ClothingItem.fromJson(json);
      expect(restored.price, null);
    });
  });
}
