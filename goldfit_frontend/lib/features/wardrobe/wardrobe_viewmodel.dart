import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
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

  /// Loads all clothing items from the repository.
  Future<void> loadItems() async {
    _setLoading(true);
    _setError(null);

    try {
      _items = await _clothingRepository.getAll();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load wardrobe items: $e');
    } finally {
      _setLoading(false);
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
