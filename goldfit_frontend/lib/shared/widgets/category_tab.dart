import 'package:flutter/material.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

/// A tab widgets for displaying and selecting clothing categories.
/// 
/// This widgets is used in the wardrobe screen to filter items by category.
/// It displays a category label with active/inactive styling and applies
/// the primary gold/yellow color when active.
/// 
/// Requirements: 4.2
class CategoryTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const CategoryTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? GoldFitTheme.primary : GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(999), // Pill shape
          border: Border.all(
            color: isActive ? GoldFitTheme.primary : GoldFitTheme.yellow200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? GoldFitTheme.textDark : GoldFitTheme.textMedium,
          ),
        ),
      ),
    );
  }
}
