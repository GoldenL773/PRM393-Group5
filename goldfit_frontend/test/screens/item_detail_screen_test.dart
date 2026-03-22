import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/wardrobe/item_detail_screen.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';

void main() {
  group('ItemDetailScreen', () {
    late AppState appState;
    late ClothingItem testItem;

    setUp(() {
      appState = AppState(MockDataProvider());
      // Get the first item from mock data
      testItem = appState.allItems.first;
    });

    Widget createTestWidget({String? itemId}) {
      return ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return ItemDetailScreen();
            },
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/item-detail') {
              return MaterialPageRoute(
                builder: (context) => const ItemDetailScreen(),
                settings: RouteSettings(
                  arguments: {'itemId': itemId},
                ),
              );
            }
            return null;
          },
        ),
      );
    }

    testWidgets('displays error message when no item ID provided', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('No item ID provided'), findsOneWidget);
    });

    testWidgets('displays error message when item not found', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: const RouteSettings(
                        arguments: {'itemId': 'non-existent-id'},
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
      expect(find.text('Item not found'), findsOneWidget);
    });

    testWidgets('displays item details when valid item ID provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: RouteSettings(
                        arguments: {'itemId': testItem.id},
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
      
      // Verify app bar
      expect(find.text('Item Detail'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      
      // Verify tag section
      expect(find.text('Item Details'), findsOneWidget);
      expect(find.textContaining('Type:'), findsOneWidget);
      expect(find.textContaining('Color:'), findsOneWidget);
      expect(find.textContaining('Seasons:'), findsOneWidget);
      
      // Verify delete button
      expect(find.text('Delete Item'), findsOneWidget);
    });

    testWidgets('displays InteractiveViewer for image zoom', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: RouteSettings(
                        arguments: {'itemId': testItem.id},
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
      
      // Verify InteractiveViewer is present
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when delete button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: RouteSettings(
                        arguments: {'itemId': testItem.id},
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
      
      // Tap delete button
      await tester.tap(find.text('Delete Item'));
      await tester.pumpAndSettle();
      
      // Verify confirmation dialog appears
      expect(find.text('Delete Item'), findsNWidgets(2)); // One in button, one in dialog title
      expect(find.text('Are you sure you want to delete this item? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('deletes item when confirmed in dialog', (WidgetTester tester) async {
      final initialItemCount = appState.allItems.length;
      
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: RouteSettings(
                        arguments: {'itemId': testItem.id},
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
      
      // Tap delete button
      await tester.tap(find.text('Delete Item'));
      await tester.pumpAndSettle();
      
      // Confirm deletion
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      
      // Verify item was deleted
      expect(appState.allItems.length, initialItemCount - 1);
      expect(appState.dataProvider.getItemById(testItem.id), isNull);
    });

    testWidgets('displays price tag when item has price', (WidgetTester tester) async {
      // Find an item with a price
      final itemWithPrice = appState.allItems.firstWhere(
        (item) => item.price != null,
        orElse: () => appState.allItems.first,
      );
      
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: RouteSettings(
                        arguments: {'itemId': itemWithPrice.id},
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
      
      if (itemWithPrice.price != null) {
        expect(find.textContaining('Price:'), findsOneWidget);
        expect(find.textContaining('\$'), findsOneWidget);
      }
    });

    testWidgets('shows edit coming soon message when edit button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Navigator(
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => const ItemDetailScreen(),
                      settings: RouteSettings(
                        arguments: {'itemId': testItem.id},
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
      
      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      
      // Verify snackbar appears
      expect(find.text('Edit functionality coming soon'), findsOneWidget);
    });
  });
}
