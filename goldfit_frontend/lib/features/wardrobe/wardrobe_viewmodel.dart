import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';

/// ViewModel for the Wardrobe screen that manages UI state and business logic.
class WardrobeViewModel extends ChangeNotifier {
  final ClothingRepository _clothingRepository;
  final GeminiService _geminiService = GeminiService();

  // State properties
  List<ClothingItem> _items = [];
  bool _isLoading = false;
  String? _error;
  FilterState _filters = FilterState.empty();

  // Getters
  List<ClothingItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FilterState get filters => _filters;

  WardrobeViewModel(this._clothingRepository);

  /// Loads all clothing items and syncs usage counts from planner.
  Future<void> loadItems({OutfitRepository? outfitRepo}) async {
    _setLoading(true);
    _setError(null);

    try {
      if (outfitRepo != null) {
        await syncUsageCountsWithPlanner(outfitRepo);
      }
      _items = await _clothingRepository.getAll();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load wardrobe items: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Syncs clothing usage counts by scanning the Planner history.
  /// Logic: Usage Count = Total days in Planner containing this Item ID up to Today.
  Future<void> syncUsageCountsWithPlanner(OutfitRepository outfitRepository) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      // 1. Get all assigned outfits from the past until today
      final pastAssignments = await outfitRepository.getByDateRange(
        DateTime(2020, 1, 1), // Realistic past starting point
        today,
      );

      // 2. Aggregate counts per Item ID
      final Map<String, int> usageMap = {};
      for (final outfit in pastAssignments) {
        for (final itemId in outfit.itemIds) {
          usageMap[itemId] = (usageMap[itemId] ?? 0) + 1;
        }
      }

      // 3. Update items in DB if count changed
      final allItems = await _clothingRepository.getAll();
      for (var item in allItems) {
        final actualUsage = usageMap[item.id] ?? 0;
        if (item.usageCount != actualUsage) {
          await _clothingRepository.update(item.copyWith(usageCount: actualUsage));
        }
      }
    } catch (e) {
      debugPrint('Usage sync error: $e');
      // Non-critical error, don't block the UI
    }
  }

  /// Applies the specified filters to the wardrobe items.
  Future<void> applyFilters(FilterState filters) async {
    _filters = filters;
    _setLoading(true);
    _setError(null);

    try {
      _items = await _clothingRepository.getByFilters(filters);
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter items: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a new clothing item to the wardrobe.
  /// 
  /// Automatically triggers background removal in the background.
  Future<void> addItem(ClothingItem item) async {
    try {
      final created = await _clothingRepository.create(item);
      _items.insert(0, created);
      notifyListeners();

      // Proactively trigger background removal for cleaner Quick Try
      _cleanItemBackground(created);
    } catch (e) {
      _setError('Failed to add item: $e');
    }
  }

  /// Triggers background removal for an item and updates it in the database.
  Future<void> _cleanItemBackground(ClothingItem item) async {
    if (item.cleanedImageUrl != null) return;

    try {
      final cleanedPath = await _geminiService.removeBackground(item.imageUrl);
      if (cleanedPath != null) {
        final updatedItem = item.copyWith(cleanedImageUrl: cleanedPath);
        await _clothingRepository.update(updatedItem);
        
        // Update in local state if still present
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
          notifyListeners();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Proactive background removal failed: $e');
    }
  }

  /// Updates an existing clothing item in the wardrobe.
  Future<void> updateItem(ClothingItem item) async {
    try {
      final updated = await _clothingRepository.update(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update item: $e');
    }
  }

  /// Toggles the favorite status of a clothing item.
  Future<void> toggleFavorite(String id) async {
    final itemIndex = _items.indexWhere((i) => i.id == id);
    if (itemIndex == -1) return;
    
    final item = _items[itemIndex];
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    
    try {
      // Optimistic update
      _items[itemIndex] = updatedItem;
      notifyListeners();
      
      await _clothingRepository.update(updatedItem);
    } catch (e) {
      // Revert on failure
      _items[itemIndex] = item;
      notifyListeners();
      _setError('Failed to update favorite status: $e');
    }
  }

  /// Deletes a clothing item from the wardrobe.
  Future<void> deleteItem(String id) async {
    try {
      await _clothingRepository.delete(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete item: $e');
    }
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
