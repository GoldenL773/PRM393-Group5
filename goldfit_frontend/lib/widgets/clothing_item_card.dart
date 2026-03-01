import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../utils/theme.dart';

/// A card widget that displays a clothing item thumbnail with border and shadow.
/// 
/// This widget is used in grid views to show clothing items from the wardrobe.
/// It displays the item's image with a subtle border and shadow effect, and
/// handles tap gestures to navigate to the item detail screen.
/// 
/// Requirements: 4.5
class ClothingItemCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const ClothingItemCard({
    super.key,
    required this.item,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Clothing item image
              _buildImage(),
              
              // Optional hover overlay with item details
              // This will be visible on hover for web/desktop platforms
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the image widget for the clothing item.
  /// 
  /// If the imageUrl starts with 'assets/', it uses Image.asset.
  /// Otherwise, it displays a colored placeholder with an icon.
  Widget _buildImage() {
    if (item.imageUrl.startsWith('assets/')) {
      return Image.asset(
        item.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  /// Builds a colored placeholder with an icon for the clothing type.
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _getColorFromName(item.color),
        image: DecorationImage(
          image: NetworkImage(
            _getMockImageUrl(item.type, item.color),
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.1),
            BlendMode.darken,
          ),
        ),
      ),
    );
  }

  /// Returns a mock image URL based on clothing type and color
  String _getMockImageUrl(ClothingType type, String color) {
    // Unsplash search keywords based on type
    String keyword = 'clothing';
    switch (type) {
      case ClothingType.tops:
        keyword = 'shirt,tshirt,blouse';
        break;
      case ClothingType.bottoms:
        keyword = 'pants,jeans,skirt';
        break;
      case ClothingType.outerwear:
        keyword = 'jacket,coat,sweater';
        break;
      case ClothingType.shoes:
        keyword = 'shoes,sneakers,boots';
        break;
      case ClothingType.accessories:
        keyword = 'accessories,bag,watch,sunglasses';
        break;
    }
    
    // Use Unsplash Source API to get a random image based on keywords
    // Adding the item ID ensures the same item gets the same image consistently
    return 'https://source.unsplash.com/featured/?$keyword,$color&sig=${item.id}';
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
        return Icons.checkroom; // Shirt icon
      case ClothingType.bottoms:
        return Icons.dry_cleaning; // Pants icon
      case ClothingType.outerwear:
        return Icons.ac_unit; // Jacket icon
      case ClothingType.shoes:
        return Icons.shopping_bag; // Shoes icon
      case ClothingType.accessories:
        return Icons.watch; // Accessories icon
    }
  }
}
