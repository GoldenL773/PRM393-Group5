import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/screens/home_screen.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/utils/navigation_manager.dart';
import 'package:goldfit_frontend/utils/routes.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late AppState appState;
    late NavigationManager navigationManager;

    setUp(() {
      appState = AppState(MockDataProvider());
      navigationManager = NavigationManager();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<NavigationManager>.value(value: navigationManager),
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

    testWidgets('displays weather widget on load', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify weather information is displayed
      final weather = appState.currentWeather;
      expect(find.text('${weather.temperature.round()}°F'), findsOneWidget);
      expect(find.text(weather.condition), findsOneWidget);
      expect(find.text(weather.location), findsOneWidget);
    });

    testWidgets('displays "Get Styled" button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pumpAndSettle();

      // Verify "Get Styled" button is present
      expect(find.text('Get Styled'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('displays recommended outfits section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pumpAndSettle();

      // Verify recommended outfits section header
      expect(find.text('Recommended for Today'), findsOneWidget);

      // Verify outfit cards are displayed (up to 3)
      final recommendations = appState.weatherRecommendations;
      if (recommendations.isNotEmpty) {
        // At least one outfit card should be present
        expect(find.byType(GestureDetector), findsWidgets);
      }
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

      final recommendations = appState.weatherRecommendations;
      if (recommendations.isNotEmpty) {
        // Find the outfit name text and tap on it
        final outfitName = recommendations.first.name;
        final outfitNameFinder = find.text(outfitName);
        
        if (outfitNameFinder.evaluate().isNotEmpty) {
          await tester.tap(outfitNameFinder);
          await tester.pumpAndSettle();

          // Verify navigation to try-on screen
          expect(find.text('Try-On Screen'), findsOneWidget);
        }
      }
    });
  });
}
