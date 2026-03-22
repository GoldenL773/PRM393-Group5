// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:goldfit_frontend/main.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/collection_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_collection.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';

// Create minimal mock classes directly here
class MockAnalyticsRepository implements AnalyticsRepository {
  @override Future<WardrobeAnalytics> getAnalytics() async => WardrobeAnalytics(
    totalItems: 0,
    totalValue: 0,
    mostWorn: [],
    leastWorn: [],
  );
  @override Future<void> recordUsage(String outfitId, DateTime date) async {}
  @override Future<List<ClothingItem>> getMostWorn(int limit) async => [];
  @override Future<List<ClothingItem>> getLeastWorn(int limit) async => [];
  @override Future<Map<ClothingType, int>> getItemCountByType() async => {};
  @override Future<double> getTotalValue() async => 0;
  @override void invalidateCache() {}
}

class MockClothingRepository implements ClothingRepository {
  @override Future<ClothingItem> create(ClothingItem item) async => item;
  @override Future<ClothingItem?> getById(String id) async => null;
  @override Future<List<ClothingItem>> getAll() async => [];
  @override Future<List<ClothingItem>> getByType(ClothingType type) async => [];
  @override Future<List<ClothingItem>> getByFilters(FilterState filters) async => [];
  @override Future<ClothingItem> update(ClothingItem item) async => item;
  @override Future<void> delete(String id) async {}
  @override Future<List<ClothingItem>> batchCreate(List<ClothingItem> items) async => items;
  @override Stream<List<ClothingItem>> watchAll() => Stream.value([]);
}

class MockOutfitRepository implements OutfitRepository {
  @override Future<Outfit> create(Outfit outfit) async => outfit;
  @override Future<Outfit?> getById(String id) async => null;
  @override Future<List<Outfit>> getAll() async => [];
  @override Future<List<Outfit>> getByVibe(String vibe) async => [];
  @override Future<Outfit> update(Outfit outfit) async => outfit;
  @override Future<void> delete(String id) async {}
  @override Future<void> assignToDate(String outfitId, DateTime date) async {}
  @override Future<void> unassignFromDate(DateTime date) async {}
  @override Future<List<Outfit>> getByDate(DateTime date) async => [];
  @override Future<List<Outfit>> getByDateRange(DateTime start, DateTime end) async => [];
  @override Stream<List<Outfit>> watchAll() => Stream.value([]);
}

class MockCollectionRepository implements CollectionRepository {
  @override
  Future<WardrobeCollection> create(WardrobeCollection collection) async =>
      collection;

  @override
  Future<WardrobeCollection?> getById(String id) async => null;

  @override
  Future<List<WardrobeCollection>> getAll() async => [];

  @override
  Future<WardrobeCollection> update(WardrobeCollection collection) async =>
      collection;

  @override
  Future<void> delete(String id) async {}
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: '''
GEMINI_API_KEY=
GEMINI_API_KEY_TEXT=
OPENWEATHER_API_KEY=
REMOVE_BG_API_KEY=
''');
  });

  testWidgets('GoldFit app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(GoldFitApp(
      analyticsRepository: MockAnalyticsRepository(),
      clothingRepository: MockClothingRepository(),
      collectionRepository: MockCollectionRepository(),
      outfitRepository: MockOutfitRepository(),
    ));

    // Verify that the app shell renders
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
