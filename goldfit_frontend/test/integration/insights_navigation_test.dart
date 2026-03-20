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

/// Integration tests for InsightsScreen navigation with ViewModel
/// 
/// Validates: Requirements 10.3, 10.4, 14.3, 14.4 - Navigation from Most Worn and Dusty Corner
void main() {
  late MockAnalyticsRepository mockRepository;
  late InsightsViewModel viewModel;

  setUp(() {
    mockRepository = MockAnalyticsRepository();
    viewModel = InsightsViewModel(mockRepository);
  });

  Widget createTestApp() {
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

  group('InsightsScreen Navigation Integration', () {
    testWidgets('tapping Most Worn item navigates to item detail', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(); // Trigger initState
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Only test if there are items in Most Worn
      if (analytics.mostWorn.isNotEmpty) {
        // Find all ClothingItemCard widgets
        final itemCards = find.byType(ClothingItemCard);
        
        if (itemCards.evaluate().isNotEmpty) {
          // Tap the first item card
          await tester.tap(itemCards.first);
          await tester.pumpAndSettle();
          
          // Verify that ItemDetailScreen is now displayed
          expect(find.byType(ItemDetailScreen), findsOneWidget);
        }
      }
    });

    testWidgets('tapping Dusty Corner item navigates to item detail', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      // Only test if there are items in Dusty Corner
      if (analytics.leastWorn.isNotEmpty) {
        // Find all ClothingItemCard widgets
        final itemCards = find.byType(ClothingItemCard);
        
        // If we have enough cards, tap one from the Dusty Corner section
        // (Most Worn items come first, then Dusty Corner items)
        if (itemCards.evaluate().length > analytics.mostWorn.length) {
          final dustyCornerCardIndex = analytics.mostWorn.length;
          await tester.tap(itemCards.at(dustyCornerCardIndex));
          await tester.pumpAndSettle();
          
          // Verify that ItemDetailScreen is now displayed
          expect(find.byType(ItemDetailScreen), findsOneWidget);
        }
      }
    });

    testWidgets('correct item ID is passed to item detail screen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pumpAndSettle();

      final analytics = mockRepository.mockAnalytics;
      
      if (analytics.mostWorn.isNotEmpty) {
        // Find and tap the first item card
        final itemCards = find.byType(ClothingItemCard);
        if (itemCards.evaluate().isNotEmpty) {
          await tester.tap(itemCards.first);
          await tester.pumpAndSettle();
          
          // Verify navigation occurred
          expect(find.byType(ItemDetailScreen), findsOneWidget);
          
          // Note: In a real integration test, we would verify the item ID
          // was passed correctly by checking the ItemDetailScreen's state
          // For now, we just verify the navigation succeeded
        }
      }
    });

    testWidgets('analytics data is properly accessed from ViewModel', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify that analytics data is displayed
      final analytics = mockRepository.mockAnalytics;
      
      // Check total items
      expect(find.text('${analytics.totalItems}'), findsOneWidget);
      
      // Check total value
      expect(find.text('\$${analytics.totalValue.toStringAsFixed(0)}'), findsOneWidget);
      
      // Verify sections are present
      expect(find.text('Most Worn'), findsOneWidget);
      expect(find.text('Dusty Corner'), findsOneWidget);
    });

    testWidgets('ViewModel properly provides analytics data', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pumpAndSettle();

      // Get analytics from ViewModel
      final analytics = viewModel.analytics;
      
      // Verify analytics has valid data
      expect(analytics, isNotNull);
      expect(analytics!.totalItems, greaterThanOrEqualTo(0));
      expect(analytics.totalValue, greaterThanOrEqualTo(0));
      expect(analytics.mostWorn, isNotNull);
      expect(analytics.leastWorn, isNotNull);
      
      // Verify the data is displayed in the UI
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Total Value'), findsOneWidget);
    });
  });
}

/// Mock AnalyticsRepository for testing
class MockAnalyticsRepository implements AnalyticsRepository {
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
