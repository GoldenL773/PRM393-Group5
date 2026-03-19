import 'package:goldfit_frontend/shared/models/outfit.dart';

/// Abstract repository interface for calendar and outfit scheduling operations.
/// 
/// Defines the contract for managing outfit assignments to specific dates,
/// querying calendar data, and handling date-based outfit operations.
/// This repository focuses specifically on calendar-related operations.
abstract class CalendarRepository {
  /// Assigns an outfit to a specific date in the calendar.
  /// 
  /// Inserts a record into the outfit_calendar table.
  /// Enforces unique constraint - only one outfit can be assigned per date.
  /// If the date is in the past, should trigger usage history recording.
  /// Throws DatabaseException if the date already has an outfit assigned or operation fails.
  Future<void> assignOutfitToDate(String outfitId, DateTime date);

  /// Removes the outfit assignment from a specific date.
  /// 
  /// Deletes the corresponding record from the outfit_calendar table.
  /// Throws DatabaseException if the operation fails.
  Future<void> unassignOutfitFromDate(DateTime date);

  /// Retrieves the outfit assigned to a specific date.
  /// 
  /// Joins the outfit_calendar and outfits tables to return the complete outfit.
  /// Returns the outfit if one is assigned, null otherwise.
  /// Throws DatabaseException if the query fails.
  Future<Outfit?> getOutfitForDate(DateTime date);

  /// Retrieves all outfit assignments within a date range.
  /// 
  /// Joins the outfit_calendar and outfits tables to return outfits assigned
  /// between start and end dates (inclusive).
  /// Returns a map of date to outfit for easy lookup.
  /// Throws DatabaseException if the query fails.
  Future<Map<DateTime, Outfit>> getOutfitsForDateRange(
    DateTime start,
    DateTime end,
  );

  /// Checks if a specific date has an outfit assigned.
  /// 
  /// Returns true if an outfit is assigned to the date, false otherwise.
  /// Throws DatabaseException if the query fails.
  Future<bool> hasOutfitForDate(DateTime date);

  /// Retrieves all dates that have outfit assignments within a date range.
  /// 
  /// Returns a list of dates (normalized to midnight) that have outfits assigned.
  /// Useful for calendar UI to highlight dates with assignments.
  /// Throws DatabaseException if the query fails.
  Future<List<DateTime>> getAssignedDatesInRange(
    DateTime start,
    DateTime end,
  );

  /// Clears all outfit assignments within a date range.
  /// 
  /// Deletes all records from outfit_calendar between start and end dates (inclusive).
  /// Useful for bulk operations or clearing a week/month.
  /// Throws DatabaseException if the operation fails.
  Future<void> clearAssignmentsInRange(DateTime start, DateTime end);
}
