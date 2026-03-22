import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';

void main() {
  group('AppState Wardrobe Methods', () {
    late AppState appState;
    late MockDataProvider mockDataProvider;

    setUp(() {
      mockDataProvider = MockDataProvider();
      appState = AppState(mockDataProvider);
    });

    group('getFilteredItems', () {
      test('returns all items when no category or filters are selected', () {
        final allItems = appState.allItems;
        final filteredItems = appState.filteredItems;

        expect(filteredItems.length, equals(allItems.length));
        expect(filteredItems, containsAll(allItems));
      });

      test('returns only items of selected category', () {
        appState.selectCategory(ClothingType.tops);
        final filteredItems = appState.filteredItems;

        expect(filteredItems.every((item) => item.type == ClothingType.tops), isTrue);
      });

      test('returns items matching color filter', () {
        // Get a color that exists in the wardrobe
        final allItems = appState.allItems;
        final testColor = allItems.first.color;

        appState.applyFilters(FilterState(colors: [testColor]));
        final filteredItems = appState.filteredItems;

        expect(filteredItems.every((item) => item.color == testColor), isTrue);
        expect(filteredItems.isNotEmpty, isTrue);
      });

      test('returns items matching season filter', () {
        // Get a season that exists in the wardrobe
        final allItems = appState.allItems;
        final testSeason = allItems.first.seasons.first;

        appState.applyFilters(FilterState(seasons: [testSeason]));
        final filteredItems = appState.filteredItems;

        expect(
          filteredItems.every((item) => item.seasons.contains(testSeason)),
          isTrue,
        );
        expect(filteredItems.isNotEmpty, isTrue);
      });

      test('returns items matching both category and filters', () {
        // Get a color from a specific category
        final topsItems = mockDataProvider.getItemsByCategory(ClothingType.tops);
        if (topsItems.isEmpty) {
          return; // Skip if no tops items
        }
        
        final testColor = topsItems.first.color;

        appState.selectCategory(ClothingType.tops);
        appState.applyFilters(FilterState(colors: [testColor]));
        final filteredItems = appState.filteredItems;

        expect(
          filteredItems.every((item) => 
            item.type == ClothingType.tops && item.color == testColor
          ),
          isTrue,
        );
      });

      test('returns empty list when no items match filters', () {
        appState.applyFilters(FilterState(colors: ['NonExistentColor']));
        final filteredItems = appState.filteredItems;

        expect(filteredItems, isEmpty);
      });
    });

    group('applyFilters', () {
      test('updates filter state and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        final newFilters = FilterState(colors: ['Red'], seasons: [Season.summer]);
        appState.applyFilters(newFilters);

        expect(appState.filterState, equals(newFilters));
        expect(notified, isTrue);
      });

      test('can apply empty filters', () {
        appState.applyFilters(FilterState(colors: ['Red']));
        appState.applyFilters(FilterState.empty());

        expect(appState.filterState.isEmpty, isTrue);
      });
    });

    group('selectCategory', () {
      test('updates selected category and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        appState.selectCategory(ClothingType.bottoms);

        expect(appState.selectedCategory, equals(ClothingType.bottoms));
        expect(notified, isTrue);
      });

      test('can select null to show all categories', () {
        appState.selectCategory(ClothingType.tops);
        appState.selectCategory(null);

        expect(appState.selectedCategory, isNull);
        expect(appState.filteredItems.length, equals(appState.allItems.length));
      });
    });

    group('updateItem', () {
      test('updates item in data provider and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        final originalItem = appState.allItems.first;
        final updatedItem = originalItem.copyWith(color: 'UpdatedColor');

        appState.updateItem(updatedItem);

        final retrievedItem = mockDataProvider.getItemById(originalItem.id);
        expect(retrievedItem?.color, equals('UpdatedColor'));
        expect(notified, isTrue);
      });

      test('updated item reflects in filteredItems', () {
        final originalItem = appState.allItems.first;
        final updatedItem = originalItem.copyWith(color: 'UniqueTestColor');

        appState.updateItem(updatedItem);

        final filteredItems = appState.filteredItems;
        final foundItem = filteredItems.firstWhere((item) => item.id == originalItem.id);
        expect(foundItem.color, equals('UniqueTestColor'));
      });
    });

    group('clearFilters', () {
      test('clears all filters and notifies listeners', () {
        var notified = false;
        
        appState.applyFilters(FilterState(colors: ['Red'], seasons: [Season.summer]));
        appState.addListener(() => notified = true);

        appState.clearFilters();

        expect(appState.filterState.isEmpty, isTrue);
        expect(notified, isTrue);
      });
    });

    group('Integration: Category and Filter Combination', () {
      test('category filter applies before attribute filters', () {
        // Select a category
        appState.selectCategory(ClothingType.tops);
        final categoryFiltered = appState.filteredItems;

        // Apply additional color filter
        final testColor = categoryFiltered.first.color;
        appState.applyFilters(FilterState(colors: [testColor]));
        final fullyFiltered = appState.filteredItems;

        // All items should be tops with the specified color
        expect(
          fullyFiltered.every((item) => 
            item.type == ClothingType.tops && item.color == testColor
          ),
          isTrue,
        );
        expect(fullyFiltered.length, lessThanOrEqualTo(categoryFiltered.length));
      });

      test('clearing category shows all items with active filters', () {
        final testColor = appState.allItems.first.color;
        
        appState.selectCategory(ClothingType.tops);
        appState.applyFilters(FilterState(colors: [testColor]));
        appState.selectCategory(null);

        final filteredItems = appState.filteredItems;
        
        // Should show items of all categories with the test color
        expect(filteredItems.every((item) => item.color == testColor), isTrue);
      });
    });
  });

  group('AppState Try-On Methods', () {
    late AppState appState;
    late MockDataProvider mockDataProvider;

    setUp(() {
      mockDataProvider = MockDataProvider();
      appState = AppState(mockDataProvider);
    });

    group('selectItemForTryOn', () {
      test('adds item to selection and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        final itemId = appState.allItems.first.id;
        appState.selectItemForTryOn(itemId);

        expect(appState.selectedItemIds, contains(itemId));
        expect(notified, isTrue);
      });

      test('does not add duplicate items', () {
        final itemId = appState.allItems.first.id;
        
        appState.selectItemForTryOn(itemId);
        appState.selectItemForTryOn(itemId);

        expect(appState.selectedItemIds.length, equals(1));
        expect(appState.selectedItemIds.first, equals(itemId));
      });

      test('can select multiple items', () {
        final item1Id = appState.allItems[0].id;
        final item2Id = appState.allItems[1].id;
        final item3Id = appState.allItems[2].id;

        appState.selectItemForTryOn(item1Id);
        appState.selectItemForTryOn(item2Id);
        appState.selectItemForTryOn(item3Id);

        expect(appState.selectedItemIds.length, equals(3));
        expect(appState.selectedItemIds, containsAll([item1Id, item2Id, item3Id]));
      });

      test('selectedTryOnItems returns actual ClothingItem objects', () {
        final item1 = appState.allItems[0];
        final item2 = appState.allItems[1];

        appState.selectItemForTryOn(item1.id);
        appState.selectItemForTryOn(item2.id);

        final selectedItems = appState.selectedTryOnItems;
        expect(selectedItems.length, equals(2));
        expect(selectedItems.any((item) => item.id == item1.id), isTrue);
        expect(selectedItems.any((item) => item.id == item2.id), isTrue);
      });
    });

    group('toggleTryOnMode', () {
      test('toggles from quick to realistic mode and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        expect(appState.tryOnMode, equals(TryOnMode.quick));

        appState.toggleTryOnMode();

        expect(appState.tryOnMode, equals(TryOnMode.realistic));
        expect(notified, isTrue);
      });

      test('toggles from realistic to quick mode', () {
        appState.setTryOnMode(TryOnMode.realistic);
        
        appState.toggleTryOnMode();

        expect(appState.tryOnMode, equals(TryOnMode.quick));
      });

      test('toggles back and forth correctly', () {
        expect(appState.tryOnMode, equals(TryOnMode.quick));
        
        appState.toggleTryOnMode();
        expect(appState.tryOnMode, equals(TryOnMode.realistic));
        
        appState.toggleTryOnMode();
        expect(appState.tryOnMode, equals(TryOnMode.quick));
        
        appState.toggleTryOnMode();
        expect(appState.tryOnMode, equals(TryOnMode.realistic));
      });
    });

    group('clearTryOnSelection', () {
      test('clears all selected items and notifies listeners', () {
        var notified = false;
        
        // Add some items first
        final item1Id = appState.allItems[0].id;
        final item2Id = appState.allItems[1].id;
        appState.selectItemForTryOn(item1Id);
        appState.selectItemForTryOn(item2Id);
        
        expect(appState.selectedItemIds.length, equals(2));

        appState.addListener(() => notified = true);
        appState.clearTryOnSelection();

        expect(appState.selectedItemIds, isEmpty);
        expect(notified, isTrue);
      });

      test('clearing empty selection still notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        appState.clearTryOnSelection();

        expect(appState.selectedItemIds, isEmpty);
        expect(notified, isTrue);
      });

      test('can select items again after clearing', () {
        final itemId = appState.allItems.first.id;
        
        appState.selectItemForTryOn(itemId);
        appState.clearTryOnSelection();
        appState.selectItemForTryOn(itemId);

        expect(appState.selectedItemIds.length, equals(1));
        expect(appState.selectedItemIds.first, equals(itemId));
      });
    });

    group('Integration: Try-On State Workflow', () {
      test('complete try-on workflow: select items, toggle mode, clear', () {
        // Start in quick mode
        expect(appState.tryOnMode, equals(TryOnMode.quick));
        expect(appState.selectedItemIds, isEmpty);

        // Select some items
        final item1Id = appState.allItems[0].id;
        final item2Id = appState.allItems[1].id;
        appState.selectItemForTryOn(item1Id);
        appState.selectItemForTryOn(item2Id);
        expect(appState.selectedItemIds.length, equals(2));

        // Toggle to realistic mode
        appState.toggleTryOnMode();
        expect(appState.tryOnMode, equals(TryOnMode.realistic));
        // Items should still be selected
        expect(appState.selectedItemIds.length, equals(2));

        // Clear selection
        appState.clearTryOnSelection();
        expect(appState.selectedItemIds, isEmpty);
        // Mode should remain realistic
        expect(appState.tryOnMode, equals(TryOnMode.realistic));
      });

      test('loadOutfitForTryOn replaces current selection', () {
        // Select some items first
        final item1Id = appState.allItems[0].id;
        appState.selectItemForTryOn(item1Id);
        expect(appState.selectedItemIds.length, equals(1));

        // Load an outfit
        final outfit = appState.allOutfits.first;
        appState.loadOutfitForTryOn(outfit);

        // Selection should be replaced with outfit items
        expect(appState.selectedItemIds.length, equals(outfit.itemIds.length));
        expect(appState.selectedItemIds, containsAll(outfit.itemIds));
        expect(appState.selectedItemIds, isNot(contains(item1Id)));
      });

      test('mode and selection are independent', () {
        final itemId = appState.allItems.first.id;
        
        // Select item in quick mode
        appState.selectItemForTryOn(itemId);
        expect(appState.tryOnMode, equals(TryOnMode.quick));
        expect(appState.selectedItemIds, contains(itemId));

        // Toggle mode - selection should persist
        appState.toggleTryOnMode();
        expect(appState.tryOnMode, equals(TryOnMode.realistic));
        expect(appState.selectedItemIds, contains(itemId));

        // Clear selection - mode should persist
        appState.clearTryOnSelection();
        expect(appState.tryOnMode, equals(TryOnMode.realistic));
        expect(appState.selectedItemIds, isEmpty);
      });
    });
  });

  group('AppState Planner Methods', () {
    late AppState appState;
    late MockDataProvider mockDataProvider;

    setUp(() {
      mockDataProvider = MockDataProvider();
      appState = AppState(mockDataProvider);
    });

    group('toggleCalendarView', () {
      test('toggles from month to week view and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        expect(appState.calendarView, equals(CalendarView.month));

        appState.toggleCalendarView();

        expect(appState.calendarView, equals(CalendarView.week));
        expect(notified, isTrue);
      });

      test('toggles from week to month view', () {
        appState.setCalendarView(CalendarView.week);
        
        appState.toggleCalendarView();

        expect(appState.calendarView, equals(CalendarView.month));
      });

      test('toggles back and forth correctly', () {
        expect(appState.calendarView, equals(CalendarView.month));
        
        appState.toggleCalendarView();
        expect(appState.calendarView, equals(CalendarView.week));
        
        appState.toggleCalendarView();
        expect(appState.calendarView, equals(CalendarView.month));
        
        appState.toggleCalendarView();
        expect(appState.calendarView, equals(CalendarView.week));
      });
    });

    group('assignOutfitToDate', () {
      test('assigns outfit to date and notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        final outfit = appState.allOutfits.first;
        final date = DateTime(2024, 6, 15);

        appState.assignOutfitToDate(outfit.id, date);

        final assignedOutfit = appState.getOutfitForDate(date);
        expect(assignedOutfit, isNotNull);
        expect(assignedOutfit?.id, equals(outfit.id));
        expect(notified, isTrue);
      });

      test('can assign different outfits to different dates', () {
        final outfit1 = appState.allOutfits[0];
        final outfit2 = appState.allOutfits[1];
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 16);

        appState.assignOutfitToDate(outfit1.id, date1);
        appState.assignOutfitToDate(outfit2.id, date2);

        final assignedOutfit1 = appState.getOutfitForDate(date1);
        final assignedOutfit2 = appState.getOutfitForDate(date2);

        expect(assignedOutfit1?.id, equals(outfit1.id));
        expect(assignedOutfit2?.id, equals(outfit2.id));
      });

      test('reassigning outfit to same date replaces previous assignment', () {
        final outfit1 = appState.allOutfits[0];
        final outfit2 = appState.allOutfits[1];
        final date = DateTime(2024, 6, 15);

        appState.assignOutfitToDate(outfit1.id, date);
        appState.assignOutfitToDate(outfit2.id, date);

        final assignedOutfit = appState.getOutfitForDate(date);
        expect(assignedOutfit?.id, equals(outfit2.id));
      });

      test('normalizes date to midnight for consistent assignment', () {
        final outfit = appState.allOutfits.first;
        final dateWithTime = DateTime(2024, 6, 15, 14, 30, 45);
        final dateMidnight = DateTime(2024, 6, 15);

        appState.assignOutfitToDate(outfit.id, dateWithTime);

        // Should be able to retrieve with midnight date
        final assignedOutfit = appState.getOutfitForDate(dateMidnight);
        expect(assignedOutfit, isNotNull);
        expect(assignedOutfit?.id, equals(outfit.id));
      });
    });

    group('getOutfitForDate', () {
      test('returns null when no outfit is assigned to date', () {
        final date = DateTime(2024, 6, 15);

        final assignedOutfit = appState.getOutfitForDate(date);

        expect(assignedOutfit, isNull);
      });

      test('returns assigned outfit for date', () {
        final outfit = appState.allOutfits.first;
        final date = DateTime(2024, 6, 15);

        appState.assignOutfitToDate(outfit.id, date);
        final assignedOutfit = appState.getOutfitForDate(date);

        expect(assignedOutfit, isNotNull);
        expect(assignedOutfit?.id, equals(outfit.id));
        expect(assignedOutfit?.name, equals(outfit.name));
      });

      test('returns null after unassigning outfit from date', () {
        final outfit = appState.allOutfits.first;
        final date = DateTime(2024, 6, 15);

        appState.assignOutfitToDate(outfit.id, date);
        appState.unassignOutfitFromDate(date);

        final assignedOutfit = appState.getOutfitForDate(date);
        expect(assignedOutfit, isNull);
      });

      test('normalizes date to midnight for consistent retrieval', () {
        final outfit = appState.allOutfits.first;
        final dateMidnight = DateTime(2024, 6, 15);
        final dateWithTime = DateTime(2024, 6, 15, 18, 45, 30);

        appState.assignOutfitToDate(outfit.id, dateMidnight);

        // Should be able to retrieve with any time on same day
        final assignedOutfit = appState.getOutfitForDate(dateWithTime);
        expect(assignedOutfit, isNotNull);
        expect(assignedOutfit?.id, equals(outfit.id));
      });
    });

    group('Integration: Planner State Workflow', () {
      test('complete planner workflow: toggle view, select date, assign outfit', () {
        // Start in month view
        expect(appState.calendarView, equals(CalendarView.month));

        // Toggle to week view
        appState.toggleCalendarView();
        expect(appState.calendarView, equals(CalendarView.week));

        // Select a date
        final date = DateTime(2024, 6, 15);
        appState.selectDate(date);
        expect(appState.selectedDate, equals(date));

        // Verify no outfit assigned initially
        expect(appState.getOutfitForDate(date), isNull);

        // Assign an outfit
        final outfit = appState.allOutfits.first;
        appState.assignOutfitToDate(outfit.id, date);
        expect(appState.getOutfitForDate(date)?.id, equals(outfit.id));

        // Toggle back to month view - assignment should persist
        appState.toggleCalendarView();
        expect(appState.calendarView, equals(CalendarView.month));
        expect(appState.getOutfitForDate(date)?.id, equals(outfit.id));
      });

      test('calendar view and outfit assignments are independent', () {
        final outfit = appState.allOutfits.first;
        final date = DateTime(2024, 6, 15);

        // Assign outfit in month view
        expect(appState.calendarView, equals(CalendarView.month));
        appState.assignOutfitToDate(outfit.id, date);

        // Toggle view - assignment should persist
        appState.toggleCalendarView();
        expect(appState.calendarView, equals(CalendarView.week));
        expect(appState.getOutfitForDate(date)?.id, equals(outfit.id));

        // Unassign outfit - view should persist
        appState.unassignOutfitFromDate(date);
        expect(appState.calendarView, equals(CalendarView.week));
        expect(appState.getOutfitForDate(date), isNull);
      });

      test('can manage multiple outfit assignments across different dates', () {
        final outfit1 = appState.allOutfits[0];
        final outfit2 = appState.allOutfits[1];
        final outfit3 = appState.allOutfits[2];
        
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 16);
        final date3 = DateTime(2024, 6, 17);

        // Assign outfits to different dates
        appState.assignOutfitToDate(outfit1.id, date1);
        appState.assignOutfitToDate(outfit2.id, date2);
        appState.assignOutfitToDate(outfit3.id, date3);

        // Verify all assignments
        expect(appState.getOutfitForDate(date1)?.id, equals(outfit1.id));
        expect(appState.getOutfitForDate(date2)?.id, equals(outfit2.id));
        expect(appState.getOutfitForDate(date3)?.id, equals(outfit3.id));

        // Unassign one outfit
        appState.unassignOutfitFromDate(date2);
        expect(appState.getOutfitForDate(date1)?.id, equals(outfit1.id));
        expect(appState.getOutfitForDate(date2), isNull);
        expect(appState.getOutfitForDate(date3)?.id, equals(outfit3.id));
      });

      test('selected date and assigned outfits are independent', () {
        final outfit = appState.allOutfits.first;
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 16);

        // Select date1 and assign outfit
        appState.selectDate(date1);
        appState.assignOutfitToDate(outfit.id, date1);
        expect(appState.selectedDate, equals(date1));
        expect(appState.getOutfitForDate(date1)?.id, equals(outfit.id));

        // Change selected date - assignment should persist
        appState.selectDate(date2);
        expect(appState.selectedDate, equals(date2));
        expect(appState.getOutfitForDate(date1)?.id, equals(outfit.id));
        expect(appState.getOutfitForDate(date2), isNull);
      });
    });
  });
}
