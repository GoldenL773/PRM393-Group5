import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/insights/insights_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/analytics_card.dart';
import 'package:goldfit_frontend/shared/widgets/clothing_item_card.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/utils/routes.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';

/// Insights screen displaying wardrobe analytics and usage statistics
/// Shows total items, total value, most worn items, and dusty corner
///
/// Requirements: 10.1, 10.2, 10.3, 10.4, 14.3, 14.4
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    // Load analytics data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsViewModel>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(title: const Text('Insights')),
      body: Consumer<InsightsViewModel>(
        builder: (context, viewModel, child) {
          // Show loading state
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state
          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      viewModel.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GoldFitTheme.textMedium),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => viewModel.loadAnalytics(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show empty state if no analytics data
          if (viewModel.analytics == null) {
            return const Center(
              child: Text(
                'No analytics data available',
                style: TextStyle(color: GoldFitTheme.textMedium, fontSize: 16),
              ),
            );
          }

          final analytics = viewModel.analytics!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favorite Outfits Entry
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.favorites),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          GoldFitTheme.gold600,
                          GoldFitTheme.gold600.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: GoldFitTheme.gold600.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Favorite Outfits',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'View your saved try-on results',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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

                // Financial Report Section (New)
                _buildFinancialReport(analytics),

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

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the new financial report section
  Widget _buildFinancialReport(WardrobeAnalytics analytics) {
    // Highest price item with 0 usage for the dynamic insight
    ClothingItem? wastefulItem;
    if (analytics.mostWasteful.isNotEmpty) {
      wastefulItem = analytics.mostWasteful.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Financial Report', Icons.account_balance_wallet),
        const SizedBox(height: 16),

        // Dynamic Waste Insight Card
        if (wastefulItem != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Deep Black/Gray
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GoldFitTheme.gold600.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),

        // Category Value Distribution Chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Category Value Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GoldFitTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: analytics.categoryValueDistribution.isEmpty
                    ? const Center(child: Text('No pricing data available'))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildPieChartSections(
                            analytics.categoryValueDistribution,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ROI Sections
        _buildSectionHeader(
          'Top 3 Most Valuable (Best ROI)',
          Icons.trending_up,
          subtitle: 'Low Cost-Per-Wear',
        ),
        const SizedBox(height: 12),
        _buildHorizontalItemList(
          context,
          analytics.mostValueForMoney,
          showCPW: true,
        ),

        const SizedBox(height: 32),

        _buildSectionHeader(
          'Top 3 Most Wasteful (Worst ROI)',
          Icons.trending_down,
          subtitle: 'High Price, Low Usage',
        ),
        const SizedBox(height: 12),
        _buildHorizontalItemList(
          context,
          analytics.mostWasteful,
          showCPW: true,
        ),
      ],
    );
  }

  /// Helper for Pie Chart sections
  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data) {
    final List<PieChartSectionData> sections = [];
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    // Sort by value DESC
    final sortedKeys = data.keys.toList()
      ..sort((a, b) => data[b]!.compareTo(data[a]!));

    final List<Color> colors = [
      GoldFitTheme.gold600,
      GoldFitTheme.primary,
      GoldFitTheme.gold700,
      GoldFitTheme.yellow100,
      const Color(0xFFDAA520), // Goldenrod
    ];

    int i = 0;
    for (var key in sortedKeys) {
      final value = data[key]!;
      final percentage = (value / total * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: '$percentage%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          badgeWidget: _buildBadge(key),
          badgePositionPercentageOffset: 1.3,
        ),
      );
      i++;
    }
    return sections;
  }

  Widget _buildBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  /// Overload for buildSectionHeader with subtitle
  Widget _buildSectionHeader(String title, IconData icon, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: GoldFitTheme.gold600, size: 24),
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
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: GoldFitTheme.textMedium,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a horizontal scrollable list of clothing items
  Widget _buildHorizontalItemList(
    BuildContext context,
    List<ClothingItem> items, {
    bool showCPW = false,
  }) {
    if (items.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: const Center(
          child: Text(
            'No items to display',
            style: TextStyle(color: GoldFitTheme.textMedium),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200, // Slightly taller to accommodate CPW
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final cpw = item.price != null
              ? item.price! / (item.usageCount == 0 ? 1 : item.usageCount)
              : 0.0;

          return Container(
            width: 140,
            margin: EdgeInsets.only(right: index < items.length - 1 ? 12 : 0),
            child: Column(
              children: [
                Expanded(
                  child: ClothingItemCard(
                    item: item,
                    onFavoriteToggle: () {
                      context.read<WardrobeViewModel>().toggleFavorite(item.id);
                      context.read<InsightsViewModel>().loadAnalytics();
                    },
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/item-detail',
                        arguments: {'itemId': item.id},
                      );
                    },
                  ),
                ),
                if (showCPW)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'CPW: \$${cpw.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GoldFitTheme.gold700,
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
}
