import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/screens/recommendations_screen.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/utils/navigation_manager.dart';
import 'package:goldfit_frontend/widgets/outfit_card.dart';
import 'package:goldfit_frontend/utils/theme.dart';

void main() {
  late AppState appState;
  late NavigationManager navigationManager;

  setUp(() {
    appState = AppState(MockDataProvider());
    navigationManager = NavigationManager();
  });

  Widget createTestWidget({String? vibe, String? eventDescription}) {
    return MaterialApp(
      theme: GoldFitTheme.lightTheme,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<NavigationManager>.value(value: navigationManager),
        ],
        child: Builder(
          builder: (context) {
            // Simulate navigation with arguments
            return Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => const RecommendationsScreen(),
                  settings: RouteSettings(
                    arguments: {
                      if (vibe != null) 'vibe': vibe,
                      if (eventDescription != null) 'eventDescription': eventDescription,
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  group('RecommendationsScreen Widget Tests', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Outfit Recommendations'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays header with vibe when vibe is provided', (tester) async {
      await tester.pumpWidget(createTestWidget(vibe: 'Casual'));
      await tester.pumpAndSettle();

      expect(find.text('Perfect for Casual'), findsOneWidget);
      expect(find.text('Here are some outfit suggestions for you'), findsOneWidget);
    });

    testWidgets('displays header with event description when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(eventDescription: 'Beach party'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Recommendations'), findsOneWidget);
      expect(find.text('For: Beach party'), findsOneWidget);
    });

    testWidgets('displays default header when no vibe or event provided', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recommended for You'), findsOneWidget);
      expect(find.text('Based on current weather and your style'), findsOneWidget);
    });

    testWidgets('displays outfit cards for vibe-based recommendations', (tester) async {
      await tester.pumpWidget(createTestWidget(vibe: 'Casual'));
      await tester.pumpAndSettle();

      // Should display OutfitCard widgets
      expect(find.byType(OutfitCard), findsWidgets);
    });

    testWidgets('displays outfit cards for weather-based recommendations', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display OutfitCard widgets
      expect(find.byType(OutfitCard), findsWidgets);
    });

    testWidgets('displays 3-5 outfit recommendations', (tester) async {
      await tester.pumpWidget(createTestWidget(vibe: 'Work'));
      await tester.pumpAndSettle();

      // Count the number of OutfitCard widgets
      final outfitCards = find.byType(OutfitCard);
      final count = outfitCards.evaluate().length;
      
      // Should have between 3 and 5 recommendations
      expect(count, greaterThanOrEqualTo(3));
      expect(count, lessThanOrEqualTo(5));
    });

    testWidgets('outfit cards are tappable', (tester) async {
      await tester.pumpWidget(createTestWidget(vibe: 'Date Night'));
      await tester.pumpAndSettle();

      // Find the first outfit card
      final outfitCard = find.byType(OutfitCard).first;
      expect(outfitCard, findsOneWidget);

      // Tap the outfit card - it should be tappable
      await tester.tap(outfitCard);
      await tester.pumpAndSettle();
      
      // If we got here without error, the tap worked
      expect(outfitCard, findsOneWidget);
    });

    testWidgets('uses correct theme colors', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, GoldFitTheme.backgroundLight);
    });

    testWidgets('displays empty state when no recommendations available', (tester) async {
      // Create an AppState with no outfits
      final emptyProvider = MockDataProvider();
      // Clear all outfits
      for (final outfit in emptyProvider.getAllOutfits()) {
        emptyProvider.deleteOutfit(outfit.id);
      }
      final emptyAppState = AppState(emptyProvider);

      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>.value(value: emptyAppState),
              Provider<NavigationManager>.value(value: navigationManager),
            ],
            child: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const RecommendationsScreen(),
                      settings: RouteSettings(
                        arguments: <String, dynamic>{},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No Recommendations Available'), findsOneWidget);
      expect(find.text('Try adding more items to your wardrobe'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });
  });
}
