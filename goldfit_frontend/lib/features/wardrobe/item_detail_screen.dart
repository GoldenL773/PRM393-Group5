import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';

/// Item detail screen displaying full-size clothing image and editable tags
/// Shows image with zoom, tag display/editing, and delete button
/// 
/// Requirements: 6.1, 6.2, 12.5
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract itemId from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final itemId = args?['itemId'] as String?;

    if (itemId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Detail')),
        body: const Center(child: Text('No item ID provided')),
      );
    }

    // Get the item from WardrobeViewModel
    final viewModel = Provider.of<WardrobeViewModel>(context);
    final item = viewModel.items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      extendBodyBehindAppBar: true, // Allow image to go behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: GoldFitTheme.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? Colors.red : GoldFitTheme.textDark,
              ),
              onPressed: () {
                viewModel.toggleFavorite(item.id);
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: GoldFitTheme.textDark),
              onPressed: () {
                final navigationManager = Provider.of<NavigationManager>(context, listen: false);
                navigationManager.navigateToEditItem(context, item.id);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Large Image Header (Top 45% of screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: 'item_${item.id}',
              child: _buildItemImage(item),
            ),
          ),

          // 2. Info Sheet (Bottom 60% of screen, overlapping image)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.40,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Title and Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatClothingType(item.type).toUpperCase(), // Main Title (e.g., "TOPS")
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: GoldFitTheme.gold600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_capitalize(item.color)} ${_formatClothingType(item.type)}', // Subtitle (e.g., "Red Tops")
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: GoldFitTheme.textDark,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: GoldFitTheme.gold600.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '\$${item.price!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: GoldFitTheme.gold700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Details Grid
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GoldFitTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid of details
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildDetailItem(
                          context,
                          icon: Icons.palette_outlined,
                          label: 'Color',
                          value: _capitalize(item.color),
                        ),
                        _buildDetailItem(
                          context,
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: _formatClothingType(item.type),
                        ),
                        _buildDetailItem(
                          context,
                          icon: Icons.calendar_month_outlined,
                          label: 'Added',
                          value: '${item.addedDate.day}/${item.addedDate.month}/${item.addedDate.year}',
                        ),
                        _buildDetailItem(
                          context,
                          icon: Icons.history,
                          label: 'Usage',
                          value: '${item.usageCount} times',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Seasons Section
                    const Text(
                      'Seasons',
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
                      children: item.seasons.map((season) {
                        return Chip(
                          label: Text(_formatSeason(season)),
                          backgroundColor: GoldFitTheme.yellow100,
                          labelStyle: const TextStyle(
                            color: GoldFitTheme.gold700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99), // Pill-shaped
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showDeleteConfirmation(context, item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50], // Light red background
                          foregroundColor: Colors.red, // Red text
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99), // Pill-shaped
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text(
                              'Delete Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Extra padding for bottom safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to capitalize first letter
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Helper to build a detail item box
  Widget _buildDetailItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GoldFitTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: GoldFitTheme.textMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: GoldFitTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GoldFitTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the clothing item image widget
  Widget _buildItemImage(ClothingItem item) {
    if (item.imageUrl.startsWith('http')) {
       return Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(item);
        },
      );
    } else if (item.imageUrl.contains('/')) {
      return LocalImageWidget(
        imagePath: item.imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      return _buildPlaceholderImage(item);
    }
  }

  /// Builds a colored placeholder image with icon
  Widget _buildPlaceholderImage(ClothingItem item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _getColorFromName(item.color),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColorFromName(item.color),
            _getColorFromName(item.color).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getIconForType(item.type),
          size: 80,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before deleting the item
  void _showDeleteConfirmation(BuildContext context, ClothingItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete the item
                final viewModel = Provider.of<WardrobeViewModel>(context, listen: false);
                viewModel.deleteItem(item.id);
                
                // Close the dialog
                Navigator.of(dialogContext).pop();
                
                // Navigate back to wardrobe
                Navigator.of(context).pop();
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted successfully')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Formats ClothingType enum to readable string
  String _formatClothingType(ClothingType type) {
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

  /// Formats Season enum to readable string
  String _formatSeason(Season season) {
    switch (season) {
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.fall:
        return 'Fall';
      case Season.winter:
        return 'Winter';
    }
  }

  /// Gets a color from a color name string
  Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'brown': Colors.brown,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'beige': const Color(0xFFF5F5DC),
      'navy': const Color(0xFF000080),
      'maroon': const Color(0xFF800000),
      'teal': Colors.teal,
      'olive': const Color(0xFF808000),
    };
    
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }

  /// Gets an icon for a clothing type
  IconData _getIconForType(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
        return Icons.checkroom;
      case ClothingType.bottoms:
        return Icons.checkroom;
      case ClothingType.outerwear:
        return Icons.checkroom;
      case ClothingType.shoes:
        return Icons.shopping_bag;
      case ClothingType.accessories:
        return Icons.watch;
    }
  }
}
