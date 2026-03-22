import 'dart:convert';
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
    Future.microtask(() {
      _setLoading(true);
      _setError(null);
    });

    try {
      final weatherData = await _weatherService.getCurrentWeather();
      final weatherStr = weatherData != null 
          ? '${weatherData.condition}, ${weatherData.temperature}°C' 
          : 'Sunny, 24°C';

      final allItems = await _clothingRepository.getAll();
      if (allItems.isEmpty) {
        _setError('Your wardrobe is empty! Add some items first.');
        return;
      }

      String contextStr = 'Weather: $weatherStr.';
      if (vibe != null) contextStr += ' Vibe: $vibe.';
      if (eventDescription != null) contextStr += ' Event: $eventDescription.';

      final jsonResponse = await _geminiService.getStyleRecommendations(contextStr, allItems.toList());
      
      List<Outfit> generatedOutfits = [];
      Map<String, List<ClothingItem>> itemsMap = {};

      if (jsonResponse != null) {
        try {
          final decoded = jsonDecode(jsonResponse);
          if (decoded is List) {
            int idx = 0;
            for (var j in decoded) {
              final String name = j['name'] ?? 'Recommended Look';
              final String advice = j['advice'] ?? '';
              final List<String> itemIds = List<String>.from(j['item_ids'] ?? []);

              if (itemIds.isNotEmpty) {
                final outfitId = 'virtual_rec_${DateTime.now().millisecondsSinceEpoch}_${idx++}';
                final outfit = Outfit(
                  id: outfitId,
                  name: name,
                  itemIds: itemIds,
                  vibe: advice,
                  eventName: eventDescription,
                  createdDate: DateTime.now(),
                );

                final List<ClothingItem> outItems = [];
                for (final id in itemIds) {
                  final item = allItems.firstWhere((i) => i.id == id, orElse: () => allItems.first);
                  if (item.id == id) outItems.add(item);
                }

                if (outItems.isNotEmpty) {
                  generatedOutfits.add(outfit);
                  itemsMap[outfitId] = outItems;
                }
              }
            }
          }
        } catch (e) {
          print('Error parsing style recommendations json: $e');
        }
      }

      _recommendations = generatedOutfits;
      _recommendationItems = itemsMap;
      
      if (_recommendations.isEmpty) {
        _aiAdvice = "We couldn't generate a specific look. Here are your existing outfits instead.";
        // Fallback to loading existing outfits
        final existing = await _outfitRepository.getAll();
        _recommendations = existing.take(5).toList();
        for (var o in _recommendations) {
           final List<ClothingItem> temp = [];
           for (var id in o.itemIds) {
             final i = await _clothingRepository.getById(id);
             if (i != null) temp.add(i);
           }
           itemsMap[o.id] = temp;
        }
      } else {
        _aiAdvice = "Here are some curated looks perfectly matching your requested style!";
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
