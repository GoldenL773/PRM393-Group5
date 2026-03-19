import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';

/// ViewModel for the Wardrobe screen that manages UI state and business logic.
/// 
/// Extends ChangeNotifier to provide reactive state updates to the UI.
/// Handles loading, filtering, and CRUD operations for clothing items.
/// 
/// **Validates Requirements:** 14.1, 14.2, 14.3, 14.4, 14.5
class WardrobeViewModel extends ChangeNotifier {
  final ClothingRepository _clothingRepository;

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
  /// 
  /// Sets loading state, clears errors, and fetches items.
  /// Updates error state if the operation fails.
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
  /// 
  /// Updates the filter state and fetches filtered items from the repository.
  /// Updates error state if the operation fails.
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
  /// Creates the item in the repository and adds it to the local state.
  /// Updates error state if the operation fails.
  Future<void> addItem(ClothingItem item) async {
    try {
      final created = await _clothingRepository.create(item);
      _items.insert(0, created);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add item: $e');
    }
  }

  /// Updates an existing clothing item in the wardrobe.
  /// 
  /// Updates the item in the repository and updates the local state.
  /// Updates error state if the operation fails.
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
  /// 
  /// Removes the item from the repository and updates the local state.
  /// Updates error state if the operation fails.
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
