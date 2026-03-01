import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

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
        appBar: AppBar(
          title: const Text('Item Detail'),
        ),
        body: const Center(
          child: Text('No item ID provided'),
        ),
      );
    }

    // Get the item from AppState
    final appState = Provider.of<AppState>(context, listen: false);
    final item = appState.dataProvider.getItemById(itemId);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Item Detail'),
        ),
        body: const Center(
          child: Text('Item not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen (task 11.2)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Full-size image with zoom capability
          Expanded(
            flex: 3,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: _buildItemImage(item),
              ),
            ),
          ),
          
          // Tag display section
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTagSection(context, item),
                  const SizedBox(height: 24),
                  _buildDeleteButton(context, item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the clothing item image widget
  Widget _buildItemImage(ClothingItem item) {
    // Check if it's an asset image or a placeholder
    if (item.imageUrl.startsWith('assets/')) {
      return Image.asset(
        item.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(item);
        },
      );
    } else {
      return _buildPlaceholderImage(item);
    }
  }

  /// Builds a colored placeholder image with icon
  Widget _buildPlaceholderImage(ClothingItem item) {
    return Container(
      width: double.infinity,
      color: _getColorFromName(item.color),
      child: Center(
        child: Icon(
          _getIconForType(item.type),
          size: 120,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  /// Builds the tag display section
  Widget _buildTagSection(BuildContext context, ClothingItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: GoldFitTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // Type tag
        _buildTagRow(
          context,
          'Type',
          _formatClothingType(item.type),
          Icons.category,
        ),
        const SizedBox(height: 12),
        
        // Color tag
        _buildTagRow(
          context,
          'Color',
          item.color,
          Icons.palette,
        ),
        const SizedBox(height: 12),
        
        // Seasons tag
        _buildTagRow(
          context,
          'Seasons',
          item.seasons.map((s) => _formatSeason(s)).join(', '),
          Icons.wb_sunny,
        ),
        const SizedBox(height: 12),
        
        // Price tag (if available)
        if (item.price != null)
          _buildTagRow(
            context,
            'Price',
            '\$${item.price!.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
      ],
    );
  }

  /// Builds a single tag row with icon, label, and value
  Widget _buildTagRow(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GoldFitTheme.yellow100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldFitTheme.yellow200),
      ),
      child: Row(
        children: [
          Icon(icon, color: GoldFitTheme.gold600, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: GoldFitTheme.textDark,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GoldFitTheme.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the delete button at the bottom
  Widget _buildDeleteButton(BuildContext context, ClothingItem item) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showDeleteConfirmation(context, item),
        icon: const Icon(Icons.delete),
        label: const Text('Delete Item'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                final appState = Provider.of<AppState>(context, listen: false);
                appState.deleteItem(item.id);
                
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
