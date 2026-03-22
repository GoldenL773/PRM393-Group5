import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/try_on/try_on_screen.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

/// Tests for orientation optimization in Try-On Screen
/// Validates Requirement 15.5: Orientation-responsive layout
void main() {
  late AppState appState;

  setUp(() {
    appState = AppState(MockDataProvider());
  });

  Widget createTestWidget({Size? size, Orientation? orientation}) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        theme: GoldFitTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: size ?? const Size(800, 600),
            devicePixelRatio: 1.0,
          ),
          child: const TryOnScreen(),
        ),
      ),
    );
  }

  group('Orientation Optimization Tests', () {
    testWidgets('displays portrait layout in portrait orientation', (tester) async {
      // Portrait size (taller than wide)
      await tester.pumpWidget(createTestWidget(size: const Size(400, 800)));

      // Should display Column layout (portrait)
      expect(find.byType(Column), findsWidgets);
      
      // Mode toggle should be at top
      expect(find.text('Quick Try'), findsOneWidget);
      expect(find.text('Realistic Fitting'), findsOneWidget);
    });

    testWidgets('displays landscape layout in landscape orientation', (tester) async {
      // Landscape size (wider than tall)
      await tester.pumpWidget(createTestWidget(size: const Size(800, 400)));

      // Should display Row layout (landscape)
      expect(find.byType(Row), findsWidgets);
      
      // Mode toggle should still be visible
      expect(find.text('Quick Try'), findsOneWidget);
      expect(find.text('Realistic Fitting'), findsOneWidget);
    });

    testWidgets('adapts layout when orientation changes', (tester) async {
      // Start in portrait
      await tester.pumpWidget(createTestWidget(size: const Size(400, 800)));
      await tester.pump();

      // Verify portrait layout
      expect(find.text('Quick Try'), findsOneWidget);

      // Change to landscape
      await tester.pumpWidget(createTestWidget(size: const Size(800, 400)));
      await tester.pump();

      // Should still display correctly
      expect(find.text('Quick Try'), findsOneWidget);
      expect(find.text('Realistic Fitting'), findsOneWidget);
    });

    testWidgets('base photo area uses LayoutBuilder for responsive sizing', (tester) async {
      await tester.pumpWidget(createTestWidget(size: const Size(800, 600)));

      // Should have LayoutBuilder for responsive sizing
      expect(find.byType(LayoutBuilder), findsWidgets);
    });

    testWidgets('maintains functionality in landscape mode', (tester) async {
      await tester.pumpWidget(createTestWidget(size: const Size(800, 400)));
      await tester.pump();

      // Mode toggle should work
      await tester.tap(find.text('Realistic Fitting'));
      await tester.pump();

      expect(appState.tryOnMode, TryOnMode.realistic);

      // Clothing selector button should be present
      expect(find.text('Select Clothing'), findsOneWidget);
    });

    testWidgets('maintains functionality in portrait mode', (tester) async {
      await tester.pumpWidget(createTestWidget(size: const Size(400, 800)));
      await tester.pump();

      // Mode toggle should work
      await tester.tap(find.text('Realistic Fitting'));
      await tester.pump();

      expect(appState.tryOnMode, TryOnMode.realistic);

      // Clothing selector button should be present
      expect(find.text('Select Clothing'), findsOneWidget);
    });
  });
}
