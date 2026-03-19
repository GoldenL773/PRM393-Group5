import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // added for kDebugMode
import 'package:goldfit_frontend/features/home/home_viewmodel.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/widgets/outfit_card.dart';
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
    final weather = appState.currentWeather;
    
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final recommendations = viewModel.recommendations;

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

  /// Builds the weather widget displaying temperature, condition, and location
  Widget _buildWeatherWidget(dynamic weather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28), // Đẩy padding to hơn xíu
      decoration: BoxDecoration(
        // Đổi màu Gradient sang vàng pastel nhẹ/trong suốt hơn
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GoldFitTheme.primary.withOpacity(0.6), // Giảm Opacity
            GoldFitTheme.yellow100.withOpacity(0.9), // Dùng yellow100 nhẹ hơn yellow200
          ],
        ),
        borderRadius: BorderRadius.circular(24), // Bo góc mềm mại hơn từ 16->24
        boxShadow: [
          // Thêm Shadow nhẹ, độ nhòe cao
          BoxShadow(
            color: GoldFitTheme.primary.withOpacity(0.2), // Màu shadow ăn nhập với theme
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getWeatherIcon(weather.condition),
                size: 56, // Tăng size icon nhẹ nhàng
                color: GoldFitTheme.gold700,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°F',
                      style: const TextStyle(
                        fontSize: 40, // To hơn cho nổi bật
                        fontWeight: FontWeight.bold, // fontWeight chuẩn
                        color: GoldFitTheme.textDark,
                        letterSpacing: -1, // Sát nét chữ một chút nhìn hiện đại hơn
                      ),
                    ),
                    Text(
                      weather.condition,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400, // Đổi fontWeight nhạt lại
                        color: Colors.black54, // Màu hơi xám như yêu cầu
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Khoảng cách giãn ra
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: Colors.black54, // Đồng bộ màu chữ location
              ),
              const SizedBox(width: 6),
              Text(
                weather.location,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the "Get Styled" button
  Widget _buildGetStyledButton(BuildContext context) {
    final navigationManager = Provider.of<NavigationManager>(context, listen: false);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          navigationManager.navigateToStyling(context);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20), // Nút béo ra một chút
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bo góc mềm mại
          ),
          elevation: 8, // Nổi hẳn lên
          shadowColor: GoldFitTheme.primary.withOpacity(0.5), // Cùng hiệu ứng gold
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 24), // Icon to ra một tẹo
            SizedBox(width: 12),
            Text(
              'Get Styled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewModel.stylingAdvice != null) ...[
          Container(
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
                    viewModel.stylingAdvice!,
                    style: const TextStyle(
                      color: GoldFitTheme.textDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Recommended for Today',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: GoldFitTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        
        if (recommendations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No recommendations available',
                style: TextStyle(
                  fontSize: 14,
                  color: GoldFitTheme.textLight,
                ),
              ),
            ),
          )
        else
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
      ],
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database seeded successfully! Please restart the app or refresh.')),
                  );
                } catch (e) {
                  if (!mounted) return;
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
