import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';
import 'package:goldfit_frontend/models/filter_state.dart';

void main() {
  group('FilterState', () {
    test('empty filter state has no colors or seasons', () {
      final filter = FilterState.empty();
      
      expect(filter.colors, isEmpty);
      expect(filter.seasons, isEmpty);
      expect(filter.isEmpty, isTrue);
      expect(filter.activeFilterCount, equals(0));
    });

    test('isEmpty returns true when no filters are active', () {
      final filter = FilterState();
      
      expect(filter.isEmpty, isTrue);
    });

    test('isEmpty returns false when colors are active', () {
      final filter = FilterState(colors: ['Red']);
      
      expect(filter.isEmpty, isFalse);
    });

    test('isEmpty returns false when seasons are active', () {
      final filter = FilterState(seasons: [Season.summer]);
      
      expect(filter.isEmpty, isFalse);
    });

    test('activeFilterCount returns correct count with only colors', () {
      final filter = FilterState(colors: ['Red', 'Blue', 'Green']);
      
      expect(filter.activeFilterCount, equals(3));
    });

    test('activeFilterCount returns correct count with only seasons', () {
      final filter = FilterState(seasons: [Season.summer, Season.winter]);
      
      expect(filter.activeFilterCount, equals(2));
    });

    test('activeFilterCount returns correct count with both colors and seasons', () {
      final filter = FilterState(
        colors: ['Red', 'Blue'],
        seasons: [Season.summer, Season.winter, Season.spring],
      );
      
      expect(filter.activeFilterCount, equals(5));
    });

    test('matches returns true for any item when filter is empty', () {
      final filter = FilterState.empty();
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isTrue);
    });

    test('matches returns true when item color matches color filter', () {
      final filter = FilterState(colors: ['Red', 'Blue']);
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isTrue);
    });

    test('matches returns false when item color does not match color filter', () {
      final filter = FilterState(colors: ['Blue', 'Green']);
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isFalse);
    });

    test('matches returns true when item has at least one matching season', () {
      final filter = FilterState(seasons: [Season.summer, Season.winter]);
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer, Season.spring],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isTrue);
    });

    test('matches returns false when item has no matching seasons', () {
      final filter = FilterState(seasons: [Season.winter]);
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer, Season.spring],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isFalse);
    });

    test('matches returns true when item matches both color and season filters', () {
      final filter = FilterState(
        colors: ['Red', 'Blue'],
        seasons: [Season.summer, Season.winter],
      );
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.winter, Season.spring],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isTrue);
    });

    test('matches returns false when item matches color but not season', () {
      final filter = FilterState(
        colors: ['Red'],
        seasons: [Season.winter],
      );
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isFalse);
    });

    test('matches returns false when item matches season but not color', () {
      final filter = FilterState(
        colors: ['Blue'],
        seasons: [Season.summer],
      );
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isFalse);
    });

    test('matches handles items with multiple seasons correctly', () {
      final filter = FilterState(seasons: [Season.summer]);
      final item = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.spring, Season.summer, Season.fall],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(item), isTrue);
    });

    test('matches handles multiple color filters correctly', () {
      final filter = FilterState(colors: ['Red', 'Blue', 'Green']);
      final redItem = ClothingItem(
        id: '1',
        imageUrl: 'test.png',
        type: ClothingType.tops,
        color: 'Red',
        seasons: [Season.summer],
        addedDate: DateTime.now(),
      );
      final blueItem = ClothingItem(
        id: '2',
        imageUrl: 'test.png',
        type: ClothingType.bottoms,
        color: 'Blue',
        seasons: [Season.winter],
        addedDate: DateTime.now(),
      );
      final yellowItem = ClothingItem(
        id: '3',
        imageUrl: 'test.png',
        type: ClothingType.shoes,
        color: 'Yellow',
        seasons: [Season.spring],
        addedDate: DateTime.now(),
      );
      
      expect(filter.matches(redItem), isTrue);
      expect(filter.matches(blueItem), isTrue);
      expect(filter.matches(yellowItem), isFalse);
    });
  });
}
