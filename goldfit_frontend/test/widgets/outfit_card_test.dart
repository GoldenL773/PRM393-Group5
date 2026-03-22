import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/widgets/outfit_card.dart';

void main() {
  group('OutfitCard Widget Tests', () {
    late Outfit testOutfit;
    late List<ClothingItem> testItems;

    setUp(() {
      // Create test clothing items
      testItems = [
        ClothingItem(
          id: '1',
          imageUrl: 'placeholder://tops/Blue',
          type: ClothingType.tops,
          color: 'Blue',
          seasons: [Season.summer],
          price: 50.0,
          usageCount: 5,
          addedDate: DateTime.now(),
        ),
        ClothingItem(
          id: '2',
          imageUrl: 'placeholder://bottoms/Black',
          type: ClothingType.bottoms,
          color: 'Black',
          seasons: [Season.summer, Season.fall],
          price: 80.0,
          usageCount: 3,
          addedDate: DateTime.now(),
        ),
        ClothingItem(
          id: '3',
          imageUrl: 'placeholder://shoes/White',
          type: ClothingType.shoes,
          color: 'White',
          seasons: [Season.spring, Season.summer],
          price: 120.0,
          usageCount: 10,
          addedDate: DateTime.now(),
        ),
      ];

      // Create test outfit
      testOutfit = Outfit(
        id: 'outfit1',
        name: 'Summer Casual',
        itemIds: ['1', '2', '3'],
        vibe: 'Casual',
        createdDate: DateTime.now(),
      );
    });

    testWidgets('OutfitCard displays outfit name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: testOutfit,
              items: testItems,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Summer Casual'), findsOneWidget);
    });

    testWidgets('OutfitCard displays vibe label when vibe is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: testOutfit,
              items: testItems,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Casual'), findsOneWidget);
    });

    testWidgets('OutfitCard does not display vibe label when vibe is null', (tester) async {
      final outfitWithoutVibe = Outfit(
        id: 'outfit2',
        name: 'No Vibe Outfit',
        itemIds: ['1', '2'],
        vibe: null,
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: outfitWithoutVibe,
              items: testItems.take(2).toList(),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('No Vibe Outfit'), findsOneWidget);
      // Vibe should not be displayed
      expect(find.text('Casual'), findsNothing);
    });

    testWidgets('OutfitCard handles tap gesture', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: testOutfit,
              items: testItems,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutfitCard));
      expect(tapped, true);
    });

    testWidgets('OutfitCard displays item thumbnails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: testOutfit,
              items: testItems,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display icons for placeholder items
      expect(find.byIcon(Icons.checkroom), findsOneWidget); // tops
      expect(find.byIcon(Icons.dry_cleaning), findsOneWidget); // bottoms
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget); // shoes
    });

    testWidgets('OutfitCard shows empty state when no items', (tester) async {
      final emptyOutfit = Outfit(
        id: 'empty',
        name: 'Empty Outfit',
        itemIds: [],
        vibe: 'Work',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: emptyOutfit,
              items: [],
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Empty Outfit'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });

    testWidgets('OutfitCard shows +N indicator for more than 4 items', (tester) async {
      // Create 6 items
      final manyItems = List.generate(
        6,
        (index) => ClothingItem(
          id: 'item$index',
          imageUrl: 'placeholder://tops/Blue',
          type: ClothingType.tops,
          color: 'Blue',
          seasons: [Season.summer],
          price: 50.0,
          usageCount: 0,
          addedDate: DateTime.now(),
        ),
      );

      final outfitWithManyItems = Outfit(
        id: 'many',
        name: 'Many Items',
        itemIds: manyItems.map((i) => i.id).toList(),
        vibe: 'Formal',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutfitCard(
              outfit: outfitWithManyItems,
              items: manyItems,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show +2 indicator (6 - 4 = 2)
      expect(find.text('+2'), findsOneWidget);
    });
  });
}
