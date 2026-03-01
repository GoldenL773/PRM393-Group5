import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// A chip widget for displaying active filters with a remove button.
/// 
/// This widget is used in the wardrobe screen to show active filters
/// and allow users to remove them. It displays the filter label with
/// a remove button (X icon) and is styled with a yellow border and background.
/// 
/// Requirements: 5.4
class FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const FilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GoldFitTheme.yellow100,
        borderRadius: BorderRadius.circular(999), // Pill shape
        border: Border.all(
          color: GoldFitTheme.yellow200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: GoldFitTheme.gold700,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: GoldFitTheme.gold700,
            ),
          ),
        ],
      ),
    );
  }
}
