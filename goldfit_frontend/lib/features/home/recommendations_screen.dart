import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/home/recommendations_viewmodel.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/widgets/outfit_card.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final vibe = args?['vibe'] as String?;
      final eventDescription = args?['eventDescription'] as String?;
      
      context.read<RecommendationsViewModel>().loadRecommendations(
        vibe: vibe,
        eventDescription: eventDescription,
      );
      _isFirstLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final vibe = args?['vibe'] as String?;
    final eventDescription = args?['eventDescription'] as String?;

    return Consumer<RecommendationsViewModel>(
      builder: (context, viewModel, child) {
        final recommendations = viewModel.recommendations;
        final navigationManager = Provider.of<NavigationManager>(context, listen: false);

        return Scaffold(
          backgroundColor: GoldFitTheme.backgroundLight,
          appBar: AppBar(
            title: const Text('Outfit Recommendations'),
            backgroundColor: GoldFitTheme.backgroundLight,
            elevation: 0,
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.error != null
                  ? _buildErrorState(viewModel.error!, () {
                      viewModel.loadRecommendations(
                        vibe: vibe,
                        eventDescription: eventDescription,
                      );
                    })
                  : SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(vibe, eventDescription),
                          if (viewModel.aiAdvice != null) _buildAiAdvice(viewModel.aiAdvice!),
                          Expanded(
                            child: recommendations.isEmpty
                                ? _buildEmptyState()
                                : _buildRecommendationsList(
                                    context,
                                    recommendations,
                                    viewModel,
                                    navigationManager,
                                  ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildAiAdvice(String advice) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldFitTheme.yellow100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GoldFitTheme.yellow200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates, color: GoldFitTheme.gold600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advice,
              style: const TextStyle(
                color: GoldFitTheme.textDark,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(
    BuildContext context,
    List<Outfit> recommendations,
    RecommendationsViewModel viewModel,
    NavigationManager navigationManager,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final outfit = recommendations[index];
        final items = viewModel.recommendationItems[outfit.id] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OutfitCard(
            outfit: outfit,
            items: items,
            onTap: () => navigationManager.navigateToTryOnWithOutfit(context, outfit),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String? vibe, String? eventDescription) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vibe != null ? 'Perfect for $vibe' : 'Custom Recommendations',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: GoldFitTheme.textDark,
            ),
          ),
          if (eventDescription != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'For: $eventDescription',
                style: const TextStyle(fontSize: 14, color: GoldFitTheme.textMedium),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No recommendations found.'));
  }
}
