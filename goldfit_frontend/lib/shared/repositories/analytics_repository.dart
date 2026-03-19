import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';

/// Abstract repository interface for analytics and usage tracking operations.
/// 
/// Defines the contract for aggregating wardrobe statistics, tracking usage history,
/// and generating insights. Implementations should use efficient queries with indexes
/// and consider caching results for performance.
abstract class AnalyticsRepository {
  /// Retrieves comprehensive wardrobe analytics.
  /// 
  /// Aggregates data from multiple tables to calculate:
  /// - Total item count
  /// - Total wardrobe value
  /// - Most worn items
  /// - Least worn items
  /// 
  /// Returns a WardrobeAnalytics object with all statistics.
  /// Throws DatabaseException if the query fails.
  Future<WardrobeAnalytics> getAnalytics();

  /// Records usage of an outfit on a specific date.
  /// 
  /// Inserts usage_history records for all clothing items in the outfit.
  /// Increments the usage_count for each item.
  /// Should be called when an outfit is assigned to a past date.
  /// Throws DatabaseException if the operation fails.
  Future<void> recordUsage(String outfitId, DateTime date);

  /// Retrieves the most frequently worn clothing items.
  /// 
  /// Joins clothing_items and usage_history tables, orders by usage count descending.
  /// Returns up to [limit] items with the highest usage counts.
  /// Throws DatabaseException if the query fails.
  Future<List<ClothingItem>> getMostWorn(int limit);

  /// Retrieves the least frequently worn clothing items.
  /// 
  /// Queries clothing_items table and orders by usage_count ascending.
  /// Returns up to [limit] items with the lowest usage counts.
  /// Throws DatabaseException if the query fails.
  Future<List<ClothingItem>> getLeastWorn(int limit);

  /// Calculates the count of items by clothing type.
  /// 
  /// Groups clothing items by type and returns a map of type to count.
  /// Example: {ClothingType.tops: 15, ClothingType.bottoms: 10, ...}
  /// Throws DatabaseException if the query fails.
  Future<Map<ClothingType, int>> getItemCountByType();

  /// Calculates the total monetary value of the wardrobe.
  /// 
  /// Sums the price column for all items where price is not null.
  /// Returns 0.0 if no items have prices.
  /// Throws DatabaseException if the query fails.
  Future<double> getTotalValue();

  /// Invalidates the analytics cache.
  /// 
  /// This should be called whenever data changes that would affect
  /// analytics results, such as:
  /// - Adding, updating, or deleting clothing items
  /// - Adding, updating, or deleting outfits
  /// - Recording usage history
  /// 
  /// After invalidation, the next call to getAnalytics() will fetch fresh data.
  void invalidateCache();
}
