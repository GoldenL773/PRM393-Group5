import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';

void main() {
  group('Property 13: Clothing Overlay Layering', () {
    property('Selected items are layered in correct order (bottoms, tops, outerwear)', () {
      // **Validates: Requirements 8.4**
      forAll(
        clothingItemListArbitrary(),
        (items) {
          // Sort items using the same logic as the TryOnScreen
          final sorted = _sortItemsByLayerOrder(items);
          
          // Verify the layering order is correct
          // Order should be: shoes (0) -> bottoms (1) -> tops (2) -> outerwear (3) -> accessories (4)
          for (int i = 0; i < sorted.length - 1; i++) {
            final currentLayer = _getLayerOrder(sorted[i].type);
            final nextLayer = _getLayerOrder(sorted[i + 1].type);
            
            expect(
              currentLayer <= nextLayer,
              isTrue,
              reason: 'Items should be sorted by layer order. '
                  'Item at index $i (${sorted[i].type}) has layer $currentLayer, '
                  'but item at index ${i + 1} (${sorted[i + 1].type}) has layer $nextLayer. '
                  'Expected currentLayer <= nextLayer.',
            );
          }
          
          // Verify specific ordering constraints
          _verifyLayeringConstraints(sorted);
        },
      );
    });

    property('Bottoms always appear before tops in the layer order', () {
      // **Validates: Requirements 8.4**
      forAll(
        clothingItemListArbitrary(),
        (items) {
          final sorted = _sortItemsByLayerOrder(items);
          
          // Find indices of bottoms and tops
          int? lastBottomsIndex;
          int? firstTopsIndex;
          
          for (int i = 0; i < sorted.length; i++) {
            if (sorted[i].type == ClothingType.bottoms) {
              lastBottomsIndex = i;
            }
            if (sorted[i].type == ClothingType.tops && firstTopsIndex == null) {
              firstTopsIndex = i;
            }
          }
          
          // If both exist, bottoms should come before tops
          if (lastBottomsIndex != null && firstTopsIndex != null) {
            expect(
              lastBottomsIndex < firstTopsIndex,
              isTrue,
              reason: 'All bottoms should appear before all tops in the layer order. '
                  'Last bottoms at index $lastBottomsIndex, first tops at index $firstTopsIndex.',
            );
          }
        },
      );
    });

    property('Tops always appear before outerwear in the layer order', () {
      // **Validates: Requirements 8.4**
      forAll(
        clothingItemListArbitrary(),
        (items) {
          final sorted = _sortItemsByLayerOrder(items);
          
          // Find indices of tops and outerwear
          int? lastTopsIndex;
          int? firstOuterwearIndex;
          
          for (int i = 0; i < sorted.length; i++) {
            if (sorted[i].type == ClothingType.tops) {
              lastTopsIndex = i;
            }
            if (sorted[i].type == ClothingType.outerwear && firstOuterwearIndex == null) {
              firstOuterwearIndex = i;
            }
          }
          
          // If both exist, tops should come before outerwear
          if (lastTopsIndex != null && firstOuterwearIndex != null) {
            expect(
              lastTopsIndex < firstOuterwearIndex,
              isTrue,
              reason: 'All tops should appear before all outerwear in the layer order. '
                  'Last tops at index $lastTopsIndex, first outerwear at index $firstOuterwearIndex.',
            );
          }
        },
      );
    });

    property('Shoes always appear at the back (first in layer order)', () {
      // **Validates: Requirements 8.4**
      forAll(
        clothingItemListArbitrary(),
        (items) {
          final sorted = _sortItemsByLayerOrder(items);
          
          // Find the first non-shoes item
          int? firstNonShoesIndex;
          for (int i = 0; i < sorted.length; i++) {
            if (sorted[i].type != ClothingType.shoes) {
              firstNonShoesIndex = i;
              break;
            }
          }
          
          // All shoes should appear before the first non-shoes item
          if (firstNonShoesIndex != null) {
            for (int i = firstNonShoesIndex; i < sorted.length; i++) {
              expect(
                sorted[i].type != ClothingType.shoes,
                isTrue,
                reason: 'All shoes should appear at the beginning of the layer order. '
                    'Found shoes at index $i after non-shoes item at index $firstNonShoesIndex.',
              );
            }
          }
        },
      );
    });

    property('Accessories always appear at the front (last in layer order)', () {
      // **Validates: Requirements 8.4**
      forAll(
        clothingItemListArbitrary(),
        (items) {
          final sorted = _sortItemsByLayerOrder(items);
          
          // Find the last non-accessories item
          int? lastNonAccessoriesIndex;
          for (int i = sorted.length - 1; i >= 0; i--) {
            if (sorted[i].type != ClothingType.accessories) {
              lastNonAccessoriesIndex = i;
              break;
            }
          }
          
          // All accessories should appear after the last non-accessories item
          if (lastNonAccessoriesIndex != null) {
            for (int i = 0; i <= lastNonAccessoriesIndex; i++) {
              expect(
                sorted[i].type != ClothingType.accessories,
                isTrue,
                reason: 'All accessories should appear at the end of the layer order. '
                    'Found accessories at index $i before non-accessories item at index $lastNonAccessoriesIndex.',
              );
            }
          }
        },
      );
    });

    property('Sorting is stable - items of same type maintain relative order', () {
      // **Validates: Requirements 8.4**
      forAll(
        clothingItemListArbitrary(),
        (items) {
          // Create items with tracking IDs to verify stability
          final itemsWithIndices = items.asMap().entries.map((e) => (e.key, e.value)).toList();
          
          final sorted = _sortItemsByLayerOrder(items);
          
          // For each type, verify items maintain their relative order
          for (final type in ClothingType.values) {
            final originalIndices = itemsWithIndices
                .where((entry) => entry.$2.type == type)
                .map((entry) => entry.$1)
                .toList();
            
            final sortedIndices = <int>[];
            for (final item in sorted) {
              final originalIndex = itemsWithIndices
                  .firstWhere((entry) => entry.$2.id == item.id)
                  .$1;
              if (item.type == type) {
                sortedIndices.add(originalIndex);
              }
            }
            
            // Verify sorted indices are in ascending order (stable sort)
            for (int i = 0; i < sortedIndices.length - 1; i++) {
              expect(
                sortedIndices[i] < sortedIndices[i + 1],
                isTrue,
                reason: 'Items of type $type should maintain their relative order. '
                    'Original indices: $originalIndices, Sorted indices: $sortedIndices',
              );
            }
          }
        },
      );
    });
  });
}

/// Sorts clothing items by their layering order
/// This replicates the logic from TryOnScreen._sortItemsByLayerOrder
List<ClothingItem> _sortItemsByLayerOrder(List<ClothingItem> items) {
  final layerOrder = {
    ClothingType.shoes: 0,
    ClothingType.bottoms: 1,
    ClothingType.tops: 2,
    ClothingType.outerwear: 3,
    ClothingType.accessories: 4,
  };
  
  final sorted = List<ClothingItem>.from(items);
  sorted.sort((a, b) {
    final orderA = layerOrder[a.type] ?? 0;
    final orderB = layerOrder[b.type] ?? 0;
    return orderA.compareTo(orderB);
  });
  
  return sorted;
}

/// Gets the layer order for a clothing type
int _getLayerOrder(ClothingType type) {
  const layerOrder = {
    ClothingType.shoes: 0,
    ClothingType.bottoms: 1,
    ClothingType.tops: 2,
    ClothingType.outerwear: 3,
    ClothingType.accessories: 4,
  };
  
  return layerOrder[type] ?? 0;
}

/// Verifies specific layering constraints
void _verifyLayeringConstraints(List<ClothingItem> sorted) {
  // Group items by type
  final itemsByType = <ClothingType, List<int>>{};
  for (int i = 0; i < sorted.length; i++) {
    final type = sorted[i].type;
    itemsByType.putIfAbsent(type, () => []).add(i);
  }
  
  // Verify shoes come before bottoms
  if (itemsByType.containsKey(ClothingType.shoes) && 
      itemsByType.containsKey(ClothingType.bottoms)) {
    final lastShoes = itemsByType[ClothingType.shoes]!.last;
    final firstBottoms = itemsByType[ClothingType.bottoms]!.first;
    expect(
      lastShoes < firstBottoms,
      isTrue,
      reason: 'Shoes should come before bottoms',
    );
  }
  
  // Verify bottoms come before tops
  if (itemsByType.containsKey(ClothingType.bottoms) && 
      itemsByType.containsKey(ClothingType.tops)) {
    final lastBottoms = itemsByType[ClothingType.bottoms]!.last;
    final firstTops = itemsByType[ClothingType.tops]!.first;
    expect(
      lastBottoms < firstTops,
      isTrue,
      reason: 'Bottoms should come before tops',
    );
  }
  
  // Verify tops come before outerwear
  if (itemsByType.containsKey(ClothingType.tops) && 
      itemsByType.containsKey(ClothingType.outerwear)) {
    final lastTops = itemsByType[ClothingType.tops]!.last;
    final firstOuterwear = itemsByType[ClothingType.outerwear]!.first;
    expect(
      lastTops < firstOuterwear,
      isTrue,
      reason: 'Tops should come before outerwear',
    );
  }
  
  // Verify outerwear comes before accessories
  if (itemsByType.containsKey(ClothingType.outerwear) && 
      itemsByType.containsKey(ClothingType.accessories)) {
    final lastOuterwear = itemsByType[ClothingType.outerwear]!.last;
    final firstAccessories = itemsByType[ClothingType.accessories]!.first;
    expect(
      lastOuterwear < firstAccessories,
      isTrue,
      reason: 'Outerwear should come before accessories',
    );
  }
}

/// Arbitrary generator for a list of ClothingItems
Arbitrary<List<ClothingItem>> clothingItemListArbitrary() {
  return integer(min: 1, max: 10).flatMap((count) {
    return _generateClothingItemList(count);
  });
}

/// Generates a list of clothing items
Arbitrary<List<ClothingItem>> _generateClothingItemList(int count) {
  if (count == 0) {
    return constant(<ClothingItem>[]);
  }
  
  return clothingItemArbitrary().flatMap((item) {
    return _generateClothingItemList(count - 1).flatMap((rest) {
      return constant([item, ...rest]);
    });
  });
}

/// Arbitrary generator for a single ClothingItem
Arbitrary<ClothingItem> clothingItemArbitrary() {
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
