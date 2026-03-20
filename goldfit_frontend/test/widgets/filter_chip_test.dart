import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/widgets/filter_chip.dart' as goldfit;
import 'package:goldfit_frontend/shared/utils/theme.dart';

void main() {
  group('FilterChip Widget Tests', () {
    testWidgets('displays filter label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Red',
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Red'), findsOneWidget);
    });

    testWidgets('displays remove button icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Summer',
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onRemove when remove button is tapped', (tester) async {
      bool removeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Blue',
              onRemove: () {
                removeCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(removeCalled, true);
    });

    testWidgets('has yellow background and border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Winter',
              onRemove: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(goldfit.FilterChip),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, GoldFitTheme.yellow100);
      expect(decoration.border, isA<Border>());
      
      final border = decoration.border as Border;
      expect(border.top.color, GoldFitTheme.yellow200);
    });

    testWidgets('has pill shape with rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Green',
              onRemove: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(goldfit.FilterChip),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(999));
    });

    testWidgets('displays multiple filter chips correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                goldfit.FilterChip(
                  label: 'Red',
                  onRemove: () {},
                ),
                const SizedBox(width: 8),
                goldfit.FilterChip(
                  label: 'Summer',
                  onRemove: () {},
                ),
                const SizedBox(width: 8),
                goldfit.FilterChip(
                  label: 'Blue',
                  onRemove: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Summer'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.byType(goldfit.FilterChip), findsNWidgets(3));
    });

    testWidgets('handles long filter labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Very Long Filter Label',
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Very Long Filter Label'), findsOneWidget);
    });

    testWidgets('remove button is tappable independently', (tester) async {
      bool removeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: goldfit.FilterChip(
              label: 'Test Filter',
              onRemove: () {
                removeCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap on the label should not trigger remove
      await tester.tap(find.text('Test Filter'));
      await tester.pump();
      expect(removeCalled, false);

      // Tap on the close icon should trigger remove
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(removeCalled, true);
    });
  });
}
