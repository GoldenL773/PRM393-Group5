import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/features/home/styling_screen.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

void main() {
  group('StylingScreen', () {
    testWidgets('displays "What\'s the vibe today?" header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const StylingScreen(),
        ),
      );

      expect(find.text('What\'s the vibe today?'), findsOneWidget);
    });

    testWidgets('displays three predefined vibe cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const StylingScreen(),
        ),
      );

      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Date Night'), findsOneWidget);
    });

    testWidgets('displays text input field for custom event descriptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const StylingScreen(),
        ),
      );

      expect(find.text('Describe your event'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Get Recommendations'), findsOneWidget);
    });

    testWidgets('vibe card shows selected state when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const StylingScreen(),
          routes: {
            '/recommendations': (context) => const Scaffold(
              body: Center(child: Text('Recommendations')),
            ),
          },
        ),
      );

      // Find and tap the Casual vibe card
      await tester.tap(find.text('Casual'));
      await tester.pumpAndSettle();

      // Should navigate to recommendations screen
      expect(find.text('Recommendations'), findsOneWidget);
    });

    testWidgets('text input can be entered and submitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const StylingScreen(),
          routes: {
            '/recommendations': (context) => const Scaffold(
              body: Center(child: Text('Recommendations')),
            ),
          },
        ),
      );

      // Drag to scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Enter text in the text field
      await tester.enterText(find.byType(TextField), 'Brunch with friends');
      expect(find.text('Brunch with friends'), findsOneWidget);

      // Tap the Get Recommendations button
      await tester.tap(find.text('Get Recommendations'));
      await tester.pumpAndSettle();

      // Should navigate to recommendations screen
      expect(find.text('Recommendations'), findsOneWidget);
    });

    testWidgets('Get Recommendations button does nothing with empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const StylingScreen(),
          routes: {
            '/recommendations': (context) => const Scaffold(
              body: Center(child: Text('Recommendations')),
            ),
          },
        ),
      );

      // Drag to scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap the Get Recommendations button without entering text
      await tester.tap(find.text('Get Recommendations'));
      await tester.pumpAndSettle();

      // Should still be on styling screen
      expect(find.text('What\'s the vibe today?'), findsOneWidget);
    });
  });
}
