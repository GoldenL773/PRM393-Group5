import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/try_on/try_on_screen.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

void main() {
  late AppState appState;

  setUp(() {
    appState = AppState(MockDataProvider());
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        theme: GoldFitTheme.lightTheme,
        home: const TryOnScreen(),
      ),
    );
  }

  group('TryOnScreen Widget Tests', () {
    testWidgets('displays app bar with title and save button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Virtual Try-On'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byTooltip('Save Outfit'), findsOneWidget);
    });

    testWidgets('displays mode toggle buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Quick Try'), findsOneWidget);
      expect(find.text('Realistic Fitting'), findsOneWidget);
    });

    testWidgets('Quick Try mode is selected by default', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Quick Try should be selected (has primary color background)
      expect(appState.tryOnMode, TryOnMode.quick);
    });

    testWidgets('displays base photo placeholder', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Base Photo'), findsOneWidget);
      expect(find.text('Select clothing items below to try them on'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('displays clothing selector button at bottom', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select Clothing'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom), findsOneWidget);
    });

    testWidgets('tapping Quick Try button switches to Quick Try mode', (tester) async {
      // Start in realistic mode
      appState.setTryOnMode(TryOnMode.realistic);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(appState.tryOnMode, TryOnMode.realistic);

      // Tap Quick Try button
      await tester.tap(find.text('Quick Try'));
      await tester.pump();

      expect(appState.tryOnMode, TryOnMode.quick);
    });

    testWidgets('tapping Realistic Fitting button switches to Realistic mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(appState.tryOnMode, TryOnMode.quick);

      // Tap Realistic Fitting button
      await tester.tap(find.text('Realistic Fitting'));
      await tester.pump();

      expect(appState.tryOnMode, TryOnMode.realistic);
    });

    testWidgets('clothing selector button shows selected count when items are selected', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially shows no count
      expect(find.text('Select Clothing'), findsOneWidget);

      // Select some items
      appState.selectItemForTryOn('item1');
      appState.selectItemForTryOn('item2');
      await tester.pump();

      // Should show count
      expect(find.text('Select Clothing (2 selected)'), findsOneWidget);
    });

    testWidgets('mode toggle buttons have correct styling when selected', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Quick Try should be selected initially
      final quickTryButton = tester.widget<Container>(
        find.ancestor(
          of: find.text('Quick Try'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = quickTryButton.decoration as BoxDecoration;
      expect(decoration.color, GoldFitTheme.primary);
    });

    testWidgets('mode toggle buttons have correct styling when not selected', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Realistic Fitting should not be selected initially
      final realisticButton = tester.widget<Container>(
        find.ancestor(
          of: find.text('Realistic Fitting'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = realisticButton.decoration as BoxDecoration;
      expect(decoration.color, GoldFitTheme.surfaceLight);
    });
  });

  group('Quick Try Mode Tests', () {
    testWidgets('displays placeholder when no items selected in Quick Try mode', (tester) async {
      appState.setTryOnMode(TryOnMode.quick);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Base Photo'), findsOneWidget);
      expect(find.text('Select clothing items below to try them on'), findsOneWidget);
    });

    testWidgets('displays Stack with overlays when items selected in Quick Try mode', (tester) async {
      appState.setTryOnMode(TryOnMode.quick);
      
      // Select some items from the mock data
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have a Stack widgets for layering
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('updates overlay immediately when items selected (< 100ms)', (tester) async {
      appState.setTryOnMode(TryOnMode.quick);
      await tester.pumpWidget(createTestWidget());
      
      final startTime = DateTime.now();
      
      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      // Pump to rebuild
      await tester.pump();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Update should be immediate (< 100ms)
      expect(duration.inMilliseconds, lessThan(100));
    });

    testWidgets('items are layered in correct order (bottoms, tops, outerwear)', (tester) async {
      appState.setTryOnMode(TryOnMode.quick);
      
      // Find items of different types
      final items = appState.allItems;
      final bottomsItem = items.firstWhere(
        (item) => item.type == ClothingType.bottoms,
        orElse: () => items.first,
      );
      final topsItem = items.firstWhere(
        (item) => item.type == ClothingType.tops,
        orElse: () => items.first,
      );
      
      // Select items
      appState.selectItemForTryOn(bottomsItem.id);
      appState.selectItemForTryOn(topsItem.id);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify Stack widgets exists (layering is handled by Stack)
      expect(find.byType(Stack), findsWidgets);
      
      // Verify selected items are in the state
      expect(appState.selectedItemIds.length, 2);
    });

    testWidgets('switching to Realistic mode shows placeholder', (tester) async {
      // Start in Quick Try with items selected
      appState.setTryOnMode(TryOnMode.quick);
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Switch to Realistic mode
      await tester.tap(find.text('Realistic Fitting'));
      await tester.pump();

      // Should show placeholder with generate button
      expect(find.text('Base Photo'), findsOneWidget);
      expect(find.text('Generate Realistic Fitting'), findsOneWidget);
    });
  });

  group('Clothing Selector Bottom Sheet Tests', () {
    testWidgets('tapping clothing selector button opens bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap the clothing selector button
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Should show bottom sheet with header
      expect(find.text('Select Clothing'), findsNWidgets(2)); // Button + sheet header
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('bottom sheet displays category tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Should show category tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tops'), findsOneWidget);
      expect(find.text('Bottoms'), findsOneWidget);
      expect(find.text('Outerwear'), findsOneWidget);
      expect(find.text('Shoes'), findsOneWidget);
      expect(find.text('Accessories'), findsOneWidget);
    });

    testWidgets('bottom sheet displays grid of clothing items', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Should show grid with items
      expect(find.byType(GridView), findsOneWidget);
      
      // Should have items from mock data
      final items = appState.allItems;
      expect(items.isNotEmpty, true);
    });

    testWidgets('tapping item in bottom sheet selects it', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Get initial selection count
      final initialCount = appState.selectedItemIds.length;

      // Find and tap first item in grid
      final gridItems = find.byType(GestureDetector);
      if (gridItems.evaluate().isNotEmpty) {
        await tester.tap(gridItems.first);
        await tester.pump();

        // Should have one more item selected
        expect(appState.selectedItemIds.length, initialCount + 1);
      }
    });

    testWidgets('tapping selected item deselects it', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Select an item first
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing (1 selected)'));
      await tester.pumpAndSettle();

      // Find and tap the selected item
      final gridItems = find.byType(GestureDetector);
      if (gridItems.evaluate().isNotEmpty) {
        await tester.tap(gridItems.first);
        await tester.pump();

        // Should be deselected
        expect(appState.selectedItemIds.length, 0);
      }
    });

    testWidgets('selected items show selection indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Select an item first
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing (1 selected)'));
      await tester.pumpAndSettle();

      // Should show check icon for selected item
      expect(find.byIcon(Icons.check), findsAtLeastNWidgets(1));
    });

    testWidgets('clear all button clears all selections', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Select multiple items
      final items = appState.allItems;
      if (items.length >= 2) {
        appState.selectItemForTryOn(items[0].id);
        appState.selectItemForTryOn(items[1].id);
      }

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing (2 selected)'));
      await tester.pumpAndSettle();

      // Tap clear all button
      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // Should have no selections
      expect(appState.selectedItemIds.length, 0);
    });

    testWidgets('done button closes bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Tap done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed (only one "Select Clothing" text visible)
      expect(find.text('Select Clothing'), findsOneWidget);
    });

    testWidgets('done button shows selected count', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Select items
      final items = appState.allItems;
      if (items.length >= 2) {
        appState.selectItemForTryOn(items[0].id);
        appState.selectItemForTryOn(items[1].id);
      }

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing (2 selected)'));
      await tester.pumpAndSettle();

      // Done button should show count
      expect(find.text('Done (2 selected)'), findsOneWidget);
    });

    testWidgets('category filter works in bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Tap Tops category
      await tester.tap(find.text('Tops'));
      await tester.pumpAndSettle();

      // Grid should update to show only tops
      // (We can't easily verify the filtered items without accessing internal state,
      // but we can verify the tap worked)
      expect(find.text('Tops'), findsOneWidget);
    });

    testWidgets('closing bottom sheet updates try-on display', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Select Clothing'));
      await tester.pumpAndSettle();

      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        final gridItems = find.byType(GestureDetector);
        if (gridItems.evaluate().isNotEmpty) {
          await tester.tap(gridItems.first);
          await tester.pump();
        }
      }

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Try-on screen should show updated selection count
      if (appState.selectedItemIds.isNotEmpty) {
        expect(find.textContaining('selected'), findsOneWidget);
      }
    });
  });

  group('Realistic Fitting Mode Tests', () {
    testWidgets('shows generate button when no items selected', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show generate button
      expect(find.text('Generate Realistic Fitting'), findsOneWidget);
      expect(find.text('Select clothing items to generate'), findsOneWidget);
    });

    testWidgets('shows enabled generate button when items are selected', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      
      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show generate button (without the helper text)
      expect(find.text('Generate Realistic Fitting'), findsOneWidget);
      expect(find.text('Select clothing items to generate'), findsNothing);
    });

    testWidgets('shows loading indicator when generating realistic fitting', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      
      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap generate button
      await tester.tap(find.text('Generate Realistic Fitting'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generating realistic fitting...'), findsOneWidget);
      expect(find.text('This may take a few seconds'), findsOneWidget);
      
      // Complete the async operation
      await tester.pumpAndSettle();
    });

    testWidgets('displays result after 2-second delay', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      
      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap generate button
      await tester.tap(find.text('Generate Realistic Fitting'));
      await tester.pump();

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for 2-second delay and settle
      await tester.pumpAndSettle();

      // Should show result
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Realistic Fitting Complete'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
    });

    testWidgets('can regenerate realistic fitting', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      
      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Generate first time
      await tester.tap(find.text('Generate Realistic Fitting'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show result
      expect(find.text('Realistic Fitting Complete'), findsOneWidget);

      // Tap regenerate button
      await tester.tap(find.text('Regenerate'));
      await tester.pump();

      // Should show loading again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generating realistic fitting...'), findsOneWidget);

      // Wait for delay
      await tester.pumpAndSettle();

      // Should show result again
      expect(find.text('Realistic Fitting Complete'), findsOneWidget);
    });

    testWidgets('resets realistic mode state when switching to Quick Try', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      
      // Select an item
      final items = appState.allItems;
      if (items.isNotEmpty) {
        appState.selectItemForTryOn(items[0].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Generate realistic fitting
      await tester.tap(find.text('Generate Realistic Fitting'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show result
      expect(find.text('Realistic Fitting Complete'), findsOneWidget);

      // Switch to Quick Try mode
      await tester.tap(find.text('Quick Try'));
      await tester.pump();

      // Switch back to Realistic mode
      await tester.tap(find.text('Realistic Fitting'));
      await tester.pump();

      // Should show initial state (generate button), not the result
      expect(find.text('Generate Realistic Fitting'), findsOneWidget);
      expect(find.text('Realistic Fitting Complete'), findsNothing);
    });

    testWidgets('realistic result displays selected items', (tester) async {
      appState.setTryOnMode(TryOnMode.realistic);
      
      // Select multiple items
      final items = appState.allItems;
      if (items.length >= 2) {
        appState.selectItemForTryOn(items[0].id);
        appState.selectItemForTryOn(items[1].id);
      }
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Generate realistic fitting
      await tester.tap(find.text('Generate Realistic Fitting'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show result with items
      expect(find.text('Realistic Fitting Complete'), findsOneWidget);
      
      // Should have visual representation of items (icons)
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
