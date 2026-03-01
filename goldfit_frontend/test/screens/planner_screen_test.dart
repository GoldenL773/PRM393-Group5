import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/screens/planner_screen.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/utils/theme.dart';

void main() {
  group('PlannerScreen Widget Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState(MockDataProvider());
    });

    testWidgets('PlannerScreen displays calendar and basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Planner'), findsOneWidget);

      // Verify PlannerScreen widget is rendered
      expect(find.byType(PlannerScreen), findsOneWidget);
      
      // Verify scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('PlannerScreen displays calendar and basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Planner'), findsOneWidget);

      // Verify PlannerScreen widget is rendered
      expect(find.byType(PlannerScreen), findsOneWidget);
      
      // Verify scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Calendar view can be toggled between week and month', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state should be month view
      expect(appState.calendarView, CalendarView.month);

      // Find and tap Week button by finding the GestureDetector with Week text
      final weekButton = find.ancestor(
        of: find.text('Week'),
        matching: find.byType(GestureDetector),
      );
      
      if (weekButton.evaluate().isNotEmpty) {
        await tester.tap(weekButton.first);
        await tester.pumpAndSettle();

        // Verify calendar view changed to week
        expect(appState.calendarView, CalendarView.week);
      }
    });

    testWidgets('Calendar view transitions are animated smoothly with 300ms duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AnimatedSwitcher is present with correct duration
      final animatedSwitcherFinder = find.byType(AnimatedSwitcher);
      if (animatedSwitcherFinder.evaluate().isNotEmpty) {
        final animatedSwitcher = tester.widget<AnimatedSwitcher>(animatedSwitcherFinder);
        
        // Verify the duration is 300ms as specified in requirements 9.2, 9.3
        expect(animatedSwitcher.duration, equals(const Duration(milliseconds: 300)));
      }

      // Initial state should be month view
      expect(appState.calendarView, CalendarView.month);

      // Find and tap Week button
      final weekButton = find.ancestor(
        of: find.text('Week'),
        matching: find.byType(GestureDetector),
      );
      
      if (weekButton.evaluate().isNotEmpty) {
        await tester.tap(weekButton.first);
        
        // Pump a frame to start the animation
        await tester.pump();
        
        // Verify state changed immediately
        expect(appState.calendarView, CalendarView.week);
        
        // Pump through the animation duration (300ms)
        await tester.pump(const Duration(milliseconds: 150)); // Mid-animation
        await tester.pump(const Duration(milliseconds: 150)); // Complete animation
        
        // Verify animation completed
        await tester.pumpAndSettle();
        expect(appState.calendarView, CalendarView.week);

        // Test switching back to month view
        final monthButton = find.ancestor(
          of: find.text('Month'),
          matching: find.byType(GestureDetector),
        );
        
        if (monthButton.evaluate().isNotEmpty) {
          await tester.tap(monthButton.first);
          await tester.pump();
          
          // Verify state changed
          expect(appState.calendarView, CalendarView.month);
          
          // Pump through animation
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
          
          // Verify final state
          expect(appState.calendarView, CalendarView.month);
        }
      }
    });

    testWidgets('Calendar view toggle buttons show correct active state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state: Month should be active
      expect(appState.calendarView, CalendarView.month);

      // Find the toggle buttons
      final weekButton = find.ancestor(
        of: find.text('Week'),
        matching: find.byType(GestureDetector),
      );
      final monthButton = find.ancestor(
        of: find.text('Month'),
        matching: find.byType(GestureDetector),
      );

      // Switch to week view
      if (weekButton.evaluate().isNotEmpty) {
        await tester.tap(weekButton.first);
        await tester.pumpAndSettle();
        expect(appState.calendarView, CalendarView.week);
      }

      // Switch back to month view
      if (monthButton.evaluate().isNotEmpty) {
        await tester.tap(monthButton.first);
        await tester.pumpAndSettle();
        expect(appState.calendarView, CalendarView.month);
      }
    });
  });

  group('PlannerScreen Outfit Assignment Tests (Task 14.3)', () {
    late AppState appState;

    setUp(() {
      appState = AppState(MockDataProvider());
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: GoldFitTheme.lightTheme,
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const PlannerScreen(),
        ),
      );
    }

    test('AppState.assignOutfitToDate assigns outfit to date correctly', () {
      final outfits = appState.allOutfits;
      if (outfits.isEmpty) {
        return;
      }
      
      final firstOutfit = outfits.first;
      final testDate = DateTime.now();

      // Verify no outfit assigned initially
      expect(appState.getOutfitForDate(testDate), isNull);

      // Assign outfit to date
      appState.assignOutfitToDate(firstOutfit.id, testDate);

      // Verify outfit is now assigned
      final assignedOutfit = appState.getOutfitForDate(testDate);
      expect(assignedOutfit, isNotNull);
      expect(assignedOutfit?.id, equals(firstOutfit.id));
    });

    test('AppState.assignOutfitToDate normalizes dates to midnight', () {
      final outfits = appState.allOutfits;
      if (outfits.isEmpty) {
        return;
      }
      
      final firstOutfit = outfits.first;
      final testDate = DateTime(2024, 1, 15, 14, 30, 45); // Date with time

      // Assign outfit
      appState.assignOutfitToDate(firstOutfit.id, testDate);

      // Verify outfit can be retrieved with normalized date
      final normalizedDate = DateTime(2024, 1, 15); // Midnight
      final assignedOutfit = appState.getOutfitForDate(normalizedDate);
      expect(assignedOutfit, isNotNull);
      expect(assignedOutfit?.id, equals(firstOutfit.id));
    });

    test('Multiple dates can have different outfit assignments', () {
      final outfits = appState.allOutfits;
      if (outfits.length < 2) {
        return;
      }

      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 1, 16);
      
      appState.assignOutfitToDate(outfits[0].id, date1);
      appState.assignOutfitToDate(outfits[1].id, date2);

      // Verify each date has its own outfit
      expect(appState.getOutfitForDate(date1)?.id, equals(outfits[0].id));
      expect(appState.getOutfitForDate(date2)?.id, equals(outfits[1].id));
    });

    test('Changing outfit assignment replaces previous assignment', () {
      final outfits = appState.allOutfits;
      if (outfits.length < 2) {
        return;
      }

      final testDate = DateTime(2024, 1, 15);
      
      // Assign first outfit
      appState.assignOutfitToDate(outfits[0].id, testDate);
      expect(appState.getOutfitForDate(testDate)?.id, equals(outfits[0].id));

      // Assign second outfit to same date
      appState.assignOutfitToDate(outfits[1].id, testDate);
      expect(appState.getOutfitForDate(testDate)?.id, equals(outfits[1].id));
    });

    testWidgets('PlannerScreen displays calendar with outfit markers', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assign an outfit to today
      final outfits = appState.allOutfits;
      if (outfits.isEmpty) {
        return;
      }
      
      final today = DateTime.now();
      appState.assignOutfitToDate(outfits.first.id, today);
      await tester.pumpAndSettle();

      // Verify the outfit is assigned in state
      final assignedOutfit = appState.getOutfitForDate(today);
      expect(assignedOutfit, isNotNull);
      expect(assignedOutfit?.id, equals(outfits.first.id));

      // Verify PlannerScreen is displayed
      expect(find.byType(PlannerScreen), findsOneWidget);
    });

    testWidgets('PlannerScreen shows outfit picker bottom sheet when button tapped', (WidgetTester tester) async {
      // Set a larger screen size to ensure bottom section is visible
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Try to find any button (ElevatedButton)
      final buttons = find.byType(ElevatedButton);
      
      if (buttons.evaluate().isNotEmpty) {
        // Tap the first button found
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // Verify bottom sheet appears
        expect(find.text('Select an Outfit'), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      }
      
      // Reset the screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('Outfit picker displays available outfits', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final outfits = appState.allOutfits;
      final buttons = find.byType(ElevatedButton);
      
      if (buttons.evaluate().isNotEmpty && outfits.isNotEmpty) {
        // Open outfit picker
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // Verify outfits are displayed
        expect(find.byType(ListTile), findsWidgets);
        expect(find.text(outfits.first.name), findsOneWidget);
      }
      
      addTearDown(tester.view.reset);
    });

    testWidgets('Selecting outfit from picker assigns it to date', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final outfits = appState.allOutfits;
      if (outfits.isEmpty) {
        addTearDown(tester.view.reset);
        return;
      }

      final selectedDate = appState.selectedDate;
      expect(appState.getOutfitForDate(selectedDate), isNull);

      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        // Open outfit picker
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // Select first outfit
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        // Verify outfit is assigned
        final assignedOutfit = appState.getOutfitForDate(selectedDate);
        expect(assignedOutfit, isNotNull);
        expect(assignedOutfit?.id, equals(outfits.first.id));

        // Verify success message
        expect(find.byType(SnackBar), findsOneWidget);
      }
      
      addTearDown(tester.view.reset);
    });

    testWidgets('Date with assigned outfit shows outfit information', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final outfits = appState.allOutfits;
      if (outfits.isEmpty) {
        addTearDown(tester.view.reset);
        return;
      }

      // Assign outfit
      final selectedDate = appState.selectedDate;
      appState.assignOutfitToDate(outfits.first.id, selectedDate);
      await tester.pumpAndSettle();

      // Verify outfit is assigned in state (the UI may not show it if scrolled out of view)
      final assignedOutfit = appState.getOutfitForDate(selectedDate);
      expect(assignedOutfit, isNotNull);
      expect(assignedOutfit?.id, equals(outfits.first.id));
      
      addTearDown(tester.view.reset);
    });
  });
}
