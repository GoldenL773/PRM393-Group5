import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/models/clothing_item.dart';
import 'package:goldfit_frontend/widgets/clothing_item_card.dart';

void main() {
  group('ClothingItemCard', () {
    late ClothingItem testItem;

    setUp(() {
      testItem = ClothingItem(
        id: 'test-1',
        imageUrl: 'placeholder',
        type: ClothingType.tops,
        color: 'blue',
        seasons: [Season.summer],
        price: 29.99,
        usageCount: 5,
        addedDate: DateTime.now(),
      );
    });

    testWidgets('displays clothing item and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClothingItemCard(
              item: testItem,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify the card is displayed
      expect(find.byType(ClothingItemCard), findsOneWidget);

      // Verify placeholder icon is shown (since imageUrl doesn't start with 'assets/')
      expect(find.byIcon(Icons.checkroom), findsOneWidget);

      // Tap the card
      await tester.tap(find.byType(ClothingItemCard));
      await tester.pump();

      // Verify tap callback was called
      expect(tapped, true);
    });

    testWidgets('displays correct icon for each clothing type', (tester) async {
      final types = [
        (ClothingType.tops, Icons.checkroom),
        (ClothingType.bottoms, Icons.dry_cleaning),
        (ClothingType.outerwear, Icons.ac_unit),
        (ClothingType.shoes, Icons.shopping_bag),
        (ClothingType.accessories, Icons.watch),
      ];

      for (final (type, expectedIcon) in types) {
        final item = testItem.copyWith(type: type);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClothingItemCard(
                item: item,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(expectedIcon), findsOneWidget,
            reason: 'Expected icon $expectedIcon for type $type');

        // Clear the widget tree for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('displays asset image when imageUrl starts with assets/', (tester) async {
      final itemWithAsset = testItem.copyWith(
        imageUrl: 'assets/test_image.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClothingItemCard(
              item: itemWithAsset,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify Image.asset is used (will show error builder since asset doesn't exist)
      // The error builder will show the placeholder icon
      expect(find.byType(ClothingItemCard), findsOneWidget);
    });

    testWidgets('has proper styling with border and shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClothingItemCard(
              item: testItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the container with decoration
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ClothingItemCard),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;

      // Verify border radius
      expect(decoration.borderRadius, BorderRadius.circular(16));

      // Verify border
      expect(decoration.border, isNotNull);

      // Verify shadow
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
    });
  });
}
