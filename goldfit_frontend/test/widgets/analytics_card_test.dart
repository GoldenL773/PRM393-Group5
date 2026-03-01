import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/widgets/analytics_card.dart';
import 'package:goldfit_frontend/utils/theme.dart';

void main() {
  group('AnalyticsCard Widget Tests', () {
    testWidgets('displays title, value, and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const Scaffold(
            body: AnalyticsCard(
              title: 'Total Items',
              value: '42',
              icon: Icons.checkroom,
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Total Items'), findsOneWidget);
      
      // Verify value is displayed
      expect(find.text('42'), findsOneWidget);
      
      // Verify icon is displayed
      expect(find.byIcon(Icons.checkroom), findsOneWidget);
    });

    testWidgets('displays with different metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const Scaffold(
            body: AnalyticsCard(
              title: 'Total Value',
              value: '\$1,234',
              icon: Icons.attach_money,
            ),
          ),
        ),
      );

      expect(find.text('Total Value'), findsOneWidget);
      expect(find.text('\$1,234'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('applies correct styling from theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const Scaffold(
            body: AnalyticsCard(
              title: 'Test Metric',
              value: '100',
              icon: Icons.star,
            ),
          ),
        ),
      );

      // Find the container with the card decoration
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnalyticsCard),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      
      // Verify card styling
      expect(decoration.color, GoldFitTheme.surfaceLight);
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('icon container has yellow background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const Scaffold(
            body: AnalyticsCard(
              title: 'Test',
              value: '50',
              icon: Icons.favorite,
            ),
          ),
        ),
      );

      // Find the icon container
      final iconContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(AnalyticsCard),
          matching: find.byType(Container),
        ),
      );

      // The second container should be the icon container
      bool foundIconContainer = false;
      for (final container in iconContainers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration?.color == GoldFitTheme.yellow100) {
          foundIconContainer = true;
          expect(decoration?.borderRadius, BorderRadius.circular(12));
          break;
        }
      }
      
      expect(foundIconContainer, true);
    });

    testWidgets('handles long title text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 200,
              child: AnalyticsCard(
                title: 'Very Long Title That Should Not Overflow',
                value: '999',
                icon: Icons.info,
              ),
            ),
          ),
        ),
      );

      // Should not throw overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('Very Long Title That Should Not Overflow'), findsOneWidget);
    });

    testWidgets('handles long value text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 200,
              child: AnalyticsCard(
                title: 'Big Number',
                value: '\$1,234,567.89',
                icon: Icons.trending_up,
              ),
            ),
          ),
        ),
      );

      // Should not throw overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('\$1,234,567.89'), findsOneWidget);
    });
  });
}
