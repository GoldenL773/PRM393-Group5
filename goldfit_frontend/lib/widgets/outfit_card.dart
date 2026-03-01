import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../utils/theme.dart';

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9), // Subtle border from theme
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
  /// Displays up to 4 items in a horizontal row with small thumbnails.
  /// If there are more than 4 items, shows a "+N" indicator.
  Widget _buildItemsPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: GoldFitTheme.backgroundDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Display up to 4 items
                  ...items.take(4).map((item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildItemThumbnail(item),
                        ),
                      )),
                  
                  // Show "+N" indicator if there are more items
                  if (items.length > 4)
                    Container(
                      width: 40,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: GoldFitTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${items.length - 4}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GoldFitTheme.gold600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
    if (item.imageUrl.startsWith('assets/')) {
      return Image.asset(
        item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(item);
        },
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
        image: DecorationImage(
          image: NetworkImage(
            _getMockImageUrl(item.type, item.color, item.id),
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Returns a mock image URL based on clothing type and color
  String _getMockImageUrl(ClothingType type, String color, String id) {
    String keyword = 'clothing';
    switch (type) {
      case ClothingType.tops:
        keyword = 'shirt,tshirt';
        break;
      case ClothingType.bottoms:
        keyword = 'pants,jeans';
        break;
      case ClothingType.outerwear:
        keyword = 'jacket,coat';
        break;
      case ClothingType.shoes:
        keyword = 'shoes,sneakers';
        break;
      case ClothingType.accessories:
        keyword = 'bag,accessories';
        break;
    }
    
    // Using Unsplash source API for random images based on keywords
    return 'https://source.unsplash.com/featured/?$keyword,$color&sig=$id';
  }

  /// Builds the vibe label chip.
  Widget _buildVibeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GoldFitTheme.yellow100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GoldFitTheme.yellow200,
          width: 1,
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
