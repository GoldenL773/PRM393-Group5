import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';
import 'package:goldfit_frontend/models/filter_state.dart';
import 'package:goldfit_frontend/models/outfit.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';

void main() {
  group('Property 16: Reactive State Updates', () {
    property('notifyListeners is called when wardrobe items are updated', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        clothingItemUpdateArbitrary(),
        (updateData) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          // Track if listeners are notified
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Get an existing item to update
          final items = appState.allItems;
          if (items.isEmpty) return; // Skip if no items
          
          final originalItem = items.first;
          final updatedItem = originalItem.copyWith(
            color: updateData.newColor,
            price: updateData.newPrice,
          );
          
          // Perform the update
          appState.updateItem(updatedItem);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when item is updated');
          
          // Verify the change is reflected in the state
          final retrievedItem = mockDataProvider.getItemById(originalItem.id);
          expect(retrievedItem?.color, equals(updateData.newColor),
              reason: 'Updated color should be reflected in state');
        },
      );
    });

    property('notifyListeners is called when filters are applied', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        filterStateArbitrary(),
        (filterState) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Apply filters
          appState.applyFilters(filterState);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when filters are applied');
          
          // Verify filter state is updated
          expect(appState.filterState, equals(filterState),
              reason: 'Filter state should be updated');
        },
      );
    });

    property('notifyListeners is called when category is selected', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        categoryArbitrary(),
        (category) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Select category
          appState.selectCategory(category);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when category is selected');
          
          // Verify category is updated
          expect(appState.selectedCategory, equals(category),
              reason: 'Selected category should be updated');
        },
      );
    });

    property('notifyListeners is called when try-on items are selected', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        integer(min: 1, max: 5),
        (itemCount) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final items = appState.allItems;
          if (items.length < itemCount) return; // Skip if not enough items
          
          var listenerCallCount = 0;
          appState.addListener(() {
            listenerCallCount++;
          });
          
          // Select multiple items
          for (var i = 0; i < itemCount; i++) {
            appState.selectItemForTryOn(items[i].id);
          }
          
          // Verify listener was called for each selection
          expect(listenerCallCount, equals(itemCount),
              reason: 'notifyListeners should be called for each item selection');
          
          // Verify items are in selection
          expect(appState.selectedItemIds.length, equals(itemCount),
              reason: 'All selected items should be in state');
        },
      );
    });

    property('notifyListeners is called when try-on mode is toggled', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        integer(min: 1, max: 5),
        (toggleCount) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          var listenerCallCount = 0;
          appState.addListener(() {
            listenerCallCount++;
          });
          
          final initialMode = appState.tryOnMode;
          
          // Toggle mode multiple times
          for (var i = 0; i < toggleCount; i++) {
            appState.toggleTryOnMode();
          }
          
          // Verify listener was called for each toggle
          expect(listenerCallCount, equals(toggleCount),
              reason: 'notifyListeners should be called for each mode toggle');
          
          // Verify mode is correct based on toggle count
          final expectedMode = toggleCount % 2 == 0 
              ? initialMode 
              : (initialMode == TryOnMode.quick ? TryOnMode.realistic : TryOnMode.quick);
          expect(appState.tryOnMode, equals(expectedMode),
              reason: 'Try-on mode should reflect toggle operations');
        },
      );
    });

    property('notifyListeners is called when outfit is assigned to date', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        dateArbitrary(),
        (date) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.isEmpty) return; // Skip if no outfits
          
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Assign outfit to date
          appState.assignOutfitToDate(outfits.first.id, date);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when outfit is assigned');
          
          // Verify assignment is reflected in state
          final assignedOutfit = appState.getOutfitForDate(date);
          expect(assignedOutfit, isNotNull,
              reason: 'Assigned outfit should be retrievable');
          expect(assignedOutfit?.id, equals(outfits.first.id),
              reason: 'Correct outfit should be assigned');
        },
      );
    });

    property('notifyListeners is called when calendar view is toggled', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        integer(min: 1, max: 5),
        (toggleCount) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          var listenerCallCount = 0;
          appState.addListener(() {
            listenerCallCount++;
          });
          
          final initialView = appState.calendarView;
          
          // Toggle view multiple times
          for (var i = 0; i < toggleCount; i++) {
            appState.toggleCalendarView();
          }
          
          // Verify listener was called for each toggle
          expect(listenerCallCount, equals(toggleCount),
              reason: 'notifyListeners should be called for each view toggle');
          
          // Verify view is correct based on toggle count
          final expectedView = toggleCount % 2 == 0 
              ? initialView 
              : (initialView == CalendarView.month ? CalendarView.week : CalendarView.month);
          expect(appState.calendarView, equals(expectedView),
              reason: 'Calendar view should reflect toggle operations');
        },
      );
    });

    property('notifyListeners is called when outfit is saved', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        outfitArbitrary(),
        (outfit) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Save outfit
          appState.saveOutfit(outfit);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when outfit is saved');
        },
      );
    });

    property('notifyListeners is called when item is added', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        clothingItemArbitrary(),
        (newItem) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final initialCount = appState.allItems.length;
          
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Add item
          appState.addItem(newItem);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when item is added');
          
          // Verify item count increased
          expect(appState.allItems.length, equals(initialCount + 1),
              reason: 'Item count should increase after adding item');
        },
      );
    });

    property('notifyListeners is called when item is deleted', () {
      // **Validates: Requirements 13.2, 13.3**
      forAll(
        integer(min: 0, max: 100),
        (seed) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final items = appState.allItems;
          if (items.isEmpty) return; // Skip if no items
          
          final itemToDelete = items[seed % items.length];
          final initialCount = items.length;
          
          var listenerCalled = false;
          appState.addListener(() {
            listenerCalled = true;
          });
          
          // Delete item
          appState.deleteItem(itemToDelete.id);
          
          // Verify listener was called
          expect(listenerCalled, isTrue,
              reason: 'notifyListeners should be called when item is deleted');
          
          // Verify item count decreased
          expect(appState.allItems.length, equals(initialCount - 1),
              reason: 'Item count should decrease after deleting item');
        },
      );
    });
  });
}

// ============================================================================
// Arbitrary Generators
// ============================================================================

/// Arbitrary generator for ClothingItem updates
Arbitrary<ClothingItemUpdate> clothingItemUpdateArbitrary() {
  return integer(min: 0, max: 14).flatMap((colorIndex) {
    return integer(min: 0, max: 1).flatMap((hasPriceInt) {
      return integer(min: 0, max: 500).flatMap((priceInt) {
        final colors = [
          'red', 'blue', 'green', 'black', 'white',
          'gray', 'brown', 'yellow', 'purple', 'pink',
          'orange', 'beige', 'navy', 'burgundy', 'olive',
        ];
        final color = colors[colorIndex];
        final hasPrice = hasPriceInt == 1;
        final price = hasPrice ? priceInt.toDouble() : null;
        
        return constant(ClothingItemUpdate(
          newColor: color,
          newPrice: price,
        ));
      });
    });
  });
}

/// Arbitrary generator for FilterState
Arbitrary<FilterState> filterStateArbitrary() {
  return integer(min: 0, max: 3).flatMap((colorCount) {
    return integer(min: 0, max: 4).flatMap((seasonCount) {
      final colors = ['red', 'blue', 'green', 'black', 'white'];
      final selectedColors = <String>[];
      for (var i = 0; i < colorCount && i < colors.length; i++) {
        selectedColors.add(colors[i]);
      }
      
      final allSeasons = Season.values;
      final selectedSeasons = <Season>[];
      for (var i = 0; i < seasonCount && i < allSeasons.length; i++) {
        selectedSeasons.add(allSeasons[i]);
      }
      
      return constant(FilterState(
        colors: selectedColors,
        seasons: selectedSeasons,
      ));
    });
  });
}

/// Arbitrary generator for ClothingType (including null for "All")
Arbitrary<ClothingType?> categoryArbitrary() {
  return integer(min: 0, max: ClothingType.values.length).flatMap((index) {
    if (index == ClothingType.values.length) {
      return constant(null); // "All" category
    }
    return constant(ClothingType.values[index]);
  });
}

/// Arbitrary generator for DateTime
Arbitrary<DateTime> dateArbitrary() {
  return integer(min: 0, max: 365).flatMap((daysOffset) {
    final baseDate = DateTime(2024, 1, 1);
    return constant(baseDate.add(Duration(days: daysOffset)));
  });
}

/// Arbitrary generator for Outfit
Arbitrary<Outfit> outfitArbitrary() {
  return integer(min: 1, max: 1000000).flatMap((idNum) {
    return integer(min: 1, max: 5).flatMap((itemCount) {
      return integer(min: 0, max: 2).flatMap((vibeIndex) {
        final vibes = ['Casual', 'Work', 'Date Night'];
        final vibe = vibes[vibeIndex];
        
        // Generate item IDs
        final itemIds = List.generate(itemCount, (i) => 'item-${idNum + i}');
        
        return constant(Outfit(
          id: 'outfit-$idNum',
          name: 'Test Outfit $idNum',
          itemIds: itemIds,
          vibe: vibe,
          createdDate: DateTime.now(),
        ));
      });
    });
  });
}

/// Arbitrary generator for ClothingItem
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
                    final colors = [
                      'red', 'blue', 'green', 'black', 'white',
                      'gray', 'brown', 'yellow', 'purple', 'pink',
                      'orange', 'beige', 'navy', 'burgundy', 'olive',
                    ];
                    final color = colors[colorIndex];
                    
                    final type = ClothingType.values[typeIndex];
                    
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

// ============================================================================
// Helper Classes
// ============================================================================

/// Helper class for clothing item updates
class ClothingItemUpdate {
  final String newColor;
  final double? newPrice;
  
  ClothingItemUpdate({
    required this.newColor,
    this.newPrice,
  });
}
