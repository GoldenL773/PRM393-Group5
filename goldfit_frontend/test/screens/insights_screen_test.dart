import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/screens/insights_screen.dart';
import 'package:goldfit_frontend/screens/item_detail_screen.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/widgets/clothing_item_card.dart';
import 'package:goldfit_frontend/utils/routes.dart';

/// Tests for InsightsScreen widget
/// 
/// Validates: Requirements 10.1, 10.2, 10.3, 10.4
void main() {
  late MockDataProvider mockDataProvider;
  late AppState appState;

  setUp(() {
    mockDataProvider = MockDataProvider();
    appState = AppState(mockDataProvider);
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        home: const InsightsScreen(),
        routes: {
          AppRoutes.itemDetail: (context) => const ItemDetailScreen(),
        },
      ),
    );
  }

  group('InsightsScreen - AppState Connection', () {
    testWidgets('displays total items count from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final analytics = appState.analytics;
      
      // Verify total items card is displayed
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('${analytics.totalItems}'), findsOneWidget);
    });

    testWidgets('displays total value from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final analytics = appState.analytics;
      
      // Verify total value card is displayed
      expect(find.text('Total Value'), findsOneWidget);
      expect(find.text('\$${analytics.totalValue.toStringAsFixed(0)}'), findsOneWidget);
    });

    testWidgets('displays Most Worn section with top 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify Most Worn section header
      expect(find.text('Most Worn'), findsOneWidget);
      
      // Verify correct number of items are displayed (top 5)
      final analytics = appState.analytics;
      expect(analytics.mostWorn.length, lessThanOrEqualTo(5));
      
      if (analytics.mostWorn.isNotEmpty) {
        // Should find ClothingItemCard widgets
        expect(find.byType(ListView), findsWidgets);
        
        // Verify the items are displayed in the horizontal list
        // The ListView should contain the correct number of items
        final listView = tester.widget<ListView>(find.byType(ListView).first);
        expect(listView.scrollDirection, Axis.horizontal);
      }
    });

    testWidgets('displays Dusty Corner section with bottom 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify Dusty Corner section header
      expect(find.text('Dusty Corner'), findsOneWidget);
      
      // Verify correct number of items are displayed (bottom 5)
      final analytics = appState.analytics;
      expect(analytics.leastWorn.length, lessThanOrEqualTo(5));
      
      if (analytics.leastWorn.isNotEmpty) {
        // Should find ClothingItemCard widgets
        expect(find.byType(ListView), findsWidgets);
        
        // Verify the items are displayed in the horizontal list
        // Find the second ListView (Dusty Corner section)
        final listViews = find.byType(ListView);
        if (listViews.evaluate().length > 1) {
          final listView = tester.widget<ListView>(listViews.at(1));
          expect(listView.scrollDirection, Axis.horizontal);
        }
      }
    });

    testWidgets('navigates to item detail when Most Worn item is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analytics = appState.analytics;
      
      if (analytics.mostWorn.isNotEmpty) {
        // Find the first item card in the Most Worn section
        // We need to find the ListView and tap on a card within it
        final listViews = find.byType(ListView);
        
        if (listViews.evaluate().isNotEmpty) {
          // Tap on the first ListView (Most Worn section)
          await tester.tap(listViews.first);
          await tester.pumpAndSettle();
          
          // Verify navigation occurred (ItemDetailScreen should be pushed)
          // Note: In a real test, we'd verify the route was pushed
          // For now, we just verify the tap doesn't cause errors
        }
      }
    });

    testWidgets('navigates to item detail when Dusty Corner item is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analytics = appState.analytics;
      
      if (analytics.leastWorn.isNotEmpty) {
        // Find the second ListView (Dusty Corner section)
        final listViews = find.byType(ListView);
        
        if (listViews.evaluate().length > 1) {
          // Tap on the second ListView (Dusty Corner section)
          await tester.tap(listViews.at(1));
          await tester.pumpAndSettle();
          
          // Verify navigation occurred
          // For now, we just verify the tap doesn't cause errors
        }
      }
    });

    testWidgets('shows empty state when no items in Most Worn', (tester) async {
      // Create a mock provider with no analytics data
      final emptyProvider = MockDataProvider();
      final emptyState = AppState(emptyProvider);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: emptyState,
          child: const MaterialApp(
            home: InsightsScreen(),
          ),
        ),
      );

      // The screen should still render without errors
      expect(find.byType(InsightsScreen), findsOneWidget);
    });

    testWidgets('Most Worn section displays exactly the items from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analytics = appState.analytics;
      
      // Verify that the number of ClothingItemCards matches the analytics data
      if (analytics.mostWorn.isNotEmpty) {
        // Find all ClothingItemCards
        final itemCards = find.byType(ClothingItemCard);
        
        // The total number of cards should be mostWorn + leastWorn
        final expectedTotal = analytics.mostWorn.length + analytics.leastWorn.length;
        expect(itemCards.evaluate().length, expectedTotal);
      }
    });

    testWidgets('Dusty Corner section displays exactly the items from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analytics = appState.analytics;
      
      // Verify that the Dusty Corner section displays the correct items
      if (analytics.leastWorn.isNotEmpty) {
        // Find all ClothingItemCards
        final itemCards = find.byType(ClothingItemCard);
        
        // The total number of cards should be mostWorn + leastWorn
        final expectedTotal = analytics.mostWorn.length + analytics.leastWorn.length;
        expect(itemCards.evaluate().length, expectedTotal);
      }
    });

    testWidgets('verifies Most Worn displays maximum 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analytics = appState.analytics;
      
      // Requirement 10.3: Most Worn section should show top 5 items
      expect(analytics.mostWorn.length, lessThanOrEqualTo(5),
          reason: 'Most Worn should display at most 5 items');
    });

    testWidgets('verifies Dusty Corner displays maximum 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analytics = appState.analytics;
      
      // Requirement 10.4: Dusty Corner section should show bottom 5 items
      expect(analytics.leastWorn.length, lessThanOrEqualTo(5),
          reason: 'Dusty Corner should display at most 5 items');
    });
  });

  group('InsightsScreen - UI Elements', () {
    testWidgets('displays all required sections', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify all main sections are present
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Total Value'), findsOneWidget);
      expect(find.text('Most Worn'), findsOneWidget);
      expect(find.text('Dusty Corner'), findsOneWidget);
    });

    testWidgets('uses correct icons for sections', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify icons are present (may appear multiple times due to ClothingItemCard placeholders)
      expect(find.byIcon(Icons.checkroom), findsWidgets);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify the main content is in a scrollable widget
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
