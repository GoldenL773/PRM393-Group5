import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/utils/navigation_manager.dart';
import 'package:goldfit_frontend/utils/routes.dart';
import 'package:goldfit_frontend/models/outfit.dart';

void main() {
  group('NavigationManager', () {
    late NavigationManager navigationManager;

    setUp(() {
      navigationManager = NavigationManager();
    });

    testWidgets('navigateToItemDetail pushes route with itemId argument',
        (tester) async {
      const testItemId = 'test-item-123';
      String? pushedRoute;
      Map<String, dynamic>? pushedArguments;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  navigationManager.navigateToItemDetail(context, testItemId);
                },
                child: const Text('Navigate'),
              );
            },
          ),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Detail')),
            );
          },
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.itemDetail);
      expect(pushedArguments?['itemId'], testItemId);
    });

    testWidgets('navigateToTryOnWithOutfit pushes route with outfit argument',
        (tester) async {
      final testOutfit = Outfit(
        id: 'outfit-1',
        name: 'Test Outfit',
        itemIds: ['item-1', 'item-2'],
        createdDate: DateTime.now(),
      );

      String? pushedRoute;
      Map<String, dynamic>? pushedArguments;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  navigationManager.navigateToTryOnWithOutfit(
                      context, testOutfit);
                },
                child: const Text('Navigate'),
              );
            },
          ),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Try-On')),
            );
          },
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.tryOn);
      expect(pushedArguments?['outfit'], testOutfit);
    });

    testWidgets('navigateToStyling pushes styling route', (tester) async {
      String? pushedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  navigationManager.navigateToStyling(context);
                },
                child: const Text('Navigate'),
              );
            },
          ),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Styling')),
            );
          },
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.styling);
    });

    testWidgets('navigateToRecommendations pushes route with vibe argument',
        (tester) async {
      const testVibe = 'Casual';
      String? pushedRoute;
      Map<String, dynamic>? pushedArguments;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  navigationManager.navigateToRecommendations(
                    context,
                    vibe: testVibe,
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Recommendations')),
            );
          },
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.recommendations);
      expect(pushedArguments?['vibe'], testVibe);
      expect(pushedArguments?['eventDescription'], null);
    });

    testWidgets(
        'navigateToRecommendations pushes route with eventDescription argument',
        (tester) async {
      const testEvent = 'Wedding party';
      String? pushedRoute;
      Map<String, dynamic>? pushedArguments;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  navigationManager.navigateToRecommendations(
                    context,
                    eventDescription: testEvent,
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Recommendations')),
            );
          },
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.recommendations);
      expect(pushedArguments?['vibe'], null);
      expect(pushedArguments?['eventDescription'], testEvent);
    });

    testWidgets('navigateBack pops the current route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Push a route first, then pop it
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: Builder(
                            builder: (innerContext) {
                              return ElevatedButton(
                                onPressed: () {
                                  navigationManager.navigateBack(innerContext);
                                },
                                child: const Text('Pop'),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push'),
                );
              },
            ),
          ),
        ),
      );

      // Push a route
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      // Verify we're on the new route
      expect(find.text('Pop'), findsOneWidget);

      // Pop back
      await tester.tap(find.text('Pop'));
      await tester.pumpAndSettle();

      // Verify we're back to the original route
      expect(find.text('Push'), findsOneWidget);
      expect(find.text('Pop'), findsNothing);
    });
  });

  group('AppRoutes', () {
    test('route constants are defined correctly', () {
      expect(AppRoutes.home, '/');
      expect(AppRoutes.wardrobe, '/wardrobe');
      expect(AppRoutes.tryOn, '/try-on');
      expect(AppRoutes.planner, '/planner');
      expect(AppRoutes.insights, '/insights');
      expect(AppRoutes.itemDetail, '/item-detail');
      expect(AppRoutes.styling, '/styling');
      expect(AppRoutes.recommendations, '/recommendations');
    });
  });
}
