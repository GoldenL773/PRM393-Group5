import 'package:goldfit_frontend/shared/models/clothing_item.dart';

/// Represents the current filter state for wardrobe browsing.
/// 
/// Contains lists of active color and season filters that can be applied
/// to clothing items to narrow down the displayed wardrobe.
class FilterState {
  final List<String> colors;
  final List<Season> seasons;

  FilterState({
    this.colors = const [],
    this.seasons = const [],
  });

  /// Returns true if no filters are currently active.
  bool get isEmpty => colors.isEmpty && seasons.isEmpty;

  /// Returns the total count of active filters (colors + seasons).
  int get activeFilterCount => colors.length + seasons.length;

  /// Factory constructor for creating an empty filter state.
  factory FilterState.empty() => FilterState();

  /// Checks if a given ClothingItem matches all active filters.
  /// 
  /// Returns true if:
  /// - No filters are active (isEmpty), OR
  /// - The item's color matches one of the color filters (if any color filters are active), AND
  /// - The item has at least one season that matches the season filters (if any season filters are active)
  bool matches(ClothingItem item) {
    // If no filters are active, all items match
    if (isEmpty) {
      return true;
    }

    // Check color filter (if active)
    bool colorMatches = colors.isEmpty || colors.contains(item.color);

    // Check season filter (if active)
    bool seasonMatches = seasons.isEmpty || 
        item.seasons.any((season) => seasons.contains(season));

    // Item must match all active filter types
    return colorMatches && seasonMatches;
  }
}
