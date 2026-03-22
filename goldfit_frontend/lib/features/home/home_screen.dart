import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // added for kDebugMode
import 'package:goldfit_frontend/features/home/home_viewmodel.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/widgets/outfit_card.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/core/database/database_seeder.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';

/// Home screen displaying weather information and outfit recommendations
/// Shows weather widget, "Get Styled" button, and recommended outfits
/// 
/// Requirements: 3.1, 3.2, 3.5, 7.1, 14.3, 14.4
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load recommendations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final recommendations = viewModel.recommendations;
        final weather = viewModel.weather ?? appState.currentWeather;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (kDebugMode) ...[
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Data Seeder',
              onPressed: () => _showSeedConfirmationDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'View Error Logs',
              onPressed: () => Navigator.pushNamed(context, '/debug-logs'),
            ),

            //Settings button
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'View Settings',
              onPressed:() => Navigator.pushNamed(context, '/settings'),
            )
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await viewModel.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Padding chuẩn 20 hai bên
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather widget
                _buildWeatherWidget(weather),
                
                const SizedBox(height: 32), // Tăng khoảng cách từ 24 -> 32 để "thở"
                
                // "Get Styled" button
                _buildGetStyledButton(context),
                
                const SizedBox(height: 40), // Tăng khoảng cách từ 32 -> 40
                
                // Loading state
                if (viewModel.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Error state
                else if (viewModel.error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: GoldFitTheme.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => viewModel.loadRecommendations(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                // Recommended outfits section
                else
                  _buildRecommendedOutfitsSection(context, viewModel, recommendations),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  /// Returns the appropriate weather background image asset path
  String _getWeatherImageAsset(String condition, bool isDay) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('storm') || cond.contains('drizzle')) {
      return 'assets/images/weather/rainy.png';
    } else if (cond.contains('cloud') || cond.contains('overcast') || cond.contains('fog') || cond.contains('mist')) {
      return 'assets/images/weather/cloudy.png';
    } else {
      // Sunny, Clear, etc.
      return 'assets/images/weather/sunny.png';
    }
  }

  /// Returns overlay color based on time of day
  Color _getWeatherOverlay(String condition, bool isDay) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('storm')) {
      return Colors.blueGrey.shade900.withOpacity(0.55);
    } else if (!isDay) {
      return Colors.indigo.shade900.withOpacity(0.60);
    }
    return Colors.black.withOpacity(0.30);
  }

  /// Builds the weather widget displaying temperature, condition, and location
  Widget _buildWeatherWidget(dynamic weather) {
    if (weather == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: CircularProgressIndicator(color: GoldFitTheme.primary)),
      );
    }

    final cond = weather.condition.toString();
    final isDay = weather.isDay ?? true;
    final bgAsset = _getWeatherImageAsset(cond, isDay);
    final overlay = _getWeatherOverlay(cond, isDay);
    
    return Container(
      width: double.infinity,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: GoldFitTheme.gold600,
              ),
            ),
            // Semi-transparent overlay
            Container(color: overlay),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getWeatherIcon(cond),
                        size: 50,
                        color: Colors.white,
                        shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather.temperature.round()}°C',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                            Text(
                              cond,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          weather.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Builds the "Get Styled" button
  Widget _buildGetStyledButton(BuildContext context) {
    final navigationManager = Provider.of<NavigationManager>(context, listen: false);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [GoldFitTheme.primary, GoldFitTheme.yellow200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: GoldFitTheme.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => navigationManager.navigateToStyling(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.auto_awesome, size: 24, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Get Styled',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the recommended outfits section
  Widget _buildRecommendedOutfitsSection(
    BuildContext context,
    HomeViewModel viewModel,
    List<dynamic> recommendations,
  ) {
    final navigationManager = Provider.of<NavigationManager>(context, listen: false);
    final recommendedItems = viewModel.recommendedItems;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Styling advice box
        if (viewModel.stylingAdvice != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: GoldFitTheme.gold600.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: GoldFitTheme.gold600.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GoldFitTheme.gold600.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: GoldFitTheme.gold600, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Stylist Insight',
                      style: TextStyle(
                        color: GoldFitTheme.gold600,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.stylingAdvice!,
                  style: const TextStyle(
                    color: GoldFitTheme.textDark,
                    fontSize: 15,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Debug AI log in debug mode
        if (kDebugMode && viewModel.aiDebugLog != null) ...[
          ExpansionTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange, size: 18),
            title: const Text('AI Debug Log', style: TextStyle(fontSize: 13, color: Colors.orange)),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  viewModel.aiDebugLog!,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        const Text(
          'Recommended for Today',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: GoldFitTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        
        // Individual clothing items grid (filtered by season+color)
        if (recommendedItems.isNotEmpty) ...[
          SizedBox(
            height: 140,
            child: ListView.separated(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: recommendedItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildRecommendedItemCard(context, recommendedItems[index], navigationManager);
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
        
        // Outfit section title
        if (recommendations.isNotEmpty) ...[
          const Text(
            'Complete Outfits',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: GoldFitTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((outfit) {
            final items = viewModel.recommendationItems[outfit.id] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: OutfitCard(
                outfit: outfit,
                items: items,
                onTap: () {
                  navigationManager.navigateToTryOnWithOutfit(context, outfit);
                },
              ),
            );
          }),
        ] else if (recommendedItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No recommendations available.\nTap "Get Styled" for AI-powered suggestions!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: GoldFitTheme.textLight,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a small card for a single recommended clothing item
  Widget _buildRecommendedItemCard(
    BuildContext context,
    ClothingItem item,
    NavigationManager navigationManager,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/try-on'),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: GoldFitTheme.gold600.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _buildItemImage(item),
              // Season badge
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    item.color,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds image for clothing item card
  Widget _buildItemImage(ClothingItem item) {
    if (item.imageUrl.isEmpty) {
      return Container(
        color: GoldFitTheme.yellow100,
        child: const Icon(Icons.checkroom, color: GoldFitTheme.gold600, size: 40),
      );
    }
    
    return LocalImageWidget(
      imagePath: item.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  /// Returns the appropriate weather icon based on condition
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'partly cloudy':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.umbrella;
      case 'snowy':
      case 'snow':
        return Icons.ac_unit;
      case 'stormy':
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  /// Displays confirmation dialog for seeding database with test data
  void _showSeedConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seed Database?'),
          content: const Text(
            'This will clear ALL existing data and insert new mock data into SQLite. '
            'Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Seed Data', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seeding database...')),
                );
                
                try {
                  final dbManager = DatabaseManager();
                  final clothingRepo = Provider.of<ClothingRepository>(context, listen: false);
                  final outfitRepo = Provider.of<OutfitRepository>(context, listen: false);
                  
                  final seeder = DatabaseSeeder(dbManager, clothingRepo, outfitRepo);
                  await seeder.seed();
                  
                  if (!mounted) return;
                  if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database seeded successfully! Please restart the app or refresh.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to seed: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
