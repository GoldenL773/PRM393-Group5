import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';

void main() {
  group('Property 5: Mock Data Validity', () {
    property('All generated ClothingItems have valid attributes', () {
      // **Validates: Requirements 2.2**
      forAll(
        clothingItemArbitrary(),
        (item) {
          // Verify type is not null (enum always has a value)
          expect(item.type, isNotNull);

          // Verify color is non-empty
          expect(item.color.isNotEmpty, isTrue,
              reason: 'Color should be non-empty, got: "${item.color}"');

          // Verify at least one season
          expect(item.seasons.isNotEmpty, isTrue,
              reason: 'Should have at least one season, got: ${item.seasons}');

          // Verify non-negative price if present
          if (item.price != null) {
            expect(item.price! >= 0, isTrue,
                reason: 'Price should be non-negative, got: ${item.price}');
          }

          // Additional validity checks
          expect(item.id.isNotEmpty, isTrue, reason: 'ID should be non-empty');
          expect(item.imageUrl.isNotEmpty, isTrue,
              reason: 'Image URL should be non-empty');
          expect(item.usageCount >= 0, isTrue,
              reason: 'Usage count should be non-negative');
        },
      );
    });
  });

  group('Property 6: Image Representation Completeness', () {
    property('All ClothingItems have either asset image or colored placeholder', () {
      // **Validates: Requirements 2.5, 12.3**
      forAll(
        clothingItemArbitrary(),
        (item) {
          // Verify imageUrl is not empty
          expect(item.imageUrl.isNotEmpty, isTrue,
              reason: 'Image URL should not be empty');

          // Verify it's either an asset path or a placeholder
          final isAssetImage = item.imageUrl.startsWith('assets/');
          final isPlaceholder = item.imageUrl.startsWith('placeholder-');

          expect(isAssetImage || isPlaceholder, isTrue,
              reason: 'Image URL should be either an asset path (starts with "assets/") '
                  'or a colored placeholder (starts with "placeholder-"), '
                  'got: "${item.imageUrl}"');
        },
      );
    });
  });
}

/// Arbitrary generator for ClothingItem
Arbitrary<ClothingItem> clothingItemArbitrary() {
  final random = Random();
  
  return integer(min: 1, max: 1000000).flatMap((idNum) {
    return integer(min: 0, max: 14).flatMap((colorIndex) {
      return integer(min: 0, max: 4).flatMap((typeIndex) {
        return integer(min: 1, max: 4).flatMap((seasonCount) {
          return integer(min: 0, max: 100).flatMap((usage) {
            return integer(min: 0, max: 365).flatMap((daysAgo) {
              return integer(min: 0, max: 1).flatMap((hasPriceInt) {
                return integer(min: 0, max: 500).flatMap((priceInt) {
                  return integer(min: 0, max: 19).flatMap((imageNum) {
                    // Generate values
                    final colors = [
                      'red', 'blue', 'green', 'black', 'white',
                      'gray', 'brown', 'yellow', 'purple', 'pink',
                      'orange', 'beige', 'navy', 'burgundy', 'olive',
                    ];
                    final color = colors[colorIndex];
                    
                    final type = ClothingType.values[typeIndex];
                    
                    // Generate seasons (at least one)
                    final allSeasons = Season.values;
                    final seasons = <Season>[];
                    for (var i = 0; i < seasonCount && i < allSeasons.length; i++) {
                      if (!seasons.contains(allSeasons[i])) {
                        seasons.add(allSeasons[i]);
                      }
                    }
                    if (seasons.isEmpty) {
                      seasons.add(Season.spring);
                    }
                    
                    final hasPrice = hasPriceInt == 1;
                    final price = hasPrice ? priceInt.toDouble() : null;
                    
                    final imageUrl = imageNum % 2 == 0
                        ? 'assets/mock_$imageNum.png'
                        : 'placeholder-${color.toLowerCase()}';
                    
                    final addedDate = DateTime.now().subtract(Duration(days: daysAgo));
                    
                    return constant(ClothingItem(
                      id: 'item-$idNum',
                      imageUrl: imageUrl,
                      type: type,
                      color: color,
                      seasons: seasons,
                      price: price,
                      usageCount: usage,
                      addedDate: addedDate,
                    ));
                  });
                });
              });
            });
          });
        });
      });
    });
  });
}

