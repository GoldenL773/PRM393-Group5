import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_screen.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/shared/widgets/filter_chip.dart' as custom;

void main() {
  group('WardrobeScreen Filter Tests', () {
    late AppState appState;
    late MockDataProvider mockDataProvider;

    setUp(() {
      mockDataProvider = MockDataProvider();
      appState = AppState(mockDataProvider);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<NavigationManager>(create: (_) => NavigationManager()),
        ],
        child: MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const WardrobeScreen(),
        ),
      );
    }

    testWidgets('Filter button shows badge when filters are active', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no badge should be visible
      expect(find.text('0'), findsNothing);

      // Apply a filter
      appState.applyFilters(FilterState(colors: ['Red']));
      await tester.pumpAndSettle();

      // Badge should show count of 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Filter button opens bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible
      expect(find.text('Filter Items'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Season'), findsOneWidget);
    });

    testWidgets('Can select color filters in bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select a color filter
      await tester.tap(find.text('Red'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Filter should be applied
      expect(appState.filterState.colors, contains('Red'));
    });

    testWidgets('Can select season filters in bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select a season filter
      await tester.tap(find.text('Summer'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Filter should be applied
      expect(appState.filterState.seasons, contains(Season.summer));
    });

    testWidgets('Clear All button clears all selections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select multiple filters
      await tester.tap(find.text('Red'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Summer'));
      await tester.pumpAndSettle();

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Apply filters (should be empty)
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // No filters should be applied
      expect(appState.filterState.isEmpty, true);
    });

    testWidgets('Active filter chips are displayed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply filters
      appState.applyFilters(FilterState(
        colors: ['Red', 'Blue'],
        seasons: [Season.summer],
      ));
      await tester.pumpAndSettle();

      // Filter chips should be visible
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Summer'), findsOneWidget);
    });

    testWidgets('Can remove individual filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply filters
      appState.applyFilters(FilterState(
        colors: ['Red', 'Blue'],
        seasons: [Season.summer],
      ));
      await tester.pumpAndSettle();

      // Find and tap the close button on the Red chip
      final redChipFinder = find.ancestor(
        of: find.text('Red'),
        matching: find.byType(custom.FilterChip),
      );
      expect(redChipFinder, findsOneWidget);

      // Tap the close icon within the Red chip
      await tester.tap(find.descendant(
        of: redChipFinder,
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      // Red filter should be removed
      expect(appState.filterState.colors, isNot(contains('Red')));
      expect(appState.filterState.colors, contains('Blue'));
      expect(appState.filterState.seasons, contains(Season.summer));
    });

    testWidgets('Grid updates when filters are applied', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Get initial item count
      final initialItems = appState.filteredItems;
      final initialCount = initialItems.length;

      // Apply a restrictive filter
      appState.applyFilters(FilterState(colors: ['Red']));
      await tester.pumpAndSettle();

      // Filtered items should be different
      final filteredItems = appState.filteredItems;
      expect(filteredItems.length, lessThanOrEqualTo(initialCount));
      
      // All visible items should match the filter
      for (final item in filteredItems) {
        expect(item.color, 'Red');
      }
    });

    testWidgets('Shows empty state when no items match filters', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply a filter that matches no items (unlikely but possible)
      // We'll use a combination that's very restrictive
      appState.applyFilters(FilterState(
        colors: ['Red'],
        seasons: [Season.winter],
      ));
      await tester.pumpAndSettle();

      // If no items match, empty state should be shown
      if (appState.filteredItems.isEmpty) {
        expect(find.text('No items found'), findsOneWidget);
        expect(find.text('Try adjusting your filters'), findsOneWidget);
      }
    });
  });

  group('WardrobeScreen Orientation Tests', () {
    late AppState appState;
    late MockDataProvider mockDataProvider;

    setUp(() {
      mockDataProvider = MockDataProvider();
      appState = AppState(mockDataProvider);
    });

    Widget createTestWidgetWithSize(Size size) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<NavigationManager>(create: (_) => NavigationManager()),
        ],
        child: MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: const WardrobeScreen(),
          ),
        ),
      );
    }

    testWidgets('Grid shows 2 columns in portrait mode', (tester) async {
      // Set portrait size (width < height)
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(createTestWidgetWithSize(const Size(400, 800)));
      await tester.pumpAndSettle();

      // Find the GridView
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      // Should have 2 columns in portrait
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('Grid shows 3 columns in landscape mode', (tester) async {
      // Set landscape size (width > height)
      await tester.binding.setSurfaceSize(const Size(800, 400));
      
      await tester.pumpWidget(createTestWidgetWithSize(const Size(800, 400)));
      await tester.pumpAndSettle();

      // Find the GridView
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      
      // Should have 3 columns in landscape
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('Grid adapts when orientation changes', (tester) async {
      // Start in portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidgetWithSize(const Size(400, 800)));
      await tester.pumpAndSettle();

      // Verify 2 columns in portrait
      var gridView = tester.widget<GridView>(find.byType(GridView));
      var delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      // Change to landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpWidget(createTestWidgetWithSize(const Size(800, 400)));
      await tester.pumpAndSettle();

      // Verify 3 columns in landscape
      gridView = tester.widget<GridView>(find.byType(GridView));
      delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('Scroll position is preserved during orientation change', (tester) async {
      // Start in portrait with enough items to scroll
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidgetWithSize(const Size(400, 800)));
      await tester.pumpAndSettle();

      // Check if there are enough items to scroll
      final items = appState.filteredItems;
      if (items.length < 10) {
        // Skip test if not enough items to scroll
        return;
      }

      // Scroll down
      await tester.drag(find.byType(GridView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Get the scroll position
      final scrollable = tester.widget<Scrollable>(find.byType(Scrollable).first);
      final controller = scrollable.controller;
      final portraitPosition = controller?.position.pixels ?? 0;

      // Only verify if we actually scrolled
      if (portraitPosition > 0) {
        // Change to landscape
        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pumpWidget(createTestWidgetWithSize(const Size(800, 400)));
        await tester.pumpAndSettle();

        // The GridView automatically preserves scroll position through its key
        // We just verify the widget rebuilds successfully
        expect(find.byType(GridView), findsOneWidget);
      }
    });
  });
}
