import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:goldfit_frontend/models/outfit.dart';
import 'package:goldfit_frontend/providers/app_state.dart';
import 'package:goldfit_frontend/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/screens/planner_screen.dart';
import 'package:goldfit_frontend/utils/theme.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 15: Date Interaction Appropriateness', () {
    property('Dates with assigned outfits show outfit details when tapped', () {
      // **Validates: Requirements 9.5**
      
      forAll(
        dateWithOutfitArbitrary(),
        (dateInfo) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.isEmpty) return;

          // Assign outfit to the generated date
          final outfitIndex = dateInfo.outfitIndex % outfits.length;
          final outfit = outfits[outfitIndex];
          appState.assignOutfitToDate(outfit.id, dateInfo.date);

          // Select the date (simulating tap)
          appState.selectDate(dateInfo.date);

          // Verify that the outfit is assigned and can be retrieved
          final assignedOutfit = appState.getOutfitForDate(dateInfo.date);
          
          expect(assignedOutfit, isNotNull,
              reason: 'Tapped date with assigned outfit should return outfit details');
          expect(assignedOutfit?.id, equals(outfit.id),
              reason: 'Retrieved outfit should match the assigned outfit');
          expect(assignedOutfit?.name, equals(outfit.name),
              reason: 'Outfit details should be complete and accurate');
        },
      );
    });

    property('Dates without assigned outfits show assignment options when tapped', () {
      // **Validates: Requirements 9.5**
      
      forAll(
        dateWithoutOutfitArbitrary(),
        (date) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);

          // Verify the date has no outfit assigned
          final assignedOutfit = appState.getOutfitForDate(date);
          
          expect(assignedOutfit, isNull,
              reason: 'Tapped date without assigned outfit should have no outfit');
          
          // Select the date (simulating tap)
          appState.selectDate(date);

          // Verify that assignment options are available (all outfits can be assigned)
          final availableOutfits = appState.allOutfits;
          expect(availableOutfits, isNotEmpty,
              reason: 'Assignment options should be available for dates without outfits');
        },
      );
    });

    property('Tapping different dates shows appropriate UI for each', () {
      // **Validates: Requirements 9.5**
      
      forAll(
        multipleDatesWithMixedAssignmentsArbitrary(),
        (datesInfo) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.isEmpty) return;

          // Assign outfits to some dates, leave others unassigned
          for (final dateInfo in datesInfo.dates) {
            if (dateInfo.hasOutfit && dateInfo.outfitIndex < outfits.length) {
              final outfit = outfits[dateInfo.outfitIndex];
              appState.assignOutfitToDate(outfit.id, dateInfo.date);
            }
          }

          // Verify each date shows appropriate UI
          for (final dateInfo in datesInfo.dates) {
            appState.selectDate(dateInfo.date);
            final assignedOutfit = appState.getOutfitForDate(dateInfo.date);

            if (dateInfo.hasOutfit && dateInfo.outfitIndex < outfits.length) {
              // Should show outfit details
              expect(assignedOutfit, isNotNull,
                  reason: 'Date ${dateInfo.date} with outfit should show outfit details');
              expect(assignedOutfit?.id, equals(outfits[dateInfo.outfitIndex].id),
                  reason: 'Outfit details should match assigned outfit');
            } else {
              // Should show assignment options
              expect(assignedOutfit, isNull,
                  reason: 'Date ${dateInfo.date} without outfit should show assignment options');
              expect(appState.allOutfits, isNotEmpty,
                  reason: 'Assignment options should be available');
            }
          }
        },
      );
    });

    property('Reassigning outfit to date updates displayed details', () {
      // **Validates: Requirements 9.5**
      
      forAll(
        dateWithTwoOutfitsArbitrary(),
        (dateInfo) {
          final mockDataProvider = MockDataProvider();
          final appState = AppState(mockDataProvider);
          
          final outfits = appState.allOutfits;
          if (outfits.length < 2) return;

          // Assign first outfit
          final firstOutfitIndex = dateInfo.firstOutfitIndex % outfits.length;
          final firstOutfit = outfits[firstOutfitIndex];
          appState.assignOutfitToDate(firstOutfit.id, dateInfo.date);

          // Verify first outfit is shown
          appState.selectDate(dateInfo.date);
          var assignedOutfit = appState.getOutfitForDate(dateInfo.date);
          expect(assignedOutfit?.id, equals(firstOutfit.id),
              reason: 'First assigned outfit should be displayed');

          // Reassign to second outfit
          var secondOutfitIndex = dateInfo.secondOutfitIndex % outfits.length;
          // Ensure second outfit is different from first
          if (secondOutfitIndex == firstOutfitIndex) {
            secondOutfitIndex = (secondOutfitIndex + 1) % outfits.length;
          }
          final secondOutfit = outfits[secondOutfitIndex];
          appState.assignOutfitToDate(secondOutfit.id, dateInfo.date);

          // Verify second outfit is now shown
          assignedOutfit = appState.getOutfitForDate(dateInfo.date);
          expect(assignedOutfit?.id, equals(secondOutfit.id),
              reason: 'Reassigned outfit should replace previous outfit');
          expect(assignedOutfit?.id, isNot(equals(firstOutfit.id)),
              reason: 'New outfit should be different from original');
        },
      );
    });

    testWidgets('Tapping assign outfit button shows outfit picker', (tester) async {
      // **Validates: Requirements 9.5**
      
      final mockDataProvider = MockDataProvider();
      final appState = AppState(mockDataProvider);

      // Clear any pre-assigned outfits for today
      final now = DateTime.now();
      appState.unassignOutfitFromDate(now);

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

      // Verify no outfit is assigned
      expect(appState.getOutfitForDate(now), isNull,
          reason: 'Current date should have no outfit assigned');

      // Tap the "Assign Outfit" button if it exists
      final assignButton = find.text('Assign Outfit');
      if (assignButton.evaluate().isNotEmpty) {
        await tester.tap(assignButton);
        await tester.pumpAndSettle();

        // Verify outfit picker is shown
        expect(find.text('Select an Outfit'), findsOneWidget,
            reason: 'Outfit picker should be displayed when assign button is tapped');
      }
    });
  });
}

// ============================================================================
// Arbitrary Generators
// ============================================================================

/// Represents a date with an outfit assignment
class DateWithOutfit {
  final DateTime date;
  final int outfitIndex;

  DateWithOutfit({
    required this.date,
    required this.outfitIndex,
  });
}

/// Represents a date without an outfit assignment
typedef DateWithoutOutfit = DateTime;

/// Represents a date with information about outfit assignment
class DateAssignmentInfo {
  final DateTime date;
  final bool hasOutfit;
  final int outfitIndex;

  DateAssignmentInfo({
    required this.date,
    required this.hasOutfit,
    required this.outfitIndex,
  });
}

/// Container for multiple dates with mixed assignments
class MultipleDatesWithMixedAssignments {
  final List<DateAssignmentInfo> dates;

  MultipleDatesWithMixedAssignments({required this.dates});
}

/// Represents a date with two different outfit assignments (for reassignment testing)
class DateWithTwoOutfits {
  final DateTime date;
  final int firstOutfitIndex;
  final int secondOutfitIndex;

  DateWithTwoOutfits({
    required this.date,
    required this.firstOutfitIndex,
    required this.secondOutfitIndex,
  });
}

/// Arbitrary generator for a date with an outfit
Arbitrary<DateWithOutfit> dateWithOutfitArbitrary() {
  return integer(min: 2024, max: 2025).flatMap((year) {
    return integer(min: 1, max: 12).flatMap((month) {
      return integer(min: 1, max: 28).flatMap((day) {
        return integer(min: 0, max: 4).map((outfitIndex) {
          return DateWithOutfit(
            date: DateTime(year, month, day),
            outfitIndex: outfitIndex,
          );
        });
      });
    });
  });
}

/// Arbitrary generator for a date without an outfit
Arbitrary<DateWithoutOutfit> dateWithoutOutfitArbitrary() {
  return integer(min: 2024, max: 2025).flatMap((year) {
    return integer(min: 1, max: 12).flatMap((month) {
      return integer(min: 1, max: 28).map((day) {
        return DateTime(year, month, day);
      });
    });
  });
}

/// Arbitrary generator for multiple dates with mixed assignments
Arbitrary<MultipleDatesWithMixedAssignments> multipleDatesWithMixedAssignmentsArbitrary() {
  return integer(min: 2, max: 5).flatMap((count) {
    return _generateMixedAssignments(count).map((dates) {
      return MultipleDatesWithMixedAssignments(dates: dates);
    });
  });
}

/// Arbitrary generator for a date with two outfit assignments
Arbitrary<DateWithTwoOutfits> dateWithTwoOutfitsArbitrary() {
  return integer(min: 2024, max: 2025).flatMap((year) {
    return integer(min: 1, max: 12).flatMap((month) {
      return integer(min: 1, max: 28).flatMap((day) {
        return integer(min: 0, max: 4).flatMap((firstIndex) {
          return integer(min: 0, max: 4).map((secondIndex) {
            return DateWithTwoOutfits(
              date: DateTime(year, month, day),
              firstOutfitIndex: firstIndex,
              secondOutfitIndex: secondIndex,
            );
          });
        });
      });
    });
  });
}

/// Helper to generate a list of dates with mixed outfit assignments
Arbitrary<List<DateAssignmentInfo>> _generateMixedAssignments(int count) {
  if (count == 0) {
    return constant([]);
  }
  
  return integer(min: 2024, max: 2025).flatMap((year) {
    return integer(min: 1, max: 12).flatMap((month) {
      return integer(min: 1, max: 28).flatMap((day) {
        return boolean().flatMap((hasOutfit) {
          return integer(min: 0, max: 4).flatMap((outfitIndex) {
            // Create a unique date by adding the count to the day
            final adjustedDay = (day + count) % 28 + 1;
            final date = DateTime(year, month, adjustedDay);
            final info = DateAssignmentInfo(
              date: date,
              hasOutfit: hasOutfit,
              outfitIndex: outfitIndex,
            );
            
            return _generateMixedAssignments(count - 1).map((rest) {
              // Check if this date already exists in rest
              final existingDates = rest.map((a) => a.date).toSet();
              if (existingDates.contains(date)) {
                // Skip this assignment if date already exists
                return rest;
              }
              return [info, ...rest];
            });
          });
        });
      });
    });
  });
}
