import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:intl/intl.dart';

/// Favorites screen displaying saved virtual try-on results.
/// 
/// Follows the Digital Curator aesthetic with pill-shaped roundedness,
/// Manrope headlines, and tonal layering.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FavoritesViewModel>().loadFavorites(),
          ),
        ],
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.favoriteOutfits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.favoriteOutfits.isEmpty && !viewModel.isLoading) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              _buildVibeFilters(context, viewModel),
              Expanded(
                child: _buildFavoritesGrid(context, viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GoldFitTheme.yellow100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 48,
              color: GoldFitTheme.gold600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try on some clothes and save them to see them here!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GoldFitTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeFilters(BuildContext context, FavoritesViewModel viewModel) {
    final vibes = ['All', 'Casual', 'Work', 'Date Night', 'Formal', 'Athletic'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: vibes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final vibe = vibes[index];
          final isSelected = viewModel.selectedVibe == vibe;

          return GestureDetector(
            onTap: () => viewModel.setVibeFilter(vibe),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? GoldFitTheme.primary : GoldFitTheme.surfaceLight,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? GoldFitTheme.primary : const Color(0xFFF1F5F9),
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: GoldFitTheme.gold600.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Center(
                child: Text(
                  vibe,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? GoldFitTheme.textDark : GoldFitTheme.textMedium,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesGrid(BuildContext context, FavoritesViewModel viewModel) {
    final favorites = viewModel.filteredFavorites;

    if (favorites.isEmpty) {
      return Center(
        child: Text(
          'No ${viewModel.selectedVibe} outfits found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: GoldFitTheme.textLight,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        return _FavoriteOutfitCard(outfit: favorites[index], viewModel: viewModel);
      },
    );
  }
}

class _FavoriteOutfitCard extends StatelessWidget {
  final Outfit outfit;
  final FavoritesViewModel viewModel;

  const _FavoriteOutfitCard({required this.outfit, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('MMM d, yyyy').format(outfit.createdDate);

    return Container(
      decoration: BoxDecoration(
        color: GoldFitTheme.surfaceLight,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: outfit.resultImagePath != null
                      ? LocalImageWidget(
                          imagePath: outfit.resultImagePath!,
                          fit: BoxFit.cover,
                        )
                      : outfit.modelImagePath != null 
                        ? FutureBuilder<List<ClothingItem>>(
                            future: viewModel.getItemsForOutfit(outfit),
                            builder: (context, snapshot) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  LocalImageWidget(imagePath: outfit.modelImagePath!, fit: BoxFit.cover),
                                  if (snapshot.hasData && snapshot.data!.isNotEmpty)
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                      child: const Center(
                                        child: Icon(Icons.checkroom, color: Colors.white, size: 40)
                                      )
                                    )
                                ],
                              );
                            }
                          )
                        : Container(
                          color: GoldFitTheme.yellow100,
                          child: const Icon(Icons.person, size: 48, color: GoldFitTheme.gold600),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outfit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: GoldFitTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: GoldFitTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              outfit.vibe ?? 'Casual',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: GoldFitTheme.textMedium,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            dateString,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: GoldFitTheme.textLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => viewModel.toggleFavorite(outfit),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
