import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/models/wardrobe_analytics.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';

void main() {
  group('WardrobeAnalytics', () {
    // Helper function to create test clothing items
    ClothingItem createTestItem(String id, int usageCount) {
      return ClothingItem(
        id: id,
        imageUrl: 'assets/test_$id.png',
        type: ClothingType.tops,
        color: 'blue',
        seasons: [Season.spring],
        price: 50.0,
        usageCount: usageCount,
        addedDate: DateTime.now(),
      );
    }

    test('creates instance with all required properties', () {
      final mostWorn = [
        createTestItem('item1', 10),
        createTestItem('item2', 8),
      ];
      final leastWorn = [
        createTestItem('item3', 1),
        createTestItem('item4', 0),
      ];

      final analytics = WardrobeAnalytics(
        totalItems: 25,
        totalValue: 1250.50,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      expect(analytics.totalItems, 25);
      expect(analytics.totalValue, 1250.50);
      expect(analytics.mostWorn.length, 2);
      expect(analytics.leastWorn.length, 2);
      expect(analytics.mostWorn[0].id, 'item1');
      expect(analytics.leastWorn[0].id, 'item3');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = WardrobeAnalytics(
        totalItems: 20,
        totalValue: 1000.0,
        mostWorn: [createTestItem('item1', 10)],
        leastWorn: [createTestItem('item2', 0)],
      );

      final updated = original.copyWith(
        totalItems: 25,
        totalValue: 1500.0,
      );

      expect(updated.totalItems, 25);
      expect(updated.totalValue, 1500.0);
      expect(updated.mostWorn, original.mostWorn);
      expect(updated.leastWorn, original.leastWorn);
    });

    test('toJson serializes all fields correctly', () {
      final mostWorn = [createTestItem('item1', 10)];
      final leastWorn = [createTestItem('item2', 0)];

      final analytics = WardrobeAnalytics(
        totalItems: 15,
        totalValue: 750.25,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      final json = analytics.toJson();

      expect(json['totalItems'], 15);
      expect(json['totalValue'], 750.25);
      expect(json['mostWorn'], isA<List>());
      expect(json['leastWorn'], isA<List>());
      expect((json['mostWorn'] as List).length, 1);
      expect((json['leastWorn'] as List).length, 1);
    });

    test('fromJson deserializes all fields correctly', () {
      final item1Json = createTestItem('item1', 10).toJson();
      final item2Json = createTestItem('item2', 0).toJson();

      final json = {
        'totalItems': 30,
        'totalValue': 2000.0,
        'mostWorn': [item1Json],
        'leastWorn': [item2Json],
      };

      final analytics = WardrobeAnalytics.fromJson(json);

      expect(analytics.totalItems, 30);
      expect(analytics.totalValue, 2000.0);
      expect(analytics.mostWorn.length, 1);
      expect(analytics.leastWorn.length, 1);
      expect(analytics.mostWorn[0].id, 'item1');
      expect(analytics.leastWorn[0].id, 'item2');
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = WardrobeAnalytics(
        totalItems: 40,
        totalValue: 3500.75,
        mostWorn: [
          createTestItem('most1', 15),
          createTestItem('most2', 12),
        ],
        leastWorn: [
          createTestItem('least1', 1),
          createTestItem('least2', 0),
        ],
      );

      final json = original.toJson();
      final restored = WardrobeAnalytics.fromJson(json);

      expect(restored.totalItems, original.totalItems);
      expect(restored.totalValue, original.totalValue);
      expect(restored.mostWorn.length, original.mostWorn.length);
      expect(restored.leastWorn.length, original.leastWorn.length);
      expect(restored.mostWorn[0].id, original.mostWorn[0].id);
      expect(restored.leastWorn[0].id, original.leastWorn[0].id);
    });

    test('equality operator works correctly', () {
      final mostWorn = [createTestItem('item1', 10)];
      final leastWorn = [createTestItem('item2', 0)];

      final analytics1 = WardrobeAnalytics(
        totalItems: 20,
        totalValue: 1000.0,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      final analytics2 = WardrobeAnalytics(
        totalItems: 20,
        totalValue: 1000.0,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      final analytics3 = WardrobeAnalytics(
        totalItems: 25,
        totalValue: 1000.0,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      expect(analytics1 == analytics2, true);
      expect(analytics1 == analytics3, false);
    });

    test('hashCode is consistent with equality', () {
      final mostWorn = [createTestItem('item1', 10)];
      final leastWorn = [createTestItem('item2', 0)];

      final analytics1 = WardrobeAnalytics(
        totalItems: 20,
        totalValue: 1000.0,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      final analytics2 = WardrobeAnalytics(
        totalItems: 20,
        totalValue: 1000.0,
        mostWorn: mostWorn,
        leastWorn: leastWorn,
      );

      expect(analytics1.hashCode, analytics2.hashCode);
    });

    test('toString provides readable representation', () {
      final analytics = WardrobeAnalytics(
        totalItems: 20,
        totalValue: 1000.0,
        mostWorn: [createTestItem('item1', 10)],
        leastWorn: [createTestItem('item2', 0)],
      );

      final str = analytics.toString();
      expect(str, contains('20'));
      expect(str, contains('1000.0'));
      expect(str, contains('1 items'));
    });

    test('handles empty mostWorn and leastWorn lists', () {
      final analytics = WardrobeAnalytics(
        totalItems: 0,
        totalValue: 0.0,
        mostWorn: [],
        leastWorn: [],
      );

      expect(analytics.mostWorn.length, 0);
      expect(analytics.leastWorn.length, 0);

      final json = analytics.toJson();
      final restored = WardrobeAnalytics.fromJson(json);

      expect(restored.mostWorn.length, 0);
      expect(restored.leastWorn.length, 0);
    });
  });
}
