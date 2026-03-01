import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/analytics_card.dart';
import '../widgets/clothing_item_card.dart';
import '../utils/theme.dart';

/// Insights screen displaying wardrobe analytics and usage statistics
/// Shows total items, total value, most worn items, and dusty corner
/// 
/// Requirements: 10.1, 10.2, 10.3, 10.4
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final analytics = appState.analytics;

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards for total items and total value
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Items',
                    value: '${analytics.totalItems}',
                    icon: Icons.checkroom,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Value',
                    value: '\$${analytics.totalValue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Most Worn section
            _buildSectionHeader('Most Worn', Icons.star),
            const SizedBox(height: 16),
            _buildHorizontalItemList(context, analytics.mostWorn),
            
            const SizedBox(height: 32),
            
            // Dusty Corner section
            _buildSectionHeader('Dusty Corner', Icons.inventory_2),
            const SizedBox(height: 16),
            _buildHorizontalItemList(context, analytics.leastWorn),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds a section header with title and icon
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: GoldFitTheme.gold600,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GoldFitTheme.textDark,
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal scrollable list of clothing items
  Widget _buildHorizontalItemList(BuildContext context, List items) {
    if (items.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'No items to display',
            style: TextStyle(
              color: GoldFitTheme.textMedium,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 120,
            margin: EdgeInsets.only(
              right: index < items.length - 1 ? 12 : 0,
            ),
            child: ClothingItemCard(
              item: item,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/item-detail',
                  arguments: {'itemId': item.id},
                );
              },
            ),
          );
        },
      ),
    );
  }
}
