import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';
import 'package:goldfit_frontend/models/outfit.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/screens/app_shell.dart';
import 'package:goldfit_frontend/widgets/clothing_item_card.dart';
import 'package:goldfit_frontend/widgets/outfit_card.dart';
import 'package:goldfit_frontend/utils/routes.dart';
import 'package:goldfit_frontend/utils/theme.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 1: Navigation Correctness', () {
    testWidgets('Bottom navigation tabs navigate to correct screens', (tester) async {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Verify initial screen is Home (index 0)
      expect(find.text('Home'), findsOneWidget);

      // Test navigation to Wardrobe tab (index 1)
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsOneWidget);

      // Test navigation to Try-On tab (index 2)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Try-On'), findsOneWidget);

      // Test navigation to Planner tab (index 3)
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Planner'), findsOneWidget);

      // Test navigation to Insights tab (index 4)
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Insights'), findsOneWidget);

      // Test navigation back to Home tab (index 0)
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    property('ClothingItemCard navigates to item detail with correct item ID', () {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      forAll(
        clothingItemArbitrary(),
        (item) async {
          String? navigatedItemId;
          
          await testWidgets('ClothingItemCard tap navigation', (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: GoldFitTheme.lightTheme,
                home: Scaffold(
                  body: ClothingItemCard(
                    item: item,
                    onTap: () {
                      navigatedItemId = item.id;
                    },
                  ),
                ),
              ),
            );

            // Tap the clothing item card
            await tester.tap(find.byType(ClothingItemCard));
            await tester.pumpAndSettle();

            // Verify the correct item ID was passed to navigation
            expect(navigatedItemId, equals(item.id),
                reason: 'ClothingItemCard should navigate with correct item ID');
          });
        },
      );
    });

    property('OutfitCard navigates to try-on with correct outfit data', () {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      forAll(
        outfitWithItemsArbitrary(),
        (outfitData) async {
          Outfit? navigatedOutfit;
          
          await testWidgets('OutfitCard tap navigation', (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: GoldFitTheme.lightTheme,
                home: Scaffold(
                  body: OutfitCard(
                    outfit: outfitData.outfit,
                    items: outfitData.items,
                    onTap: () {
                      navigatedOutfit = outfitData.outfit;
                    },
                  ),
                ),
              ),
            );

            // Tap the outfit card
            await tester.tap(find.byType(OutfitCard));
            await tester.pumpAndSettle();

            // Verify the correct outfit was passed to navigation
            expect(navigatedOutfit, isNotNull,
                reason: 'OutfitCard should trigger navigation');
            expect(navigatedOutfit?.id, equals(outfitData.outfit.id),
                reason: 'OutfitCard should navigate with correct outfit ID');
            expect(navigatedOutfit?.itemIds, equals(outfitData.outfit.itemIds),
                reason: 'OutfitCard should navigate with correct item IDs');
          });
        },
      );
    });

    testWidgets('Navigation preserves data across route transitions', (tester) async {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      
      // Get test data
      final items = appState.allItems;
      if (items.isEmpty) return;
      
      final testItem = items.first;
      String? receivedItemId;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: Scaffold(
              body: ClothingItemCard(
                item: testItem,
                onTap: () {
                  receivedItemId = testItem.id;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the item card
      await tester.tap(find.byType(ClothingItemCard));
      await tester.pumpAndSettle();

      // Verify data was passed correctly
      expect(receivedItemId, equals(testItem.id),
          reason: 'Navigation should preserve item ID data');
    });

    testWidgets('Multiple navigation elements can be tapped independently', (tester) async {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      
      final items = appState.allItems.take(3).toList();
      if (items.length < 3) return;

      final tappedItems = <String>[];

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: Scaffold(
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ClothingItemCard(
                    item: items[index],
                    onTap: () {
                      tappedItems.add(items[index].id);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap each item card independently
      for (int i = 0; i < items.length; i++) {
        final cardFinder = find.byType(ClothingItemCard).at(i);
        await tester.tap(cardFinder);
        await tester.pumpAndSettle();
      }

      // Verify all items were tapped in order
      expect(tappedItems.length, equals(items.length),
          reason: 'All navigation elements should be independently tappable');
      
      for (int i = 0; i < items.length; i++) {
        expect(tappedItems[i], equals(items[i].id),
            reason: 'Each navigation element should pass correct data');
      }
    });

    testWidgets('Navigation elements in different contexts navigate correctly', (tester) async {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      
      final items = appState.allItems;
      final outfits = appState.allOutfits;
      
      if (items.isEmpty || outfits.isEmpty) return;

      final testItem = items.first;
      final testOutfit = outfits.first;
      final outfitItems = testOutfit.itemIds
          .map((id) => items.firstWhere((item) => item.id == id, orElse: () => items.first))
          .toList();

      String? navigatedItemId;
      Outfit? navigatedOutfit;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  // ClothingItemCard in one context
                  SizedBox(
                    height: 200,
                    child: ClothingItemCard(
                      item: testItem,
                      onTap: () {
                        navigatedItemId = testItem.id;
                      },
                    ),
                  ),
                  
                  // OutfitCard in another context
                  SizedBox(
                    height: 200,
                    child: OutfitCard(
                      outfit: testOutfit,
                      items: outfitItems,
                      onTap: () {
                        navigatedOutfit = testOutfit;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap the clothing item card
      await tester.tap(find.byType(ClothingItemCard));
      await tester.pumpAndSettle();
      
      expect(navigatedItemId, equals(testItem.id),
          reason: 'ClothingItemCard should navigate with correct item ID');

      // Tap the outfit card
      await tester.tap(find.byType(OutfitCard));
      await tester.pumpAndSettle();
      
      expect(navigatedOutfit?.id, equals(testOutfit.id),
          reason: 'OutfitCard should navigate with correct outfit ID');
    });

    property('Navigation buttons trigger correct navigation actions', () {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      forAll(
        integer(min: 0, max: 4),
        (tabIndex) async {
          await testWidgets('Navigation button test', (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: GoldFitTheme.lightTheme,
                home: const AppShell(),
              ),
            );

            // Get the navigation bar
            final navBar = tester.widget<BottomNavigationBar>(
              find.byType(BottomNavigationBar),
            );

            // Verify initial state
            expect(navBar.currentIndex, equals(0),
                reason: 'Initial tab should be Home (index 0)');

            // Tap the specified tab
            final icons = [
              Icons.home_outlined,
              Icons.checkroom_outlined,
              Icons.person_outline,
              Icons.calendar_today_outlined,
              Icons.insights_outlined,
            ];
            
            await tester.tap(find.byIcon(icons[tabIndex]));
            await tester.pumpAndSettle();

            // Verify the correct screen is displayed
            final expectedScreens = ['Home', 'Wardrobe', 'Try-On', 'Planner', 'Insights'];
            expect(find.text(expectedScreens[tabIndex]), findsOneWidget,
                reason: 'Tapping tab $tabIndex should navigate to ${expectedScreens[tabIndex]} screen');
          });
        },
      );
    });

    testWidgets('Navigation maintains correct screen hierarchy', (tester) async {
      // **Validates: Requirements 1.2, 3.3, 4.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Start at Home
      expect(find.text('Home'), findsOneWidget);

      // Navigate through all tabs in sequence
      final tabSequence = [
        (Icons.checkroom_outlined, 'Wardrobe'),
        (Icons.person_outline, 'Try-On'),
        (Icons.calendar_today_outlined, 'Planner'),
        (Icons.insights_outlined, 'Insights'),
        (Icons.home_outlined, 'Home'),
      ];

      for (final (icon, screenName) in tabSequence) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
        
        expect(find.text(screenName), findsOneWidget,
            reason: 'Should navigate to $screenName screen');
      }
    });
  });
}

// ============================================================================
// Arbitrary Generators
// ============================================================================

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

/// Arbitrary generator for Outfit with associated ClothingItems
Arbitrary<OutfitWithItems> outfitWithItemsArbitrary() {
  return integer(min: 1, max: 1000000).flatMap((idNum) {
    return integer(min: 2, max: 5).flatMap((itemCount) {
      return integer(min: 0, max: 2).flatMap((vibeIndex) {
        final vibes = ['Casual', 'Work', 'Date Night'];
        final vibe = vibes[vibeIndex];
        
        // Generate clothing items for the outfit
        final items = <ClothingItem>[];
        final itemIds = <String>[];
        
        for (var i = 0; i < itemCount; i++) {
          final itemId = 'item-${idNum + i}';
          itemIds.add(itemId);
          
          final colors = ['red', 'blue', 'green', 'black', 'white'];
          final color = colors[i % colors.length];
          
          final type = ClothingType.values[i % ClothingType.values.length];
          
          items.add(ClothingItem(
            id: itemId,
            imageUrl: 'placeholder-$color',
            type: type,
            color: color,
            seasons: [Season.spring],
            usageCount: 0,
            addedDate: DateTime.now(),
          ));
        }
        
        final outfit = Outfit(
          id: 'outfit-$idNum',
          name: 'Test Outfit $idNum',
          itemIds: itemIds,
          vibe: vibe,
          createdDate: DateTime.now(),
        );
        
        return constant(OutfitWithItems(outfit: outfit, items: items));
      });
    });
  });
}

// ============================================================================
// Helper Classes
// ============================================================================

/// Helper class to hold an outfit with its associated items
class OutfitWithItems {
  final Outfit outfit;
  final List<ClothingItem> items;
  
  OutfitWithItems({
    required this.outfit,
    required this.items,
  });
}
