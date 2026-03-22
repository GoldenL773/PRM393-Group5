import 'package:goldfit_frontend/shared/models/wardrobe_collection.dart';

abstract class CollectionRepository {
  Future<WardrobeCollection> create(WardrobeCollection collection);
  Future<WardrobeCollection?> getById(String id);
  Future<List<WardrobeCollection>> getAll();
  Future<WardrobeCollection> update(WardrobeCollection collection);
  Future<void> delete(String id);
}
