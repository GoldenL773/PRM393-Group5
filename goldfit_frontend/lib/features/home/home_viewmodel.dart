import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/weather_data.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/services/weather_service.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';

/// ViewModel for the Home screen that manages UI state and business logic.
/// 
/// Extends ChangeNotifier to provide reactive state updates to the UI.
/// Handles loading weather-based outfit recommendations and managing error states.
/// 
/// **Validates Requirements:** 14.1, 14.2, 14.3, 14.4, 14.5
class HomeViewModel extends ChangeNotifier {
  final OutfitRepository _outfitRepository;
  final ClothingRepository _clothingRepository;
  final WeatherService _weatherService = WeatherService();
  final GeminiService _geminiService = GeminiService();

  // State properties
  List<Outfit> _recommendations = [];
  Map<String, List<ClothingItem>> _recommendationItems = {};
  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;
  String? _stylingAdvice;

  // Getters
  List<Outfit> get recommendations => _recommendations;
  Map<String, List<ClothingItem>> get recommendationItems => _recommendationItems;
  WeatherData? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get stylingAdvice => _stylingAdvice;

  HomeViewModel(this._outfitRepository, this._clothingRepository) {
    _initWeather();
  }

  Future<void> _initWeather() async {
    final weatherData = await _weatherService.getCurrentWeather();
    if (weatherData != null) {
      _weather = weatherData;
      notifyListeners();
    } else {
      // Mock data if failed
      _weather = WeatherData(
        temperature: 24.0,
        condition: 'Sunny',
        location: 'Hanoi',
        timestamp: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Loads weather-based outfit recommendations from the repository.
  /// 
  /// Sets loading state, clears errors, and fetches recommended outfits.
  /// In the current implementation, this fetches all outfits and takes the top 3.
  /// Future implementations could integrate with a weather service to provide
  /// context-aware recommendations based on temperature and conditions.
  /// Updates error state if the operation fails.
  Future<void> loadRecommendations() async {
    _setLoading(true);
    _setError(null);

    try {
      // Fetch all outfits and take top 3 as recommendations
      // In a future implementation, this could filter based on weather context
      final allOutfits = await _outfitRepository.getAll();
      final topOutfits = allOutfits.take(3).toList();
      
      // Load items for each recommendation
      final Map<String, List<ClothingItem>> itemsMap = {};
      for (final outfit in topOutfits) {
        final List<ClothingItem> items = [];
        for (final itemId in outfit.itemIds) {
          final item = await _clothingRepository.getById(itemId);
          if (item != null) {
            items.add(item);
          }
        }
        itemsMap[outfit.id] = items;
      }
      
      _recommendations = topOutfits;
      _recommendationItems = itemsMap;
      
      // Get AI styling advice based on top outfit and weather
      if (topOutfits.isNotEmpty && _weather != null) {
        final topItems = itemsMap[topOutfits.first.id] ?? [];
        _stylingAdvice = await _geminiService.getStylingAdvice(
          topItems,
          '${_weather!.condition}, ${_weather!.temperature}°C',
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the weather data.
  /// 
  /// This method allows the UI or a weather service to update the current
  /// weather information. Future implementations could trigger automatic
  /// recommendation updates when weather changes.
  void updateWeather(WeatherData weatherData) {
    _weather = weatherData;
    notifyListeners();
  }

  /// Refreshes recommendations and weather data.
  /// 
  /// Convenience method that reloads recommendations. Can be called by
  /// pull-to-refresh gestures in the UI.
  Future<void> refresh() async {
    await loadRecommendations();
  }

  /// Sets the loading state and notifies listeners.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets the error state and notifies listeners.
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
