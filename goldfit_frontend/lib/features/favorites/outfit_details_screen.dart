import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/shared/widgets/clothing_item_card.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';
import 'package:intl/intl.dart';

/// Screen detailing a specific outfit and its constituent clothing items.
class OutfitDetailsScreen extends StatelessWidget {
  final Outfit outfit;

  const OutfitDetailsScreen({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroImage(context),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(context),
                  const SizedBox(height: 32),
                  const Text(
                    'Outfit Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildItemsGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Container(
      height: 350,
      width: double.infinity,
      color: GoldFitTheme.surfaceLight,
      child: outfit.resultImagePath != null
          ? LocalImageWidget(imagePath: outfit.resultImagePath!, fit: BoxFit.cover)
          : outfit.modelImagePath != null
              ? LocalImageWidget(imagePath: outfit.modelImagePath!, fit: BoxFit.cover)
              : Container(
                  color: GoldFitTheme.yellow100,
                  child: const Center(
                    child: Icon(Icons.person, size: 80, color: GoldFitTheme.gold600),
                  ),
                ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context) {
    final dateString = DateFormat('MMMM d, yyyy').format(outfit.createdDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                outfit.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: GoldFitTheme.textDark,
                ),
              ),
            ),
            Consumer<FavoritesViewModel>(
              builder: (context, viewModel, child) {
                final currentOutfit = viewModel.favoriteOutfits.firstWhere(
                  (o) => o.id == outfit.id,
                  orElse: () => outfit,
                );
                return IconButton(
                  icon: Icon(
                    currentOutfit.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: currentOutfit.isFavorite ? Colors.red : GoldFitTheme.textMedium,
                    size: 28,
                  ),
                  onPressed: () => viewModel.toggleFavorite(currentOutfit),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (outfit.vibe != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GoldFitTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  outfit.vibe!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GoldFitTheme.textDark,
                  ),
                ),
              ),
            const Icon(Icons.calendar_today, size: 14, color: GoldFitTheme.textMedium),
            const SizedBox(width: 6),
            Text(
              dateString,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GoldFitTheme.textMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsGrid(BuildContext context) {
    return FutureBuilder<List<ClothingItem>>(
      future: context.read<FavoritesViewModel>().getItemsForOutfit(outfit),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load items',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No clothes found for this outfit.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GoldFitTheme.textLight,
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ClothingItemCard(
              item: item,
              onTap: () {}, // Navigation to clothing details would go here
            );
          },
        );
      },
    );
  }
}
