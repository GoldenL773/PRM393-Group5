import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/core/routing/app_shell.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 3: Active Tab Highlighting', () {
    testWidgets('Home screen shows Home tab as highlighted', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Verify Home screen is displayed
      expect(find.text('Home'), findsOneWidget);

      // Verify Home tab (index 0) is highlighted
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, equals(0),
          reason: 'Home tab should be highlighted when Home screen is displayed');
    });

    testWidgets('Wardrobe screen shows Wardrobe tab as highlighted', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Navigate to Wardrobe
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();

      // Verify Wardrobe screen is displayed
      expect(find.text('Wardrobe'), findsOneWidget);

      // Verify Wardrobe tab (index 1) is highlighted
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, equals(1),
          reason: 'Wardrobe tab should be highlighted when Wardrobe screen is displayed');
    });

    testWidgets('Try-On screen shows Try-On tab as highlighted', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Navigate to Try-On
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify Try-On screen is displayed
      expect(find.text('Try-On'), findsOneWidget);

      // Verify Try-On tab (index 2) is highlighted
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, equals(2),
          reason: 'Try-On tab should be highlighted when Try-On screen is displayed');
    });

    testWidgets('Planner screen shows Planner tab as highlighted', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Navigate to Planner
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Verify Planner screen is displayed
      expect(find.text('Planner'), findsOneWidget);

      // Verify Planner tab (index 3) is highlighted
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, equals(3),
          reason: 'Planner tab should be highlighted when Planner screen is displayed');
    });

    testWidgets('Insights screen shows Insights tab as highlighted', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Navigate to Insights
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();

      // Verify Insights screen is displayed
      expect(find.text('Insights'), findsOneWidget);

      // Verify Insights tab (index 4) is highlighted
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, equals(4),
          reason: 'Insights tab should be highlighted when Insights screen is displayed');
    });

    property('For any tab index, the corresponding tab is highlighted', () {
      // **Validates: Requirements 1.4**
      
      forAll(
        integer(min: 0, max: 4),
        (tabIndex) { // Removed async here
          testWidgets('Tab highlighting for index $tabIndex', (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: GoldFitTheme.lightTheme,
                home: const AppShell(),
              ),
            );

            // Map tab index to icon and screen name
            final tabData = [
              (Icons.home_outlined, 'Home'),
              (Icons.checkroom_outlined, 'Wardrobe'),
              (Icons.person_outline, 'Try-On'),
              (Icons.calendar_today_outlined, 'Planner'),
              (Icons.insights_outlined, 'Insights'),
            ];

            final (icon, screenName) = tabData[tabIndex];

            // Navigate to the tab
            await tester.tap(find.byIcon(icon));
            await tester.pumpAndSettle();

            // Verify the screen is displayed
            expect(find.text(screenName), findsOneWidget,
                reason: 'Screen $screenName should be displayed');

            // Verify the corresponding tab is highlighted
            final navBar = tester.widget<BottomNavigationBar>(
              find.byType(BottomNavigationBar),
            );
            expect(navBar.currentIndex, equals(tabIndex),
                reason: 'Tab at index $tabIndex should be highlighted when $screenName screen is displayed');
          });
        },
      );
    });

    testWidgets('Tab highlighting updates correctly during navigation sequence', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Define navigation sequence
      final navigationSequence = [
        (Icons.checkroom_outlined, 'Wardrobe', 1),
        (Icons.person_outline, 'Try-On', 2),
        (Icons.calendar_today_outlined, 'Planner', 3),
        (Icons.insights_outlined, 'Insights', 4),
        (Icons.home_outlined, 'Home', 0),
      ];

      for (final (icon, screenName, expectedIndex) in navigationSequence) {
        // Navigate to the tab
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();

        // Verify the screen is displayed
        expect(find.text(screenName), findsOneWidget,
            reason: 'Screen $screenName should be displayed');

        // Verify the correct tab is highlighted
        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, equals(expectedIndex),
            reason: 'Tab at index $expectedIndex should be highlighted when $screenName screen is displayed');
      }
    });

    testWidgets('Visual highlighting is applied to active tab', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Get the bottom navigation bar
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      // Verify selectedItemColor is set (from theme)
      expect(navBar.selectedItemColor, isNotNull,
          reason: 'Selected item color should be defined for visual highlighting');

      // Verify unselectedItemColor is different from selectedItemColor
      expect(navBar.unselectedItemColor, isNot(equals(navBar.selectedItemColor)),
          reason: 'Unselected item color should be different from selected item color for visual distinction');

      // Navigate to different tabs and verify highlighting
      final tabs = [
        (Icons.checkroom_outlined, 1),
        (Icons.person_outline, 2),
        (Icons.calendar_today_outlined, 3),
      ];

      for (final (icon, expectedIndex) in tabs) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();

        final updatedNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(updatedNavBar.currentIndex, equals(expectedIndex),
            reason: 'Tab at index $expectedIndex should be visually highlighted');
      }
    });

    testWidgets('Tab highlighting persists after multiple navigation actions', (tester) async {
      // **Validates: Requirements 1.4**
      
      final sequences = [
        [0, 1, 2, 3, 4],
        [4, 2, 0, 1, 3],
        [1, 3, 2, 4, 0, 2],
      ];

      for (final navigationSequence in sequences) {
        await tester.pumpWidget(
          MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const AppShell(),
          ),
        );

        final icons = [
          Icons.home_outlined,
          Icons.checkroom_outlined,
          Icons.person_outline,
          Icons.calendar_today_outlined,
          Icons.insights_outlined,
        ];

        final screenNames = ['Home', 'Wardrobe', 'Try-On', 'Planner', 'Insights'];

        // Navigate through the sequence
        for (final tabIndex in navigationSequence) {
          await tester.tap(find.byIcon(icons[tabIndex]));
          await tester.pumpAndSettle();

          // Verify the correct screen is displayed
          expect(find.text(screenNames[tabIndex]), findsOneWidget,
              reason: 'Screen ${screenNames[tabIndex]} should be displayed');

          // Verify the correct tab is highlighted
          final navBar = tester.widget<BottomNavigationBar>(
            find.byType(BottomNavigationBar),
          );
          expect(navBar.currentIndex, equals(tabIndex),
              reason: 'Tab at index $tabIndex should be highlighted after navigation');
        }
      }
    });

    testWidgets('Only one tab is highlighted at a time', (tester) async {
      // **Validates: Requirements 1.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: const AppShell(),
        ),
      );

      // Navigate through all tabs
      final icons = [
        Icons.home_outlined,
        Icons.checkroom_outlined,
        Icons.person_outline,
        Icons.calendar_today_outlined,
        Icons.insights_outlined,
      ];

      for (int i = 0; i < icons.length; i++) {
        await tester.tap(find.byIcon(icons[i]));
        await tester.pumpAndSettle();

        // Verify only one tab is highlighted
        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, equals(i),
            reason: 'Only tab at index $i should be highlighted');

        // Verify currentIndex is within valid range
        expect(navBar.currentIndex, greaterThanOrEqualTo(0),
            reason: 'Current index should be non-negative');
        expect(navBar.currentIndex, lessThan(navBar.items.length),
            reason: 'Current index should be less than number of tabs');
      }
    });
  });
}
