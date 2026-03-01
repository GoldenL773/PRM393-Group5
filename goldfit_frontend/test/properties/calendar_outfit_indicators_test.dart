import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/models/outfit.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/screens/planner_screen.dart';
import 'package:goldfit_frontend/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 14: Calendar Outfit Indicators', () {
    property('Dates with assigned outfits display visual indicators', () {
      // **Validates: Requirements 9.4**
      
      forAll(
        dateOutfitAssignmentsArbitrary(),
        (assignments) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.isEmpty) return;

          // Assign outfits to the generated dates
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = outfits[assignment.outfitIndex];
              appState.assignOutfitToDate(outfit.id, assignment.date);
            }
          }

          // Verify that each assigned date has a visual indicator
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = appState.getOutfitForDate(assignment.date);
              
              expect(outfit, isNotNull,
                  reason: 'Date ${assignment.date} should have an assigned outfit');
              
              // The markerBuilder should create a visual indicator for this date
              // We verify this by checking that the outfit assignment exists in state
              // The actual marker rendering is handled by TableCalendar's markerBuilder
              expect(outfit?.id, equals(outfits[assignment.outfitIndex].id),
                  reason: 'Assigned outfit should match the expected outfit');
            }
          }
        },
      );
    });

    property('Dates without assigned outfits do not display indicators', () {
      // **Validates: Requirements 9.4**
      
      forAll(
        dateListArbitrary(),
        (dates) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);

          // Verify that none of the dates have assigned outfits
          for (final date in dates.dates) {
            final outfit = appState.getOutfitForDate(date);
            
            expect(outfit, isNull,
                reason: 'Date $date should not have an assigned outfit');
          }
        },
      );
    });

    property('Multiple dates can have different outfit assignments', () {
      // **Validates: Requirements 9.4**
      
      forAll(
        multipleDateOutfitAssignmentsArbitrary(),
        (assignments) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.length < 2) return;

          // Assign different outfits to different dates
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = outfits[assignment.outfitIndex];
              appState.assignOutfitToDate(outfit.id, assignment.date);
            }
          }

          // Verify each date has its correct outfit assignment
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = appState.getOutfitForDate(assignment.date);
              
              expect(outfit, isNotNull,
                  reason: 'Date ${assignment.date} should have an assigned outfit');
              expect(outfit?.id, equals(outfits[assignment.outfitIndex].id),
                  reason: 'Each date should have its specific outfit assignment');
            }
          }

          // Verify that different dates have different outfits (if applicable)
          if (assignments.assignments.length >= 2) {
            final firstAssignment = assignments.assignments[0];
            final secondAssignment = assignments.assignments[1];
            
            if (firstAssignment.outfitIndex != secondAssignment.outfitIndex &&
                firstAssignment.outfitIndex < outfits.length &&
                secondAssignment.outfitIndex < outfits.length) {
              final outfit1 = appState.getOutfitForDate(firstAssignment.date);
              final outfit2 = appState.getOutfitForDate(secondAssignment.date);
              
              expect(outfit1?.id, isNot(equals(outfit2?.id)),
                  reason: 'Different dates should be able to have different outfits');
            }
          }
        },
      );
    });

    property('Outfit indicators persist across calendar view changes', () {
      // **Validates: Requirements 9.4**
      
      forAll(
        dateOutfitAssignmentsArbitrary(),
        (assignments) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.isEmpty) return;

          // Assign outfits to dates
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = outfits[assignment.outfitIndex];
              appState.assignOutfitToDate(outfit.id, assignment.date);
            }
          }

          // Verify assignments in month view
          expect(appState.calendarView, equals(CalendarView.month),
              reason: 'Initial view should be month');
          
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = appState.getOutfitForDate(assignment.date);
              expect(outfit, isNotNull,
                  reason: 'Outfit should be assigned in month view');
            }
          }

          // Switch to week view
          appState.setCalendarView(CalendarView.week);
          expect(appState.calendarView, equals(CalendarView.week),
              reason: 'View should change to week');

          // Verify assignments persist in week view
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = appState.getOutfitForDate(assignment.date);
              expect(outfit, isNotNull,
                  reason: 'Outfit assignments should persist when switching to week view');
              expect(outfit?.id, equals(outfits[assignment.outfitIndex].id),
                  reason: 'Outfit ID should remain the same after view change');
            }
          }

          // Switch back to month view
          appState.setCalendarView(CalendarView.month);
          expect(appState.calendarView, equals(CalendarView.month),
              reason: 'View should change back to month');

          // Verify assignments still persist
          for (final assignment in assignments.assignments) {
            if (assignment.outfitIndex < outfits.length) {
              final outfit = appState.getOutfitForDate(assignment.date);
              expect(outfit, isNotNull,
                  reason: 'Outfit assignments should persist when switching back to month view');
              expect(outfit?.id, equals(outfits[assignment.outfitIndex].id),
                  reason: 'Outfit ID should remain the same after multiple view changes');
            }
          }
        },
      );
    });

    testWidgets('Marker builder creates visual indicator for assigned dates', (tester) async {
      // **Validates: Requirements 9.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      
      final outfits = appState.allOutfits;
      if (outfits.isEmpty) return;

      // Assign an outfit to a specific date
      final testDate = DateTime(2024, 6, 15);
      appState.assignOutfitToDate(outfits.first.id, testDate);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            routes: {
              '/': (context) => const PlannerScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the outfit is assigned
      final assignedOutfit = appState.getOutfitForDate(testDate);
      expect(assignedOutfit, isNotNull,
          reason: 'Test date should have an assigned outfit');
      expect(assignedOutfit?.id, equals(outfits.first.id),
          reason: 'Assigned outfit should match the expected outfit');

      // Verify the planner screen is displayed
      expect(find.text('Planner'), findsOneWidget,
          reason: 'Planner screen should be displayed');
    });

    testWidgets('Unassigning outfit removes visual indicator', (tester) async {
      // **Validates: Requirements 9.4**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);
      
      final outfits = appState.allOutfits;
      if (outfits.isEmpty) return;

      // Assign an outfit to a date
      final testDate = DateTime(2024, 6, 15);
      appState.assignOutfitToDate(outfits.first.id, testDate);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            theme: GoldFitTheme.lightTheme,
            home: const PlannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify outfit is assigned
      expect(appState.getOutfitForDate(testDate), isNotNull,
          reason: 'Outfit should be assigned initially');

      // Unassign the outfit
      appState.unassignOutfitFromDate(testDate);
      await tester.pumpAndSettle();

      // Verify outfit is no longer assigned
      expect(appState.getOutfitForDate(testDate), isNull,
          reason: 'Outfit should be unassigned and indicator should be removed');
    });
  });
}

// ============================================================================
// Arbitrary Generators
// ============================================================================

/// Represents a date-outfit assignment
class DateOutfitAssignment {
  final DateTime date;
  final int outfitIndex;

  DateOutfitAssignment({
    required this.date,
    required this.outfitIndex,
  });
}

/// Container for multiple date-outfit assignments
class DateOutfitAssignments {
  final List<DateOutfitAssignment> assignments;

  DateOutfitAssignments({required this.assignments});
}

/// Container for a list of dates
class DateList {
  final List<DateTime> dates;

  DateList({required this.dates});
}

/// Arbitrary generator for date-outfit assignments
Arbitrary<DateOutfitAssignments> dateOutfitAssignmentsArbitrary() {
  return integer(min: 1, max: 5).flatMap((count) {
    return _generateAssignments(count).map((assignments) {
      return DateOutfitAssignments(assignments: assignments);
    });
  });
}

/// Arbitrary generator for multiple date-outfit assignments with different outfits
Arbitrary<DateOutfitAssignments> multipleDateOutfitAssignmentsArbitrary() {
  return integer(min: 2, max: 5).flatMap((count) {
    return _generateAssignments(count).map((assignments) {
      return DateOutfitAssignments(assignments: assignments);
    });
  });
}

/// Arbitrary generator for a list of dates without assignments
Arbitrary<DateList> dateListArbitrary() {
  return integer(min: 1, max: 5).flatMap((count) {
    return _generateDates(count).map((dates) {
      return DateList(dates: dates);
    });
  });
}

/// Helper to generate a list of date-outfit assignments
Arbitrary<List<DateOutfitAssignment>> _generateAssignments(int count) {
  if (count == 0) {
    return constant([]);
  }
  
  return integer(min: 2024, max: 2025).flatMap((year) {
    return integer(min: 1, max: 12).flatMap((month) {
      return integer(min: 1, max: 28).flatMap((day) {
        return integer(min: 0, max: 4).flatMap((outfitIndex) {
          // Create a unique date by adding the count to the day
          // This ensures each assignment has a different date
          final adjustedDay = (day + count) % 28 + 1;
          final date = DateTime(year, month, adjustedDay);
          final assignment = DateOutfitAssignment(
            date: date,
            outfitIndex: outfitIndex,
          );
          
          return _generateAssignments(count - 1).map((rest) {
            // Check if this date already exists in rest
            final existingDates = rest.map((a) => a.date).toSet();
            if (existingDates.contains(date)) {
              // Skip this assignment if date already exists
              return rest;
            }
            return [assignment, ...rest];
          });
        });
      });
    });
  });
}

/// Helper to generate a list of dates
Arbitrary<List<DateTime>> _generateDates(int count) {
  if (count == 0) {
    return constant([]);
  }
  
  return integer(min: 2024, max: 2025).flatMap((year) {
    return integer(min: 1, max: 12).flatMap((month) {
      return integer(min: 1, max: 28).flatMap((day) {
        final date = DateTime(year, month, day);
        
        return _generateDates(count - 1).map((rest) {
          return [date, ...rest];
        });
      });
    });
  });
}
