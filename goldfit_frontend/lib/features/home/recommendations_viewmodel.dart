import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/weather_data.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/services/weather_service.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';

class RecommendationsViewModel extends ChangeNotifier {
  final OutfitRepository _outfitRepository;
  final ClothingRepository _clothingRepository;
  final WeatherService _weatherService = WeatherService();
  final GeminiService _geminiService = GeminiService();

  List<Outfit> _recommendations = [];
  Map<String, List<ClothingItem>> _recommendationItems = {};
  String? _aiAdvice;
  bool _isLoading = false;
  String? _error;

  List<Outfit> get recommendations => _recommendations;
  Map<String, List<ClothingItem>> get recommendationItems => _recommendationItems;
  String? get aiAdvice => _aiAdvice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RecommendationsViewModel(this._outfitRepository, this._clothingRepository);

  Future<void> loadRecommendations({String? vibe, String? eventDescription}) async {
    _setLoading(true);
    _setError(null);

    try {
      final weatherData = await _weatherService.getCurrentWeather();
      final weatherStr = weatherData != null 
          ? '${weatherData.condition}, ${weatherData.temperature}°C' 
          : 'Sunny, 24°C';

      final allOutfits = await _outfitRepository.getAll();
      
      final Map<String, List<ClothingItem>> itemsMap = {};
      for (final outfit in allOutfits) {
        final List<ClothingItem> items = [];
        for (final itemId in outfit.itemIds) {
          final item = await _clothingRepository.getById(itemId);
          if (item != null) items.add(item);
        }
        itemsMap[outfit.id] = items;
      }

      String contextStr = weatherStr;
      if (vibe != null) contextStr += ' for a $vibe vibe';
      if (eventDescription != null) contextStr += ' for event: $eventDescription';

      final bestId = await _geminiService.recommendBestOutfit(allOutfits, itemsMap, contextStr);
      
      List<Outfit> sortedOutfits = allOutfits.toList();
      if (bestId != null) {
        final index = sortedOutfits.indexWhere((o) => o.id == bestId);
        if (index != -1) {
          final best = sortedOutfits.removeAt(index);
          sortedOutfits.insert(0, best);
        }
      }

      _recommendations = sortedOutfits.take(5).toList();
      _recommendationItems = itemsMap;

      if (_recommendations.isNotEmpty) {
        final topItems = itemsMap[_recommendations.first.id] ?? [];
        _aiAdvice = await _geminiService.getStylingAdvice(topItems, contextStr);
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to get AI recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
