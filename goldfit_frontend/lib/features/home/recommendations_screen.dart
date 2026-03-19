import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/widgets/outfit_card.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

/// Recommendations screen displaying outfit suggestions based on vibe or event
/// Shows 3-5 outfit cards with tap to navigate to try-on
/// 
/// Requirements: 7.5
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract arguments from route
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final vibe = args?['vibe'] as String?;
    final eventDescription = args?['eventDescription'] as String?;

    // Get recommendations from AppState
    final appState = Provider.of<AppState>(context);
    final navigationManager = Provider.of<NavigationManager>(context, listen: false);
    
    // Get vibe-based recommendations if vibe is provided
    final recommendations = vibe != null
        ? appState.getVibeBasedRecommendations(vibe)
        : appState.weatherRecommendations;

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Outfit Recommendations'),
        backgroundColor: GoldFitTheme.backgroundLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with context
            _buildHeader(vibe, eventDescription),
            
            // Recommendations list
            Expanded(
              child: recommendations.isEmpty
                  ? _buildEmptyState()
                  : _buildRecommendationsList(
                      context,
                      recommendations,
                      appState,
                      navigationManager,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header section showing the selected vibe or event description
  Widget _buildHeader(String? vibe, String? eventDescription) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vibe != null) ...[
            Text(
              'Perfect for $vibe',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GoldFitTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here are some outfit suggestions for you',
              style: TextStyle(
                fontSize: 14,
                color: GoldFitTheme.textMedium,
              ),
            ),
          ] else if (eventDescription != null && eventDescription.isNotEmpty) ...[
            const Text(
              'Custom Recommendations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GoldFitTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'For: $eventDescription',
              style: const TextStyle(
                fontSize: 14,
                color: GoldFitTheme.textMedium,
              ),
            ),
          ] else ...[
            const Text(
              'Recommended for You',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GoldFitTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Based on current weather and your style',
              style: TextStyle(
                fontSize: 14,
                color: GoldFitTheme.textMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the list of outfit recommendations
  Widget _buildRecommendationsList(
    BuildContext context,
    List<Outfit> recommendations,
    AppState appState,
    NavigationManager navigationManager,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final outfit = recommendations[index];
        
        // Get the actual clothing items for this outfit
        final items = outfit.itemIds
            .map((id) => appState.getItemById(id))
            .whereType<ClothingItem>()
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: OutfitCard(
            outfit: outfit,
            items: items,
            onTap: () {
              // Navigate to Try-On screen with this outfit
              navigationManager.navigateToTryOnWithOutfit(context, outfit);
            },
          ),
        );
      },
    );
  }

  /// Builds the empty state when no recommendations are available
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 80,
              color: GoldFitTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Recommendations Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GoldFitTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adding more items to your wardrobe',
              style: TextStyle(
                fontSize: 14,
                color: GoldFitTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
