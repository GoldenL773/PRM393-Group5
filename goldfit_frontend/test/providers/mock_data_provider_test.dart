import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';

void main() {
  group('MockDataProvider - Mock Data Generation', () {
    late MockDataProvider provider;

    setUp(() {
      provider = MockDataProvider();
    });

    test('generates at least 20 clothing items', () {
      final items = provider.getAllItems();
      expect(items.length, greaterThanOrEqualTo(20));
    });

    test('generates at least 5 outfits', () {
      final outfits = provider.getAllOutfits();
      expect(outfits.length, greaterThanOrEqualTo(5));
    });

    test('all categories have items', () {
      final items = provider.getAllItems();
      
      // Check that each category has at least one item
      for (final category in ClothingType.values) {
        final categoryItems = items.where((item) => item.type == category);
        expect(
          categoryItems.isNotEmpty,
          true,
          reason: 'Category ${category.name} should have at least one item',
        );
      }
    });

    test('outfit item references are valid', () {
      final items = provider.getAllItems();
      final outfits = provider.getAllOutfits();
      final itemIds = items.map((item) => item.id).toSet();
      
      for (final outfit in outfits) {
        for (final itemId in outfit.itemIds) {
          expect(
            itemIds.contains(itemId),
            true,
            reason: 'Outfit "${outfit.name}" references invalid item ID: $itemId',
          );
        }
      }
    });
  });
}
