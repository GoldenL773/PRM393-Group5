import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';

/// Abstract repository interface for ClothingItem data operations.
/// 
/// Defines the contract for CRUD operations and queries on clothing items.
/// Implementations should handle database operations, error handling, and
/// data transformation between domain models and database records.
abstract class ClothingRepository {
  /// Creates a new clothing item in the repository.
  /// 
  /// Returns the created item with all fields preserved.
  /// Throws DatabaseException if the operation fails.
  Future<ClothingItem> create(ClothingItem item);

  /// Retrieves a clothing item by its unique identifier.
  /// 
  /// Returns the item if found, null otherwise.
  /// Throws DatabaseException if the query fails.
  Future<ClothingItem?> getById(String id);

  /// Retrieves all clothing items from the repository.
  /// 
  /// Returns items ordered by created_at descending (newest first).
  /// Throws DatabaseException if the query fails.
  Future<List<ClothingItem>> getAll();

  /// Retrieves all clothing items of a specific type.
  /// 
  /// Returns items matching the specified type, ordered by created_at descending.
  /// Throws DatabaseException if the query fails.
  Future<List<ClothingItem>> getByType(ClothingType type);

  /// Retrieves clothing items matching the specified filters.
  /// 
  /// Applies all active filters (colors, seasons) and returns matching items.
  /// Returns items ordered by created_at descending.
  /// Throws DatabaseException if the query fails.
  Future<List<ClothingItem>> getByFilters(FilterState filters);

  /// Updates an existing clothing item in the repository.
  /// 
  /// Updates the item and sets the updated_at timestamp.
  /// Returns the updated item.
  /// Throws DatabaseException if the item doesn't exist or update fails.
  Future<ClothingItem> update(ClothingItem item);

  /// Deletes a clothing item from the repository.
  /// 
  /// Cascades deletion to related records in junction tables.
  /// Throws DatabaseException if the item doesn't exist or deletion fails.
  Future<void> delete(String id);

  /// Creates multiple clothing items in a single transaction.
  /// 
  /// Either all items are created successfully, or none are (atomic operation).
  /// Returns the list of created items.
  /// Throws DatabaseException if any insertion fails.
  Future<List<ClothingItem>> batchCreate(List<ClothingItem> items);

  /// Watches all clothing items for changes.
  /// 
  /// Returns a stream that emits the current list of items whenever data changes.
  /// Useful for reactive UI updates.
  Stream<List<ClothingItem>> watchAll();
}
