import 'package:goldfit_frontend/shared/models/outfit.dart';

/// Abstract repository interface for Outfit data operations.
/// 
/// Defines the contract for CRUD operations, calendar assignments, and queries
/// on outfits. Implementations should handle multi-table operations (outfits and
/// outfit_items junction table) within transactions to ensure data consistency.
abstract class OutfitRepository {
  /// Creates a new outfit in the repository.
  /// 
  /// Inserts records into both the outfits table and outfit_items junction table
  /// within a single transaction to ensure atomicity.
  /// Returns the created outfit with all fields preserved.
  /// Throws DatabaseException if the operation fails.
  Future<Outfit> create(Outfit outfit);

  /// Retrieves an outfit by its unique identifier.
  /// 
  /// Joins the outfits and outfit_items tables to return the complete outfit
  /// with all associated clothing item IDs.
  /// Returns the outfit if found, null otherwise.
  /// Throws DatabaseException if the query fails.
  Future<Outfit?> getById(String id);

  /// Retrieves all outfits from the repository.
  /// 
  /// Returns outfits ordered by created_at descending (newest first).
  /// Throws DatabaseException if the query fails.
  Future<List<Outfit>> getAll();

  /// Retrieves all outfits with a specific vibe.
  /// 
  /// Returns outfits matching the specified vibe (e.g., "Casual", "Work", "Date Night"),
  /// ordered by created_at descending.
  /// Throws DatabaseException if the query fails.
  Future<List<Outfit>> getByVibe(String vibe);

  /// Updates an existing outfit in the repository.
  /// 
  /// Updates the outfit record and synchronizes the outfit_items junction table
  /// within a single transaction.
  /// Returns the updated outfit.
  /// Throws DatabaseException if the outfit doesn't exist or update fails.
  Future<Outfit> update(Outfit outfit);

  /// Deletes an outfit from the repository.
  /// 
  /// Cascades deletion to related records in outfit_items and outfit_calendar tables.
  /// Throws DatabaseException if the outfit doesn't exist or deletion fails.
  Future<void> delete(String id);

  /// Assigns an outfit to a specific date in the calendar.
  /// 
  /// Inserts a record into the outfit_calendar table.
  /// Enforces unique constraint - only one outfit can be assigned per date.
  /// Throws DatabaseException if the date already has an outfit assigned or operation fails.
  Future<void> assignToDate(String outfitId, DateTime date);

  /// Removes the outfit assignment from a specific date.
  /// 
  /// Deletes the corresponding record from the outfit_calendar table.
  /// Throws DatabaseException if the operation fails.
  Future<void> unassignFromDate(DateTime date);

  /// Retrieves the outfit assigned to a specific date.
  /// 
  /// Joins the outfit_calendar and outfits tables to return the complete outfit.
  /// Returns a list containing the assigned outfit, or an empty list if no outfit is assigned.
  /// Throws DatabaseException if the query fails.
  Future<List<Outfit>> getByDate(DateTime date);

  /// Retrieves all outfits assigned within a date range.
  /// 
  /// Joins the outfit_calendar and outfits tables to return outfits assigned
  /// between start and end dates (inclusive).
  /// Returns outfits ordered by assigned_date ascending.
  /// Throws DatabaseException if the query fails.
  Future<List<Outfit>> getByDateRange(DateTime start, DateTime end);

  /// Watches all outfits for changes.
  /// 
  /// Returns a stream that emits the current list of outfits whenever data changes.
  /// Useful for reactive UI updates.
  Stream<List<Outfit>> watchAll();
}
