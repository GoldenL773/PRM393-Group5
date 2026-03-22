import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/core/routing/app_shell.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 2: State Preservation Across Transitions', () {
    testWidgets('AppState preserves filter selections across navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Apply filters
      final filterState = FilterState(
        colors: ['red', 'blue'],
        seasons: [Season.spring, Season.summer],
      );
      appState.applyFilters(filterState);
      await tester.pumpAndSettle();

      // Navigate to Try-On screen
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Try-On'), findsOneWidget);

      // Navigate back to Wardrobe
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsOneWidget);

      // Verify filter state is preserved
      expect(appState.filterState.colors, equals(['red', 'blue']),
          reason: 'Filter colors should be preserved across navigation');
      expect(appState.filterState.seasons, equals([Season.spring, Season.summer]),
          reason: 'Filter seasons should be preserved across navigation');
    });

    testWidgets('AppState preserves category selection across navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Select a category
      appState.selectCategory(ClothingType.tops);
      await tester.pumpAndSettle();

      // Navigate to Home screen
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Navigate back to Wardrobe
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsOneWidget);

      // Verify category selection is preserved
      expect(appState.selectedCategory, equals(ClothingType.tops),
          reason: 'Category selection should be preserved across navigation');
    });

    testWidgets('AppState preserves try-on mode across navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Navigate to Try-On screen
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Toggle try-on mode
      appState.toggleTryOnMode();
      await tester.pumpAndSettle();
      final modeAfterToggle = appState.tryOnMode;

      // Navigate to Insights
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Insights'), findsOneWidget);

      // Navigate back to Try-On
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Try-On'), findsOneWidget);

      // Verify try-on mode is preserved
      expect(appState.tryOnMode, equals(modeAfterToggle),
          reason: 'Try-on mode should be preserved across navigation');
    });

    testWidgets('AppState preserves selected items for try-on across navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      final items = appState.allItems;
      
      if (items.isEmpty) return;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Select items for try-on
      final selectedIds = items.take(3).map((item) => item.id).toList();
      for (final id in selectedIds) {
        appState.selectItemForTryOn(id);
      }
      await tester.pumpAndSettle();

      // Navigate to Planner
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Planner'), findsOneWidget);

      // Navigate back to Try-On
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Try-On'), findsOneWidget);

      // Verify selected items are preserved
      expect(appState.selectedItemIds, equals(selectedIds),
          reason: 'Selected items for try-on should be preserved across navigation');
    });

    testWidgets('AppState preserves calendar view mode across navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Navigate to Planner
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Toggle calendar view
      appState.toggleCalendarView();
      await tester.pumpAndSettle();
      final viewAfterToggle = appState.calendarView;

      // Navigate to Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Navigate back to Planner
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Planner'), findsOneWidget);

      // Verify calendar view is preserved
      expect(appState.calendarView, equals(viewAfterToggle),
          reason: 'Calendar view mode should be preserved across navigation');
    });

    testWidgets('AppState preserves selected date across navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Navigate to Planner
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Select a date
      final selectedDate = DateTime(2024, 6, 15);
      appState.selectDate(selectedDate);
      await tester.pumpAndSettle();

      // Navigate to Wardrobe
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsOneWidget);

      // Navigate back to Planner
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Planner'), findsOneWidget);

      // Verify selected date is preserved
      expect(appState.selectedDate, equals(selectedDate),
          reason: 'Selected date should be preserved across navigation');
    });

    property('Filter state is preserved across multiple navigation transitions', () {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      forAll(
        filterStateArbitrary(),
        (filterState) { // Removed async here
          testWidgets('Filter state preservation test', (tester) async {
            final mockDataProvider = MockDataProvider();
            final appState = AppState(mockDataProvider);

            await tester.pumpWidget(
              ChangeNotifierProvider<AppState>.value(
                value: appState,
                child: MaterialApp(
                  theme: GoldFitTheme.lightTheme,
                  home: const AppShell(),
                ),
              ),
            );

            // Apply the generated filter state
            appState.applyFilters(filterState);
            await tester.pumpAndSettle();

            // Navigate through multiple screens
            final navigationSequence = [
              Icons.person_outline,      // Try-On
              Icons.calendar_today_outlined, // Planner
              Icons.insights_outlined,   // Insights
              Icons.home_outlined,       // Home
              Icons.checkroom_outlined,  // Back to Wardrobe
            ];

            for (final icon in navigationSequence) {
              await tester.tap(find.byIcon(icon));
              await tester.pumpAndSettle();
            }

            // Verify filter state is still preserved
            expect(appState.filterState.colors, equals(filterState.colors),
                reason: 'Filter colors should be preserved after multiple navigations');
            expect(appState.filterState.seasons, equals(filterState.seasons),
                reason: 'Filter seasons should be preserved after multiple navigations');
          });
        },
      );
    });

    property('Category selection is preserved across multiple navigation transitions', () {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      forAll(
        categoryArbitrary(),
        (category) { // Removed async here
          testWidgets('Category selection preservation test', (tester) async {
            final mockDataProvider = MockDataProvider();
            final appState = AppState(mockDataProvider);

            await tester.pumpWidget(
              ChangeNotifierProvider<AppState>.value(
                value: appState,
                child: MaterialApp(
                  theme: GoldFitTheme.lightTheme,
                  home: const AppShell(),
                ),
              ),
            );

            // Select the generated category
            appState.selectCategory(category);
            await tester.pumpAndSettle();

            // Navigate through multiple screens
            final navigationSequence = [
              Icons.home_outlined,
              Icons.person_outline,
              Icons.insights_outlined,
              Icons.checkroom_outlined,
            ];

            for (final icon in navigationSequence) {
              await tester.tap(find.byIcon(icon));
              await tester.pumpAndSettle();
            }

            // Verify category selection is still preserved
            expect(appState.selectedCategory, equals(category),
                reason: 'Category selection should be preserved after multiple navigations');
          });
        },
      );
    });

    testWidgets('IndexedStack preserves widget state during navigation', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Verify IndexedStack is used (which preserves state)
      expect(find.byType(IndexedStack), findsOneWidget,
          reason: 'AppShell should use IndexedStack to preserve screen state');

      // Navigate to Wardrobe
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsOneWidget);

      // Navigate to Try-On
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Try-On'), findsOneWidget);

      // Navigate back to Wardrobe
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsOneWidget);

      // IndexedStack keeps all screens in memory, so state is preserved
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.children.length, equals(5),
          reason: 'IndexedStack should maintain all 5 screens');
    });

    testWidgets('State preservation works with orientation changes', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Apply filters and select category
      final filterState = FilterState(
        colors: ['red', 'blue'],
        seasons: [Season.spring],
      );
      appState.applyFilters(filterState);
      appState.selectCategory(ClothingType.tops);
      await tester.pumpAndSettle();

      // Simulate orientation change by rebuilding with different size
      tester.view.physicalSize = const Size(800, 600); // Landscape
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      
      await tester.pumpAndSettle();

      // Verify state is preserved after orientation change
      expect(appState.filterState.colors, equals(['red', 'blue']),
          reason: 'Filter state should be preserved after orientation change');
      expect(appState.selectedCategory, equals(ClothingType.tops),
          reason: 'Category selection should be preserved after orientation change');

      // Change back to portrait
      tester.view.physicalSize = const Size(600, 800); // Portrait
      await tester.pumpAndSettle();

      // Verify state is still preserved
      expect(appState.filterState.colors, equals(['red', 'blue']),
          reason: 'Filter state should be preserved after orientation change back');
      expect(appState.selectedCategory, equals(ClothingType.tops),
          reason: 'Category selection should be preserved after orientation change back');
    });

    property('Try-on selections are preserved across navigation and orientation changes', () {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      forAll(
        integer(min: 1, max: 5),
        (itemCount) { // Removed async here
          testWidgets('Try-on selection preservation test', (tester) async {
            final mockDataProvider = MockDataProvider();
            final appState = AppState(mockDataProvider);
            final items = appState.allItems;
            
            if (items.length < itemCount) return;

            await tester.pumpWidget(
              ChangeNotifierProvider<AppState>.value(
                value: appState,
                child: MaterialApp(
                  theme: GoldFitTheme.lightTheme,
                  home: const AppShell(),
                ),
              ),
            );

            // Select items for try-on
            final selectedIds = items.take(itemCount).map((item) => item.id).toList();
            for (final id in selectedIds) {
              appState.selectItemForTryOn(id);
            }
            await tester.pumpAndSettle();

            // Navigate to different screens
            await tester.tap(find.byIcon(Icons.home_outlined));
            await tester.pumpAndSettle();
            
            await tester.tap(find.byIcon(Icons.insights_outlined));
            await tester.pumpAndSettle();

            // Simulate orientation change
            tester.view.physicalSize = const Size(800, 600);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpAndSettle();

            // Navigate back to Try-On
            await tester.tap(find.byIcon(Icons.person_outline));
            await tester.pumpAndSettle();

            // Verify selections are preserved
            expect(appState.selectedItemIds.length, equals(itemCount),
                reason: 'Number of selected items should be preserved');
            expect(appState.selectedItemIds, equals(selectedIds),
                reason: 'Selected item IDs should be preserved across navigation and orientation changes');
          });
        },
      );
    });

    testWidgets('Multiple state properties are preserved simultaneously', (tester) async {
      // **Validates: Requirements 1.3, 13.4, 15.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      final items = appState.allItems;
      
      if (items.isEmpty) return;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        ),
      );

      // Set multiple state properties
      final filterState = FilterState(
        colors: ['red', 'blue', 'green'],
        seasons: [Season.spring, Season.summer],
      );
      appState.applyFilters(filterState);
      appState.selectCategory(ClothingType.bottoms);
      appState.selectItemForTryOn(items.first.id);
      appState.toggleCalendarView();
      appState.selectDate(DateTime(2024, 7, 20));
      await tester.pumpAndSettle();

      // Navigate through all screens
      final screens = [
        Icons.home_outlined,
        Icons.checkroom_outlined,
        Icons.person_outline,
        Icons.calendar_today_outlined,
        Icons.insights_outlined,
        Icons.checkroom_outlined,
      ];

      for (final icon in screens) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
      }

      // Verify all state properties are preserved
      expect(appState.filterState.colors, equals(['red', 'blue', 'green']),
          reason: 'Filter colors should be preserved');
      expect(appState.filterState.seasons, equals([Season.spring, Season.summer]),
          reason: 'Filter seasons should be preserved');
      expect(appState.selectedCategory, equals(ClothingType.bottoms),
          reason: 'Category selection should be preserved');
      expect(appState.selectedItemIds, contains(items.first.id),
          reason: 'Try-on selections should be preserved');
      expect(appState.selectedDate, equals(DateTime(2024, 7, 20)),
          reason: 'Selected date should be preserved');
    });
  });
}

// ============================================================================
// Arbitrary Generators
// ============================================================================

/// Arbitrary generator for FilterState
Arbitrary<FilterState> filterStateArbitrary() {
  return integer(min: 0, max: 3).flatMap((colorCount) {
    return integer(min: 0, max: 4).flatMap((seasonCount) {
      final availableColors = ['red', 'blue', 'green', 'black', 'white', 'gray', 'brown'];
      final colors = <String>[];
      for (var i = 0; i < colorCount && i < availableColors.length; i++) {
        colors.add(availableColors[i]);
      }

      final seasons = <Season>[];
      final allSeasons = Season.values;
      for (var i = 0; i < seasonCount && i < allSeasons.length; i++) {
        if (!seasons.contains(allSeasons[i])) {
          seasons.add(allSeasons[i]);
        }
      }

      return constant(FilterState(
        colors: colors,
        seasons: seasons,
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
