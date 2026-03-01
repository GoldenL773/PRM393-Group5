import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../models/filter_state.dart';
import '../providers/app_state.dart';
import '../widgets/clothing_item_card.dart';
import '../widgets/category_tab.dart';
import '../widgets/filter_chip.dart' as custom;
import '../utils/theme.dart';
import '../utils/navigation_manager.dart';

/// Wardrobe screen displaying clothing items in a grid with category tabs and filtering.
/// 
/// This screen shows:
/// - App bar with filter button
/// - Category tabs (All, Tops, Bottoms, Outerwear, Shoes, Accessories)
/// - Active filter chips (when filters are applied)
/// - Responsive grid: 2 columns in portrait mode, 3 columns in landscape mode
/// 
/// The grid automatically adapts to orientation changes and preserves scroll position.
/// 
/// Requirements: 4.1, 4.2, 4.5, 5.1, 15.1, 15.2, 15.3, 15.4
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final filteredItems = appState.filteredItems;
    final selectedCategory = appState.selectedCategory;
    final filterState = appState.filterState;

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                // Show badge if filters are active
                if (!filterState.isEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: GoldFitTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${filterState.activeFilterCount}',
                        style: const TextStyle(
                          color: GoldFitTheme.textDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              _showFilterBottomSheet(context, appState);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          _buildCategoryTabs(appState, selectedCategory),
          
          // Active filter chips (if filters are active)
          if (!filterState.isEmpty)
            _buildActiveFilterChips(appState, filterState),
          
          // Grid view of clothing items
          Expanded(
            child: _buildItemGrid(filteredItems),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal scrollable category tabs.
  Widget _buildCategoryTabs(AppState appState, ClothingType? selectedCategory) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: GoldFitTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "All" tab
            CategoryTab(
              label: 'All',
              isActive: selectedCategory == null,
              onTap: () => appState.selectCategory(null),
            ),
            const SizedBox(width: 8),
            
            // Category tabs
            ...ClothingType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryTab(
                  label: _getCategoryLabel(type),
                  isActive: selectedCategory == type,
                  onTap: () => appState.selectCategory(type),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the active filter chips section.
  Widget _buildActiveFilterChips(AppState appState, filterState) {
    final chips = <Widget>[];
    
    // Add color filter chips
    for (final color in filterState.colors) {
      chips.add(
        custom.FilterChip(
          label: color,
          onRemove: () {
            _removeColorFilter(appState, color);
          },
        ),
      );
    }
    
    // Add season filter chips
    for (final season in filterState.seasons) {
      chips.add(
        custom.FilterChip(
          label: _getSeasonLabel(season),
          onRemove: () {
            _removeSeasonFilter(appState, season);
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: GoldFitTheme.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  /// Builds the grid of clothing items with responsive columns based on orientation.
  /// 2 columns in portrait mode, 3 columns in landscape mode.
  Widget _buildItemGrid(List<ClothingItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: GoldFitTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GoldFitTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: GoldFitTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    // Detect orientation using MediaQuery
    final orientation = MediaQuery.of(context).orientation;
    final crossAxisCount = orientation == Orientation.portrait ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount, // 2 columns in portrait, 3 in landscape
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Slightly taller than wide
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ClothingItemCard(
          item: item,
          onTap: () {
            // Navigate to item detail screen with item ID
            final navigationManager = Provider.of<NavigationManager>(context, listen: false);
            navigationManager.navigateToItemDetail(context, item.id);
          },
        );
      },
    );
  }

  /// Returns a human-readable label for a clothing type.
  String _getCategoryLabel(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
        return 'Tops';
      case ClothingType.bottoms:
        return 'Bottoms';
      case ClothingType.outerwear:
        return 'Outerwear';
      case ClothingType.shoes:
        return 'Shoes';
      case ClothingType.accessories:
        return 'Accessories';
    }
  }

  /// Returns a human-readable label for a season.
  String _getSeasonLabel(season) {
    return season.toString().split('.').last.substring(0, 1).toUpperCase() +
        season.toString().split('.').last.substring(1);
  }

  /// Shows the filter bottom sheet with color and season options.
  void _showFilterBottomSheet(BuildContext context, AppState appState) {
    // Available colors from MockDataProvider
    final availableColors = [
      'Black', 'White', 'Navy', 'Gray', 'Beige', 'Brown',
      'Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Purple'
    ];

    // Available seasons
    final availableSeasons = Season.values;

    // Track selected filters locally
    final selectedColors = List<String>.from(appState.filterState.colors);
    final selectedSeasons = List<Season>.from(appState.filterState.seasons);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: GoldFitTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GoldFitTheme.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedColors.clear();
                            selectedSeasons.clear();
                          });
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: GoldFitTheme.gold600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color section
                        const Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GoldFitTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableColors.map((color) {
                            final isSelected = selectedColors.contains(color);
                            return FilterChip(
                              label: Text(color),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedColors.add(color);
                                  } else {
                                    selectedColors.remove(color);
                                  }
                                });
                              },
                              backgroundColor: GoldFitTheme.surfaceLight,
                              selectedColor: GoldFitTheme.yellow100,
                              checkmarkColor: GoldFitTheme.gold600,
                              side: BorderSide(
                                color: isSelected 
                                    ? GoldFitTheme.primary 
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? GoldFitTheme.gold600 
                                    : GoldFitTheme.textMedium,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Season section
                        const Text(
                          'Season',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GoldFitTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableSeasons.map((season) {
                            final isSelected = selectedSeasons.contains(season);
                            return FilterChip(
                              label: Text(_getSeasonLabel(season)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedSeasons.add(season);
                                  } else {
                                    selectedSeasons.remove(season);
                                  }
                                });
                              },
                              backgroundColor: GoldFitTheme.surfaceLight,
                              selectedColor: GoldFitTheme.yellow100,
                              checkmarkColor: GoldFitTheme.gold600,
                              side: BorderSide(
                                color: isSelected 
                                    ? GoldFitTheme.primary 
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? GoldFitTheme.gold600 
                                    : GoldFitTheme.textMedium,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Apply button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters to AppState
                      appState.applyFilters(FilterState(
                        colors: selectedColors,
                        seasons: selectedSeasons,
                      ));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoldFitTheme.primary,
                      foregroundColor: GoldFitTheme.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Removes a specific color filter.
  void _removeColorFilter(AppState appState, String color) {
    final newColors = List<String>.from(appState.filterState.colors)
      ..remove(color);
    appState.applyFilters(FilterState(
      colors: newColors,
      seasons: appState.filterState.seasons,
    ));
  }

  /// Removes a specific season filter.
  void _removeSeasonFilter(AppState appState, Season season) {
    final newSeasons = List<Season>.from(appState.filterState.seasons)
      ..remove(season);
    appState.applyFilters(FilterState(
      colors: appState.filterState.colors,
      seasons: newSeasons,
    ));
  }
}
