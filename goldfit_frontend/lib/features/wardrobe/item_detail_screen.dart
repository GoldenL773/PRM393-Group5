import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:intl/intl.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final itemId = args?['itemId'] as String?;

    if (itemId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Detail')),
        body: const Center(child: Text('No item ID provided')),
      );
    }

    final viewModel = Provider.of<WardrobeViewModel>(context);
    final item = viewModel.items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    // Color Palette based on "Digital Atelier" design
    const bgColor = Color(0xFFFCFBF8);
    const surfaceColor = Color(0xFFF6F5F2);
    const textDark = Color(0xFF1E1E1E);
    const textGrey = Color(0xFF757575);
    const goldAccent = Color(0xFFB8860B);
    const goldLight = Color(0xFFFDE68A);

    final title = '${_capitalize(item.color)} ${_formatClothingType(item.type)}';
    final priceStr = item.price != null ? '\$${item.price!.toStringAsFixed(2)}' : '\$0.00';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Digital Atelier',
          style: TextStyle(color: textDark, fontWeight: FontWeight.normal, fontSize: 16, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
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
                color: item.isFavorite ? Colors.red : textDark,
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
              icon: const Icon(Icons.edit, color: goldAccent),
              onPressed: () {
                final navigationManager = Provider.of<NavigationManager>(context, listen: false);
                navigationManager.navigateToEditItem(context, item.id);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Image Container
            Center(
              child: Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Hero(
                    tag: 'item_${item.id}',
                    child: _buildItemImage(item),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Top Level Item Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: goldLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'TOP LEVEL ITEM',
                style: TextStyle(
                  color: goldAccent.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title & Price
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textDark,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              priceStr,
              style: const TextStyle(
                fontSize: 20,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Tiles
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usage Count',
                          style: TextStyle(fontSize: 12, color: textGrey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.bar_chart, size: 16, color: goldAccent),
                            const SizedBox(width: 8),
                            Text(
                              '${item.usageCount} times',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Added Date',
                          style: TextStyle(fontSize: 12, color: textGrey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: goldAccent),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(item.addedDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category & Color
            const Text(
              'CATEGORY & COLOR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: textGrey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGreyChip(Icons.category_outlined, _formatClothingType(item.type)),
                const SizedBox(width: 12),
                _buildGreyChip(Icons.circle, _capitalize(item.color), iconColor: _getColorFromName(item.color)),
              ],
            ),
            const SizedBox(height: 24),

            // Seasons
            const Text(
              'SEASONS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: textGrey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.seasons.map((s) {
                return _buildGoldChip(
                  s == Season.summer || s == Season.spring ? Icons.wb_sunny_outlined : Icons.ac_unit,
                  _formatSeason(s),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Plan Outfit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logic to navigate to planner with this item pre-selected
                  context.read<AppState>().setTab(3); // Go to planner tab
                  Navigator.pop(context); // Go back from detail to main
                },
                icon: const Text(
                  'Plan Outfit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                label: const Icon(Icons.edit_calendar, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldAccent.withOpacity(0.9),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Curate this piece into your digital capsule',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textGrey.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 40),

            // Collection Details
            const Text(
              'Collection Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A staple for any minimalist collection, this ${_capitalize(item.color)} ${_formatClothingType(item.type)} features a premium blend. Designed for versatility across the ${item.seasons.map((s) => _formatSeason(s)).join(' and ')} transition.',
                    style: const TextStyle(fontSize: 14, color: textGrey, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Delete Item Area (Redesigned as purely functional text button to keep UI clean)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context, item),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text('Remove from Wardrobe', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGreyChip(IconData icon, String label, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? const Color(0xFF1E1E1E)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGoldChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE68A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1E1E1E)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Helpers
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatClothingType(ClothingType type) {
    switch (type) {
      case ClothingType.tops: return 'Tops';
      case ClothingType.bottoms: return 'Bottoms';
      case ClothingType.outerwear: return 'Outerwear';
      case ClothingType.shoes: return 'Shoes';
      case ClothingType.accessories: return 'Accessories';
    }
  }

  String _formatSeason(Season season) {
    switch (season) {
      case Season.spring: return 'Spring';
      case Season.summer: return 'Summer';
      case Season.fall: return 'Fall';
      case Season.winter: return 'Winter';
    }
  }

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
      'beige': const Color(0xFFF5F5DC),
      'navy': const Color(0xFF000080),
    };
    return colorMap[colorName.toLowerCase()] ?? Colors.black; // Fallback to black for icons
  }

  Widget _buildItemImage(ClothingItem item) {
    if (item.imageUrl.startsWith('http')) {
      return Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    } else if (item.imageUrl.contains('/')) {
      return LocalImageWidget(
        imagePath: item.imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ClothingItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: const Text('Are you sure you want to remove this piece from your digital capsule?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Keep it'),
            ),
            TextButton(
              onPressed: () {
                final viewModel = Provider.of<WardrobeViewModel>(context, listen: false);
                viewModel.deleteItem(item.id);
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
