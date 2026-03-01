import 'package:flutter/material.dart';
import '../widgets/analytics_card.dart';

/// Demo screen to showcase the AnalyticsCard widget.
/// This is for development and testing purposes only.
class AnalyticsCardDemo extends StatelessWidget {
  const AnalyticsCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnalyticsCard Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const AnalyticsCard(
              title: 'Total Items',
              value: '42',
              icon: Icons.checkroom,
            ),
            const SizedBox(height: 16),
            const AnalyticsCard(
              title: 'Total Value',
              value: '\$1,234',
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 16),
            const AnalyticsCard(
              title: 'Most Worn',
              value: '15 times',
              icon: Icons.favorite,
            ),
            const SizedBox(height: 16),
            const AnalyticsCard(
              title: 'Least Worn',
              value: '0 times',
              icon: Icons.warning_amber,
            ),
            const SizedBox(height: 16),
            const AnalyticsCard(
              title: 'Average Price',
              value: '\$45.67',
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 16),
            const AnalyticsCard(
              title: 'Items Added',
              value: '8 this month',
              icon: Icons.add_circle,
            ),
          ],
        ),
      ),
    );
  }
}
