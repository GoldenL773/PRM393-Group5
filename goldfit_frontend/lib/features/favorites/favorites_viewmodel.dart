import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';

/// ViewModel for the Favorites screen that manages favorited outfits.
class FavoritesViewModel extends ChangeNotifier {
  final OutfitRepository _outfitRepository;
  final ClothingRepository _clothingRepository;

  List<Outfit> _favoriteOutfits = [];
  List<ClothingItem> _favoriteClothes = [];
  bool _isLoading = false;
  String? _error;
  String _selectedVibe = 'All';
  String _selectedClothingCategory = 'All';

  List<Outfit> get favoriteOutfits => _favoriteOutfits;
  List<ClothingItem> get favoriteClothes => _favoriteClothes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedVibe => _selectedVibe;
  String get selectedClothingCategory => _selectedClothingCategory;

  FavoritesViewModel(this._outfitRepository, this._clothingRepository) {
    loadFavorites();
  }

  /// Loads all favorited outfits from the repository.
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allOutfits = await _outfitRepository.getAll();
      _favoriteOutfits = allOutfits.where((o) => o.isFavorite).toList();
      
      final allClothes = await _clothingRepository.getAll();
      _favoriteClothes = allClothes.where((c) => c.isFavorite).toList();
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load favorite outfits: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the selected vibe filter and notifies listeners.
  void setVibeFilter(String vibe) {
    _selectedVibe = vibe;
    notifyListeners();
  }

  /// Returns favorite outfits filtered by the selected vibe.
  List<Outfit> get filteredFavorites {
    if (_selectedVibe == 'All') {
      return _favoriteOutfits;
    }
    return _favoriteOutfits.where((o) => o.vibe == _selectedVibe).toList();
  }

  /// Sets the selected clothing category filter
  void setClothingCategoryFilter(String category) {
    _selectedClothingCategory = category;
    notifyListeners();
  }

  /// Returns favorite clothes filtered by the selected category.
  List<ClothingItem> get filteredFavoriteClothes {
    if (_selectedClothingCategory == 'All') {
      return _favoriteClothes;
    }
    return _favoriteClothes.where((c) => 
      c.type.toString().split('.').last.toLowerCase() == _selectedClothingCategory.toLowerCase()
    ).toList();
  }

  /// Toggles favorite status for an outfit.
  Future<void> toggleFavorite(Outfit outfit) async {
    try {
      final updated = outfit.copyWith(isFavorite: !outfit.isFavorite);
      await _outfitRepository.update(updated);
      
      // Update local list
      if (updated.isFavorite) {
        if (!_favoriteOutfits.any((o) => o.id == updated.id)) {
           _favoriteOutfits.insert(0, updated);
        }
      } else {
        _favoriteOutfits.removeWhere((o) => o.id == updated.id);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update favorite: $e';
      notifyListeners();
    }
  }

  /// Toggles favorite status for a clothing item.
  Future<void> toggleFavoriteClothing(ClothingItem item) async {
    try {
      final updated = item.copyWith(isFavorite: !item.isFavorite);
      await _clothingRepository.update(updated);
      
      // Update local list
      if (updated.isFavorite) {
        if (!_favoriteClothes.any((c) => c.id == updated.id)) {
           _favoriteClothes.insert(0, updated);
        }
      } else {
        _favoriteClothes.removeWhere((c) => c.id == updated.id);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update favorite clothing: $e';
      notifyListeners();
    }
  }

  /// Saves a new outfit and adds it to favorites.
  Future<void> saveOutfit(Outfit outfit) async {
    try {
      final created = await _outfitRepository.create(outfit);
      
      if (created.isFavorite) {
        if (!_favoriteOutfits.any((o) => o.id == created.id)) {
          _favoriteOutfits.insert(0, created);
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save outfit: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Resolves item IDs to ClothingItem objects for an outfit.
  Future<List<ClothingItem>> getItemsForOutfit(Outfit outfit) async {
    final items = <ClothingItem>[];
    for (var id in outfit.itemIds) {
      final item = await _clothingRepository.getById(id);
      if (item != null) items.add(item);
    }
    return items;
  }
}
