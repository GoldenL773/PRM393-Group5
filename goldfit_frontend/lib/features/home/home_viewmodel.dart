import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/weather_data.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/services/weather_service.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<ClothingItem> _recommendedItems = []; // Individual items filtered by season+color
  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;
  String? _stylingAdvice;
  // Debug log for AI responses
  String? _aiDebugLog;

  // Getters
  List<Outfit> get recommendations => _recommendations;
  Map<String, List<ClothingItem>> get recommendationItems => _recommendationItems;
  List<ClothingItem> get recommendedItems => _recommendedItems;
  WeatherData? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get stylingAdvice => _stylingAdvice;
  String? get aiDebugLog => _aiDebugLog;

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
  /// Uses AI to determine target seasons and colors, then filters individual
  /// clothing items that match those criteria.
  Future<void> loadRecommendations() async {
    _setLoading(true);
    _setError(null);

    try {
      final allItems = await _clothingRepository.getAll();
      final allOutfits = await _outfitRepository.getAll();
      
      final Map<String, List<ClothingItem>> itemsMap = {};
      for (final outfit in allOutfits) {
        final List<ClothingItem> items = [];
        for (final itemId in outfit.itemIds) {
          final item = await _clothingRepository.getById(itemId);
          if (item != null) {
            items.add(item);
          }
        }
        itemsMap[outfit.id] = items;
      }
      
      List<String> targetSeasons = ['summer', 'spring'];

      if (_weather != null && allItems.isNotEmpty) {
        final weatherStr = '${_weather!.condition}, ${_weather!.temperature}°C';
        
        // Determine granular target seasons 
        if (_weather!.temperature >= 26) {
          targetSeasons = ['summer'];
        } else if (_weather!.temperature >= 18) {
          targetSeasons = ['summer', 'spring'];
        } else if (_weather!.temperature >= 12) {
          targetSeasons = ['spring', 'fall', 'autumn'];
        } else {
          targetSeasons = ['winter', 'fall', 'autumn'];
        }

        // Cache key based on date, weather condition, temperature bucket (2°C), and wardrobe count
        final dateKey = DateTime.now().toIso8601String().substring(0, 10);
        final tempBucket = (_weather!.temperature / 2).round() * 2;
        final weatherCond = _weather!.condition.replaceAll(' ', '_');
        final wardrobeCount = allItems.length;
        
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'ai_recs_${dateKey}_${weatherCond}_t${tempBucket}_w$wardrobeCount';
        String? jsonResponse = prefs.getString(cacheKey);

        if (jsonResponse == null || jsonResponse.isEmpty) {
          // Fetch from AI
          jsonResponse = await _geminiService.getOutfitRecommendation(weatherStr, allItems);
          if (jsonResponse != null && jsonResponse.isNotEmpty) {
            await prefs.setString(cacheKey, jsonResponse);
          }
        }

        _aiDebugLog = 'Weather: $weatherStr (Bucket: ${tempBucket}°C)\\n'
            'Cache Key: $cacheKey\\n'
            'Response: $jsonResponse';

        if (jsonResponse != null) {
          try {
            final decoded = jsonDecode(jsonResponse) as Map<String, dynamic>;
            _stylingAdvice = decoded['advice'] as String?;
            
            final itemIds = List<String>.from(decoded['item_ids'] ?? []);
            
            _recommendedItems.clear();
            for (final id in itemIds) {
              final item = await _clothingRepository.getById(id);
              if (item != null) _recommendedItems.add(item);
            }
          } catch (e) {
            print('Error parsing AI json: $e | raw: $jsonResponse');
            _aiDebugLog = '$_aiDebugLog\\nParse error: $e';
          }
        }
      }

      // If AI failed or empty, fallback to local filtering
      if (_recommendedItems.isEmpty && allItems.isNotEmpty) {
        _recommendedItems = _filterRecommendedItems(allItems, targetSeasons, []);
        _stylingAdvice = "Welcome! Tap 'Get Styled' for personalized AI outfit recommendations based on the weather.";
      }

      // 2. Sort outfits by season match for the outfit-based section
      List<Outfit> recommendedOutfits = allOutfits.toList();
      recommendedOutfits.sort((a, b) {
        final aItems = itemsMap[a.id] ?? [];
        final bItems = itemsMap[b.id] ?? [];
        
        final aMatchCount = aItems.where((i) => i.seasons.any((s) => targetSeasons.contains(s.toString().split('.').last.toLowerCase()))).length;
        final bMatchCount = bItems.where((i) => i.seasons.any((s) => targetSeasons.contains(s.toString().split('.').last.toLowerCase()))).length;
        
        return bMatchCount.compareTo(aMatchCount); // Descending
      });
      
      // Take top 3 outfits
      final topOutfits = recommendedOutfits.take(3).toList();
      _recommendations = topOutfits;
      _recommendationItems = itemsMap;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Filters clothing items by target seasons and optionally by color keywords.
  List<ClothingItem> _filterRecommendedItems(
    List<ClothingItem> allItems,
    List<String> targetSeasons,
    List<String> targetColors,
  ) {
    // Normalize targets
    final normalizedSeasons = targetSeasons.map((s) => s.toLowerCase().trim()).toSet();
    final normalizedColors = targetColors.map((c) => c.toLowerCase().trim()).toSet();

    // First: items that match both season AND color
    List<ClothingItem> seasonAndColorMatch = [];
    // Second: items that match only season
    List<ClothingItem> seasonOnlyMatch = [];

    for (final item in allItems) {
      final itemSeasons = item.seasons
          .map((s) => s.toString().split('.').last.toLowerCase())
          .toSet();
      
      // Check season match: 'fall' = 'autumn' alias
      final matchesSeason = itemSeasons.any((itemSeason) {
        return normalizedSeasons.contains(itemSeason) ||
            (itemSeason == 'fall' && normalizedSeasons.contains('autumn')) ||
            (itemSeason == 'autumn' && normalizedSeasons.contains('fall'));
      });

      if (!matchesSeason) continue;

      // Check color match (partial/keyword match)
      final itemColorLower = item.color.toLowerCase();
      final matchesColor = normalizedColors.isEmpty ||
          normalizedColors.any((targetColor) =>
              itemColorLower.contains(targetColor) ||
              targetColor.contains(itemColorLower));

      if (matchesSeason && matchesColor) {
        seasonAndColorMatch.add(item);
      } else {
        seasonOnlyMatch.add(item);
      }
    }

    // Return best matches first, then season-only matches; limit to 10
    final combined = [...seasonAndColorMatch, ...seasonOnlyMatch];
    return combined.take(10).toList();
  }

  /// Updates the weather data.
  void updateWeather(WeatherData weatherData) {
    _weather = weatherData;
    notifyListeners();
  }

  /// Refreshes recommendations and weather data.
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
