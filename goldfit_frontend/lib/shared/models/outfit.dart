import 'package:goldfit_frontend/shared/models/clothing_item.dart';

/// Represents an outfit composed of multiple clothing items.
/// 
/// An outfit is a combination of clothing items that can be assigned to a specific date
/// and associated with a particular vibe or occasion.
class Outfit {
  final String id;
  final String name;
  final List<String> itemIds; // References to ClothingItem IDs
  final DateTime? assignedDate;
  final String? vibe; // e.g., Casual, Work, Date Night
  final DateTime createdDate;
  final bool isFavorite;
  final String? modelImagePath;
  final String? resultImagePath;

  Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.assignedDate,
    this.vibe,
    required this.createdDate,
    this.isFavorite = false,
    this.modelImagePath,
    this.resultImagePath,
  });

  /// Resolves the item IDs to actual ClothingItem objects.
  /// 
  /// This method requires a function that can retrieve ClothingItems by their IDs.
  /// Typically, this would be provided by the MockDataProvider.
  /// 
  /// Returns a list of ClothingItems that are part of this outfit.
  /// Items that cannot be found are excluded from the result.
  List<ClothingItem> getItems(ClothingItem? Function(String) getItemById) {
    return itemIds
        .map((id) => getItemById(id))
        .where((item) => item != null)
        .cast<ClothingItem>()
        .toList();
  }

  /// Creates a copy of this Outfit with the given fields replaced with new values.
  Outfit copyWith({
    String? name,
    List<String>? itemIds,
    DateTime? assignedDate,
    String? vibe,
    bool? isFavorite,
    String? modelImagePath,
    String? resultImagePath,
  }) {
    return Outfit(
      id: id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
      assignedDate: assignedDate ?? this.assignedDate,
      vibe: vibe ?? this.vibe,
      createdDate: createdDate,
      isFavorite: isFavorite ?? this.isFavorite,
      modelImagePath: modelImagePath ?? this.modelImagePath,
      resultImagePath: resultImagePath ?? this.resultImagePath,
    );
  }

  /// Converts this Outfit to a JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemIds': itemIds,
      'assignedDate': assignedDate?.toIso8601String(),
      'vibe': vibe,
      'createdDate': createdDate.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'modelImagePath': modelImagePath,
      'resultImagePath': resultImagePath,
    };
  }

  /// Creates an Outfit from a JSON map.
  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as String,
      name: json['name'] as String,
      itemIds: (json['itemIds'] as List<dynamic>).cast<String>(),
      assignedDate: json['assignedDate'] != null
          ? DateTime.parse(json['assignedDate'] as String)
          : null,
      vibe: json['vibe'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      isFavorite: (json['isFavorite'] as int?) == 1,
      modelImagePath: json['modelImagePath'] as String?,
      resultImagePath: json['resultImagePath'] as String?,
    );
  }
}
