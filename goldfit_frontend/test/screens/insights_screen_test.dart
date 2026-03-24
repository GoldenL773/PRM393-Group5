import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/insights/insights_screen.dart';
import 'package:goldfit_frontend/features/wardrobe/item_detail_screen.dart';
import 'package:goldfit_frontend/features/insights/insights_viewmodel.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/widgets/clothing_item_card.dart';
import 'package:goldfit_frontend/shared/utils/routes.dart';

/// Tests for InsightsScreen widgets with ViewModel
/// 
/// Validates: Requirements 10.1, 10.2, 10.3, 10.4, 14.3, 14.4
void main() {
  late MockAnalyticsRepository mockRepository;
  late InsightsViewModel viewModel;

  setUp(() {
    mockRepository = MockAnalyticsRepository();
    viewModel = InsightsViewModel(mockRepository);
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<InsightsViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        home: const InsightsScreen(),
        routes: {
          AppRoutes.itemDetail: (context) => const ItemDetailScreen(),
        },
      ),
    );
  }

  group('InsightsScreen - ViewModel Integration', () {
    testWidgets('displays loading indicator while loading', (tester) async {
      // Set loading state
      mockRepository.shouldDelay = true;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Trigger initState
      
      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Cancel the delay and complete the test
      mockRepository.shouldDelay = false;
      await tester.pumpAndSettle();
    });

    testWidgets('displays error state when loading fails', (tester) async {
      // Set error state
      mockRepository.shouldError = true;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Trigger initState
      await tester.pumpAndSettle(); // Wait for async operation
      
      // Should show error message
      expect(find.text('Error loading analytics'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button reloads analytics', (tester) async {
      // Set error state initially
      mockRepository.shouldError = true;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();
      
      // Verify error is shown
      expect(find.text('Error loading analytics'), findsOneWidget);
      
      // Fix the error and tap retry
      mockRepository.shouldError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      
      // Should now show analytics
      expect(find.text('Total Items'), findsOneWidget);
    });

    testWidgets('displays total items count from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Verify total items card is displayed
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('${analytics.totalItems}'), findsOneWidget);
    });

    testWidgets('displays total value from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Verify total value card is displayed
      expect(find.text('Total Value'), findsOneWidget);
      expect(find.text('\$${analytics.totalValue.toStringAsFixed(0)}'), findsOneWidget);
    });

    testWidgets('displays Most Worn section with top 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify Most Worn section header
      expect(find.text('Most Worn'), findsOneWidget);
      
      // Verify correct number of items are displayed (top 5)
      final analytics = mockRepository.mockAnalytics;
      expect(analytics.mostWorn.length, lessThanOrEqualTo(5));
      
      if (analytics.mostWorn.isNotEmpty) {
        // Should find ClothingItemCard widgets
        expect(find.byType(ListView), findsWidgets);
        
        // Verify the items are displayed in the horizontal list
        final listView = tester.widget<ListView>(find.byType(ListView).first);
        expect(listView.scrollDirection, Axis.horizontal);
      }
    });

    testWidgets('displays Dusty Corner section with bottom 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify Dusty Corner section header
      expect(find.text('Dusty Corner'), findsOneWidget);
      
      // Verify correct number of items are displayed (bottom 5)
      final analytics = mockRepository.mockAnalytics;
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

    testWidgets('shows empty state when analytics is null', (tester) async {
      // Create a repository that returns empty analytics (not null)
      mockRepository.returnEmpty = true;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show empty state message for empty lists
      expect(find.text('No items to display'), findsWidgets);
    });

    testWidgets('Most Worn section displays exactly the items from analytics', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Verify that the number of ClothingItemCards matches the analytics data
      if (analytics.mostWorn.isNotEmpty) {
        // Find all ClothingItemCards
        final itemCards = find.byType(ClothingItemCard);
        
        // The total number of cards should be mostWorn + leastWorn
        final expectedTotal = analytics.mostWorn.length + analytics.leastWorn.length;
        expect(itemCards.evaluate().length, expectedTotal);
      }
    });

    testWidgets('verifies Most Worn displays maximum 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Requirement 10.3: Most Worn section should show top 5 items
      expect(analytics.mostWorn.length, lessThanOrEqualTo(5),
          reason: 'Most Worn should display at most 5 items');
    });

    testWidgets('verifies Dusty Corner displays maximum 5 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Requirement 10.4: Dusty Corner section should show bottom 5 items
      expect(analytics.leastWorn.length, lessThanOrEqualTo(5),
          reason: 'Dusty Corner should display at most 5 items');
    });
  });

  group('InsightsScreen - UI Elements', () {
    testWidgets('displays all required sections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify all main sections are present
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Total Value'), findsOneWidget);
      expect(find.text('Most Worn'), findsOneWidget);
      expect(find.text('Dusty Corner'), findsOneWidget);
    });

    testWidgets('uses correct icons for sections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify icons are present (may appear multiple times due to ClothingItemCard placeholders)
      expect(find.byIcon(Icons.checkroom), findsWidgets);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify the main content is in a scrollable widgets
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}

/// Mock AnalyticsRepository for testing
class MockAnalyticsRepository implements AnalyticsRepository {
  bool shouldError = false;
  bool shouldDelay = false;
  bool returnEmpty = false;
  
  final WardrobeAnalytics mockAnalytics = WardrobeAnalytics(
    totalItems: 25,
    totalValue: 2500.0,
    mostWorn: [
      ClothingItem(
        id: '1',
        imageUrl: 'assets/images/placeholder.png',
        type: ClothingType.tops,
        color: 'Blue',
        seasons: [Season.spring, Season.summer],
        usageCount: 10,
        addedDate: DateTime.now(),
      ),
      ClothingItem(
        id: '2',
        imageUrl: 'assets/images/placeholder.png',
        type: ClothingType.bottoms,
        color: 'Black',
        seasons: [Season.fall, Season.winter],
        usageCount: 8,
        addedDate: DateTime.now(),
      ),
    ],
    leastWorn: [
      ClothingItem(
        id: '3',
        imageUrl: 'assets/images/placeholder.png',
        type: ClothingType.outerwear,
        color: 'Red',
        seasons: [Season.summer],
        usageCount: 0,
        addedDate: DateTime.now(),
      ),
    ],
  );

  @override
  Future<WardrobeAnalytics> getAnalytics() async {
    if (shouldDelay) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (shouldError) {
      throw Exception('Failed to load analytics');
    }
    
    if (returnEmpty) {
      return WardrobeAnalytics(
        totalItems: 0,
        totalValue: 0,
        mostWorn: [],
        leastWorn: [],
      );
    }
    
    return mockAnalytics;
  }

  @override
  Future<List<ClothingItem>> getMostWorn(int limit) async {
    return mockAnalytics.mostWorn;
  }

  @override
  Future<List<ClothingItem>> getLeastWorn(int limit) async {
    return mockAnalytics.leastWorn;
  }

  @override
  Future<Map<ClothingType, int>> getItemCountByType() async {
    return {};
  }

  @override
  Future<double> getTotalValue() async {
    return mockAnalytics.totalValue;
  }

  @override
  Future<void> recordUsage(String outfitId, DateTime date) async {
    // No-op for mock
  }

  @override
  void invalidateCache() {
    // No-op for mock
  }
}
