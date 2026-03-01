import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/outfit_card.dart';
import '../utils/theme.dart';
import '../utils/navigation_manager.dart';

/// Home screen displaying weather information and outfit recommendations
/// Shows weather widget, "Get Styled" button, and recommended outfits
/// 
/// Requirements: 3.1, 3.2, 3.5, 7.1
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final weather = appState.currentWeather;
    final recommendations = appState.weatherRecommendations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh delay
          await Future.delayed(const Duration(milliseconds: 500));
          // In a real app, this would fetch new data
          // For now, the mock data remains the same
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
                
                // Recommended outfits section
                _buildRecommendedOutfitsSection(context, appState, recommendations),
              ],
            ),
          ),
        ),
      ),
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
    AppState appState,
    List<dynamic> recommendations,
  ) {
    final navigationManager = Provider.of<NavigationManager>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for Today',
          style: TextStyle(
            fontSize: 22, // Tăng nhẹ size heading
            fontWeight: FontWeight.w700, // Cứng cáp hơn
            color: GoldFitTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20), // Tăng khoảng cách margin bottom
        
        if (recommendations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
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
          ...recommendations.take(3).map((outfit) {
            final items = appState.dataProvider.getItemsByIds(outfit.itemIds);
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
          }).toList(),
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
}
