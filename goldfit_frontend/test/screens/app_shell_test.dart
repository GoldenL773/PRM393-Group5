import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/screens/app_shell.dart';
import 'package:goldfit_frontend/utils/theme.dart';

void main() {
  group('AppShell Widget Tests', () {
    Widget buildTestApp() {
      return MaterialApp(
        theme: GoldFitTheme.lightTheme,
        home: const AppShell(),
      );
    }

    testWidgets('displays bottom navigation bar with 5 tabs', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify bottom navigation bar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify all 5 navigation items are present by checking the BottomNavigationBar items
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 5);
      expect(bottomNav.items[0].label, 'Home');
      expect(bottomNav.items[1].label, 'Wardrobe');
      expect(bottomNav.items[2].label, 'Try-On');
      expect(bottomNav.items[3].label, 'Planner');
      expect(bottomNav.items[4].label, 'Insights');
    });

    testWidgets('starts with Home tab selected', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify Home screen is displayed initially
      expect(find.text('Home Screen'), findsOneWidget);
      
      // Verify the bottom navigation bar shows Home as selected (index 0)
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('navigates to different screens when tabs are tapped', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Tap Wardrobe tab
      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe Screen'), findsOneWidget);

      // Tap Try-On tab
      await tester.tap(find.text('Try-On'));
      await tester.pumpAndSettle();
      expect(find.text('Try-On Screen'), findsOneWidget);

      // Tap Planner tab
      await tester.tap(find.text('Planner'));
      await tester.pumpAndSettle();
      expect(find.text('Planner Screen'), findsOneWidget);

      // Tap Insights tab
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Insights Screen'), findsOneWidget);

      // Tap Home tab to return
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('highlights active tab with primary color', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify the theme has the correct colors configured
      final context = tester.element(find.byType(AppShell));
      final theme = Theme.of(context);
      
      expect(theme.bottomNavigationBarTheme.selectedItemColor, GoldFitTheme.gold600);
      expect(theme.bottomNavigationBarTheme.unselectedItemColor, GoldFitTheme.textLight);
    });

    testWidgets('uses IndexedStack to preserve screen state', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify IndexedStack is used
      expect(find.byType(IndexedStack), findsOneWidget);

      // Verify IndexedStack has 5 children (one for each screen)
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.children.length, 5);
    });

    testWidgets('updates IndexedStack index when tab is tapped', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Initial state - Home tab (index 0)
      var indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 0);

      // Tap Wardrobe tab (index 1)
      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();
      
      indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 1);

      // Tap Insights tab (index 4)
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      
      indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 4);
    });

    testWidgets('bottom navigation bar has correct type', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify the theme has the correct type configured
      final context = tester.element(find.byType(AppShell));
      final theme = Theme.of(context);
      
      expect(theme.bottomNavigationBarTheme.type, BottomNavigationBarType.fixed);
    });

    testWidgets('displays both outlined and filled icons', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Home tab should show filled icon (active)
      expect(find.byIcon(Icons.home), findsOneWidget);
      
      // Other tabs should show outlined icons (inactive)
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.insights_outlined), findsOneWidget);

      // Tap Wardrobe tab
      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();

      // Wardrobe should now show filled icon
      expect(find.byIcon(Icons.checkroom), findsOneWidget);
      
      // Home should now show outlined icon
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });
  });
}
