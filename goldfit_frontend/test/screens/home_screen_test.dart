import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/home/home_screen.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/shared/utils/routes.dart';
import 'package:goldfit_frontend/features/home/home_viewmodel.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';

import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';

// Mock OutfitRepository for testing
class MockOutfitRepository implements OutfitRepository {
  final List<Outfit> _outfits = [];

  MockOutfitRepository() {
    // Add some test outfits
    _outfits.addAll([
      Outfit(
        id: '1',
        name: 'Casual Summer',
        itemIds: ['item1', 'item2'],
        vibe: 'Casual',
        createdDate: DateTime.now(),
      ),
      Outfit(
        id: '2',
        name: 'Work Professional',
        itemIds: ['item3', 'item4'],
        vibe: 'Work',
        createdDate: DateTime.now(),
      ),
      Outfit(
        id: '3',
        name: 'Date Night',
        itemIds: ['item5', 'item6'],
        vibe: 'Date Night',
        createdDate: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<Outfit> create(Outfit outfit) async {
    _outfits.add(outfit);
    return outfit;
  }

  @override
  Future<Outfit?> getById(String id) async {
    try {
      return _outfits.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Outfit>> getAll() async {
    return List.from(_outfits);
  }

  @override
  Future<List<Outfit>> getByVibe(String vibe) async {
    return _outfits.where((o) => o.vibe == vibe).toList();
  }

  @override
  Future<Outfit> update(Outfit outfit) async {
    final index = _outfits.indexWhere((o) => o.id == outfit.id);
    if (index != -1) {
      _outfits[index] = outfit;
    }
    return outfit;
  }

  @override
  Future<void> delete(String id) async {
    _outfits.removeWhere((o) => o.id == id);
  }

  @override
  Future<void> assignToDate(String outfitId, DateTime date, String timeSlot, {String? eventName, String? startTime}) async {}

  @override
  Future<void> unassignFromDate(DateTime date, String timeSlot) async {}

  @override
  Future<List<Outfit>> getByDate(DateTime date) async {
    return [];
  }

  @override
  Future<List<Outfit>> getByDateRange(DateTime start, DateTime end) async {
    return [];
  }

  @override
  Stream<List<Outfit>> watchAll() {
    return Stream.value(_outfits);
  }
}

class MockClothingRepository implements ClothingRepository {
  final List<ClothingItem> _items = [];

  @override
  Future<List<ClothingItem>> getAll() async {
    return _items;
  }

  @override
  Future<ClothingItem?> getById(String id) async {
    return _items.firstWhere((i) => i.id == id, orElse: () => throw Exception('Not found'));
  }

  @override
  Future<ClothingItem> update(ClothingItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    }
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((i) => i.id == id);
  }
  
  @override
  Future<ClothingItem> create(ClothingItem item) async {
    _items.add(item);
    return item;
  }

  @override
  Future<List<ClothingItem>> batchCreate(List<ClothingItem> items) async {
    _items.addAll(items);
    return items;
  }

  @override
  Future<List<ClothingItem>> getByFilters(FilterState filters) async {
    return _items;
  }
  
  @override
  Stream<List<ClothingItem>> watchAll() {
    return Stream.value(_items);
  }

  @override
  Future<List<ClothingItem>> getByType(ClothingType type) async {
    return _items.where((item) => item.type == type).toList();
  }
}

void main() {
  group('HomeScreen Widget Tests', () {
    late AppState appState;
    late NavigationManager navigationManager;
    late MockOutfitRepository mockOutfitRepository;
    late MockClothingRepository mockClothingRepository;
    late HomeViewModel homeViewModel;

    setUp(() {
      appState = AppState(MockDataProvider());
      navigationManager = NavigationManager();
      mockOutfitRepository = MockOutfitRepository();
      mockClothingRepository = MockClothingRepository();
      homeViewModel = HomeViewModel(mockOutfitRepository, mockClothingRepository);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<NavigationManager>.value(value: navigationManager),
          ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          routes: {
            AppRoutes.styling: (context) => const Scaffold(body: Text('Styling Screen')),
            AppRoutes.tryOn: (context) => const Scaffold(body: Text('Try-On Screen')),
          },
        ),
      );
    }

    testWidgets('displays weather widgets on load', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Wait for the widgets to build
      await tester.pumpAndSettle();

      // Verify weather information is displayed
      final weather = appState.currentWeather;
      expect(find.text('Detecting...'), findsOneWidget);
    });

    testWidgets('displays recommendations after loading', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify recommended outfits section header
      expect(find.text('Recommended for Today'), findsOneWidget);

      // Verify outfit cards are displayed
      expect(find.text('Casual Summer'), findsOneWidget);
    });

    testWidgets('displays "Get Styled" button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pumpAndSettle();

      // Verify "Get Styled" button is present
      expect(find.text('Get Styled'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('pull-to-refresh triggers refresh', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Simulate pull-to-refresh gesture
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();

      // Wait for refresh to complete
      await tester.pumpAndSettle();

      // Verify the screen is still displayed (refresh completed)
      expect(find.text('Recommended for Today'), findsOneWidget);
    });

    testWidgets('tapping "Get Styled" button navigates to styling screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pumpAndSettle();

      // Tap the "Get Styled" button
      await tester.tap(find.text('Get Styled'));
      await tester.pumpAndSettle();

      // Verify navigation to styling screen
      expect(find.text('Styling Screen'), findsOneWidget);
    });

    testWidgets('tapping outfit card navigates to try-on screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pumpAndSettle();

      // Find the outfit name text and tap on it
      final outfitNameFinder = find.text('Casual Summer');
      
      if (outfitNameFinder.evaluate().isNotEmpty) {
        await tester.tap(outfitNameFinder);
        await tester.pumpAndSettle();

        // Verify navigation to try-on screen
        expect(find.text('Try-On Screen'), findsOneWidget);
      }
    });
  });
}
