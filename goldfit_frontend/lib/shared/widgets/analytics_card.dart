import 'package:flutter/material.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

/// A card widgets that displays an analytics metric with title, value, and icon.
/// 
/// This widgets is used on the Insights screen to display wardrobe analytics
/// such as total items, total value, and other metrics. It follows the card
/// styling from the theme with a clean, modern design.
/// 
/// Requirements: 10.1, 10.2
class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon container with yellow background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: GoldFitTheme.yellow100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GoldFitTheme.yellow200,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: GoldFitTheme.gold600,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Title and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GoldFitTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
