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
  bool _isLoading = false;
  String? _error;
  String _selectedVibe = 'All';

  List<Outfit> get favoriteOutfits => _favoriteOutfits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedVibe => _selectedVibe;

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
