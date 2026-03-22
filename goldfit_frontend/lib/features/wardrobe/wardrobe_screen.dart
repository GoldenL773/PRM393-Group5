import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/clothing_item_card.dart';
import 'package:goldfit_frontend/shared/widgets/category_tab.dart';
import 'package:goldfit_frontend/shared/widgets/filter_chip.dart' as custom;
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';

/// Wardrobe screen displaying clothing items in a grid with category tabs and filtering.
/// 
/// This screen shows:
/// - App bar with filter button
/// - Category tabs (All, Tops, Bottoms, Outerwear, Shoes, Accessories)
/// - Active filter chips (when filters are applied)
/// - Responsive grid: 2 columns in portrait mode, 3 columns in landscape mode
/// - Loading state while fetching items
/// - Error state if loading fails
/// 
/// The grid automatically adapts to orientation changes and preserves scroll position.
/// 
/// Requirements: 4.1, 4.2, 4.5, 5.1, 14.3, 14.4, 15.1, 15.2, 15.3, 15.4
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  ClothingType? _selectedCategory;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    // Load items when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeViewModel>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobeViewModel>(
      builder: (context, viewModel, child) {
        final filterState = viewModel.filters;
        final filteredItems = _applyLocalFilters(viewModel.items, _selectedCategory, filterState);

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          // Add new clothing button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add new item',
            onPressed: () {
              _showAddClothingOptions(context, viewModel);
            },
          ),
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
              _showFilterBottomSheet(context, viewModel);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          _buildCategoryTabs(_selectedCategory),
          
          // Active filter chips (if filters are active)
          if (!filterState.isEmpty)
            _buildActiveFilterChips(viewModel, filterState),
          
          // Error state
          if (viewModel.error != null)
            _buildErrorState(viewModel),
          
          // Loading or grid view
          Expanded(
            child: viewModel.isLoading
                ? _buildLoadingState()
                : _buildItemGrid(filteredItems),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClothingOptions(context, viewModel),
        backgroundColor: GoldFitTheme.primary,
        child: const Icon(Icons.add, color: GoldFitTheme.textDark),
      ),
    );
      },
    );
  }

  /// Applies local category filtering to items.
  List<ClothingItem> _applyLocalFilters(
    List<ClothingItem> items,
    ClothingType? category,
    FilterState filterState,
  ) {
    var filtered = items;
    
    // Apply category filter
    if (category != null) {
      filtered = filtered.where((item) => item.type == category).toList();
    }
    
    return filtered;
  }

  /// Builds the loading state UI.
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(GoldFitTheme.primary),
      ),
    );
  }

  /// Builds the error state UI.
  Widget _buildErrorState(WardrobeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () => viewModel.loadItems(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal scrollable category tabs.
  Widget _buildCategoryTabs(ClothingType? selectedCategory) {
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
              onTap: () => setState(() => _selectedCategory = null),
            ),
            const SizedBox(width: 8),
            
            // Category tabs
            ...ClothingType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryTab(
                  label: _getCategoryLabel(type),
                  isActive: selectedCategory == type,
                  onTap: () => setState(() => _selectedCategory = type),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the active filter chips section.
  Widget _buildActiveFilterChips(WardrobeViewModel viewModel, FilterState filterState) {
    final chips = <Widget>[];
    
    // Add color filter chips
    for (final color in filterState.colors) {
      chips.add(
        custom.FilterChip(
          label: color,
          onRemove: () {
            _removeColorFilter(viewModel, color);
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
            _removeSeasonFilter(viewModel, season);
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
  String _getSeasonLabel(Season season) {
    return season.toString().split('.').last.substring(0, 1).toUpperCase() +
        season.toString().split('.').last.substring(1);
  }

  /// Shows the filter bottom sheet with color and season options.
  void _showFilterBottomSheet(BuildContext context, WardrobeViewModel viewModel) {
    // Available colors from MockDataProvider
    final availableColors = [
      'Black', 'White', 'Navy', 'Gray', 'Beige', 'Brown',
      'Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Purple'
    ];

    // Available seasons
    final availableSeasons = Season.values;

    // Track selected filters locally
    final selectedColors = List<String>.from(viewModel.filters.colors);
    final selectedSeasons = List<Season>.from(viewModel.filters.seasons);

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
                      // Apply filters to ViewModel
                      viewModel.applyFilters(FilterState(
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
  void _removeColorFilter(WardrobeViewModel viewModel, String color) {
    final newColors = List<String>.from(viewModel.filters.colors)
      ..remove(color);
    viewModel.applyFilters(FilterState(
      colors: newColors,
      seasons: viewModel.filters.seasons,
    ));
  }

  /// Removes a specific season filter.
  void _removeSeasonFilter(WardrobeViewModel viewModel, Season season) {
    final newSeasons = List<Season>.from(viewModel.filters.seasons)
      ..remove(season);
    viewModel.applyFilters(FilterState(
      colors: viewModel.filters.colors,
      seasons: newSeasons,
    ));
  }

  /// Shows options to add clothing (Camera or Gallery).
  void _showAddClothingOptions(BuildContext context, WardrobeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, viewModel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, viewModel);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Picks an image from the given source and saves it.
  Future<void> _pickImage(ImageSource source, WardrobeViewModel viewModel) async {
    if (_isPickingImage) return;
    
    final picker = ImagePicker();
    try {
      setState(() => _isPickingImage = true);
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text("Processing image..."),
                ],
              ),
            ),
          );
        }

        final storage = ImageStorageManager();
        final geminiService = GeminiService();
        String relativePath;

        try {
          final processedBase64 = await geminiService.removeBackground(pickedFile.path);
          if (processedBase64 != null) {
            final bytes = base64Decode(processedBase64);
            relativePath = await storage.saveImageFromBytes(bytes);
          } else {
            // Fallback to original image if background removal fails
            final file = File(pickedFile.path);
            relativePath = await storage.saveImage(file);
          }
        } catch (e) {
          final storage = ImageStorageManager();
          final file = File(pickedFile.path);
          relativePath = await storage.saveImage(file);
        }

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
          _showClothingDetailsDialog(context, relativePath, viewModel);
        }
      }
    } catch (e) {
      if (mounted) {
        // Ensure loading is dismissed if an error occurs and it was shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick/process image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  /// Shows dialog to enter clothing details before saving.
  void _showClothingDetailsDialog(BuildContext context, String imagePath, WardrobeViewModel viewModel) {
    ClothingType selectedType = ClothingType.tops;
    String selectedColor = 'Black';
    final Set<Season> selectedSeasons = {Season.summer};

    final colors = [
      'Black', 'White', 'Navy', 'Gray', 'Beige', 'Brown',
      'Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Purple'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Item Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Dropdown
                DropdownButtonFormField<ClothingType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ClothingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getCategoryLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Color Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedColor,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: colors.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Text(color),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedColor = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Seasons Multi-select
                const Text('Seasons', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: Season.values.map((season) {
                    final isSelected = selectedSeasons.contains(season);
                    return FilterChip(
                      label: Text(_getSeasonLabel(season)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSeasons.add(season);
                          } else if (selectedSeasons.length > 1) {
                            // Require at least one season
                            selectedSeasons.remove(season);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete the image if cancelled
                ImageStorageManager().deleteImage(imagePath);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newItem = ClothingItem(
                  id: const Uuid().v4(),
                  imageUrl: imagePath,
                  type: selectedType,
                  color: selectedColor,
                  seasons: selectedSeasons.toList(),
                  addedDate: DateTime.now(),
                );
                
                viewModel.addItem(newItem);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item added successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
