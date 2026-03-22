import 'package:flutter/material.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';

/// A card widget that displays an outfit with its items, name, and vibe label.
/// 
/// This widget is used to show outfit recommendations on the home screen and
/// in other contexts where outfits need to be displayed. It shows the outfit's
/// clothing items in a horizontal layout, along with the outfit name and vibe.
/// 
/// Requirements: 3.2
class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final List<ClothingItem> items;
  final VoidCallback onTap;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: GoldFitTheme.yellow200.withOpacity(0.1), // Ghost border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outfit items display in horizontal layout
            _buildItemsPreview(),
            
            // Outfit name and vibe label
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (outfit.vibe != null) ...[
                    const SizedBox(height: 4),
                    _buildVibeLabel(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal preview of outfit items.
  /// 
  /// Displays items in a horizontal scrollable row with small thumbnails.
  Widget _buildItemsPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: GoldFitTheme.backgroundDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: items.isEmpty
          ? const Center(
              child: Icon(
                Icons.checkroom_outlined,
                size: 48,
                color: GoldFitTheme.textLight,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AspectRatio(
                    aspectRatio: 0.8,
                    child: _buildItemThumbnail(items[index]),
                  ),
                );
              },
            ),
    );
  }

  /// Builds a small thumbnail for a clothing item.
  Widget _buildItemThumbnail(ClothingItem item) {
    return Container(
      decoration: BoxDecoration(
        color: GoldFitTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildItemImage(item),
      ),
    );
  }

  /// Builds the image widget for a clothing item thumbnail.
  Widget _buildItemImage(ClothingItem item) {
    if (item.imageUrl.contains('/')) {
      return LocalImageWidget(
        imagePath: item.imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      return _buildPlaceholder(item);
    }
  }

  /// Builds a colored placeholder with an icon for the clothing type.
  Widget _buildPlaceholder(ClothingItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _getColorFromName(item.color),
      ),
      child: Center(
        child: Icon(
          _getIconForType(item.type),
          size: 32,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  /// Builds the vibe label chip.
  Widget _buildVibeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GoldFitTheme.yellow100,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: GoldFitTheme.yellow200.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        outfit.vibe!,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: GoldFitTheme.gold600,
        ),
      ),
    );
  }

  /// Returns a Color based on the color name string.
  Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red.shade300,
      'blue': Colors.blue.shade300,
      'green': Colors.green.shade300,
      'yellow': Colors.yellow.shade300,
      'black': Colors.grey.shade800,
      'white': Colors.grey.shade200,
      'gray': Colors.grey.shade400,
      'grey': Colors.grey.shade400,
      'brown': Colors.brown.shade300,
      'pink': Colors.pink.shade300,
      'purple': Colors.purple.shade300,
      'orange': Colors.orange.shade300,
      'beige': const Color(0xFFF5F5DC),
      'navy': Colors.indigo.shade700,
      'burgundy': const Color(0xFF800020),
      'olive': const Color(0xFF808000),
      'teal': Colors.teal.shade300,
    };
    
    return colorMap[colorName.toLowerCase()] ?? Colors.grey.shade300;
  }

  /// Returns an icon based on the clothing type.
  IconData _getIconForType(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
        return Icons.checkroom;
      case ClothingType.bottoms:
        return Icons.dry_cleaning;
      case ClothingType.outerwear:
        return Icons.ac_unit;
      case ClothingType.shoes:
        return Icons.shopping_bag;
      case ClothingType.accessories:
        return Icons.watch;
    }
  }
}
