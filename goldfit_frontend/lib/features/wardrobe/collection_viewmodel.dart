import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_collection.dart';
import 'package:goldfit_frontend/shared/repositories/collection_repository.dart';

class CollectionViewModel extends ChangeNotifier {
  final CollectionRepository _collectionRepository;

  List<WardrobeCollection> _collections = [];
  bool _isLoading = false;
  String? _error;

  CollectionViewModel(this._collectionRepository);

  List<WardrobeCollection> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCollections() async {
    _setLoading(true);
    _setError(null);

    try {
      _collections = await _collectionRepository.getAll();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load collections: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCollection({
    required String name,
    required List<String> itemIds,
  }) async {
    final now = DateTime.now();
    final collection = WardrobeCollection(
      id: const Uuid().v4(),
      name: name.trim(),
      itemIds: itemIds,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final created = await _collectionRepository.create(collection);
      _collections.insert(0, created);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create collection: $e');
      rethrow;
    }
  }

  Future<void> updateCollection({
    required String collectionId,
    required String name,
    required List<String> itemIds,
  }) async {
    final current = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw Exception('Collection not found'),
    );

    final updated = current.copyWith(
      name: name.trim(),
      itemIds: itemIds,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _collectionRepository.update(updated);
      final index = _collections.indexWhere((c) => c.id == collectionId);
      if (index != -1) {
        _collections[index] = saved;
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to update collection: $e');
      rethrow;
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await _collectionRepository.delete(id);
      _collections.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete collection: $e');
      rethrow;
    }
  }

  WardrobeCollection? getById(String id) {
    try {
      return _collections.firstWhere((collection) => collection.id == id);
    } catch (_) {
      return null;
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
