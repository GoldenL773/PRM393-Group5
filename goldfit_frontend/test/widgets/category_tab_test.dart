import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/widgets/category_tab.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

void main() {
  group('CategoryTab Widget Tests', () {
    testWidgets('displays label text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTab(
              label: 'Tops',
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tops'), findsOneWidget);
    });

    testWidgets('applies active styling when isActive is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTab(
              label: 'Bottoms',
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CategoryTab),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      
      // Verify active background color
      expect(decoration.color, GoldFitTheme.primary);
      
      // Verify active border color
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, GoldFitTheme.primary);

      // Verify text styling
      final text = tester.widget<Text>(find.text('Bottoms'));
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.color, GoldFitTheme.textDark);
    });

    testWidgets('applies inactive styling when isActive is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTab(
              label: 'Shoes',
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CategoryTab),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      
      // Verify inactive background color
      expect(decoration.color, GoldFitTheme.surfaceLight);
      
      // Verify inactive border color
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, GoldFitTheme.yellow200);

      // Verify text styling
      final text = tester.widget<Text>(find.text('Shoes'));
      expect(text.style?.fontWeight, FontWeight.w500);
      expect(text.style?.color, GoldFitTheme.textMedium);
    });

    testWidgets('handles tap gesture correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTab(
              label: 'Accessories',
              isActive: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the widgets
      await tester.tap(find.byType(CategoryTab));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('has pill-shaped border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTab(
              label: 'All',
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CategoryTab),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;
      
      // Verify pill shape (999px radius)
      expect(borderRadius.topLeft.x, 999);
      expect(borderRadius.topRight.x, 999);
      expect(borderRadius.bottomLeft.x, 999);
      expect(borderRadius.bottomRight.x, 999);
    });

    testWidgets('applies correct padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTab(
              label: 'Outerwear',
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CategoryTab),
          matching: find.byType(Container),
        ),
      );

      // Verify padding
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 10));
    });
  });
}
