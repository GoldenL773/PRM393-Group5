/// Represents a clothing item in the wardrobe with all its properties and metadata.
class ClothingItem {
  final String id;
  final String imageUrl;
  final ClothingType type;
  final String color;
  final List<Season> seasons;
  final double? price;
  final int usageCount;
  final DateTime addedDate;

  ClothingItem({
    required this.id,
    required this.imageUrl,
    required this.type,
    required this.color,
    required this.seasons,
    this.price,
    this.usageCount = 0,
    required this.addedDate,
  });

  /// Creates a copy of this ClothingItem with the given fields replaced with new values.
  ClothingItem copyWith({
    String? imageUrl,
    ClothingType? type,
    String? color,
    List<Season>? seasons,
    double? price,
    int? usageCount,
  }) {
    return ClothingItem(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      color: color ?? this.color,
      seasons: seasons ?? this.seasons,
      price: price ?? this.price,
      usageCount: usageCount ?? this.usageCount,
      addedDate: addedDate,
    );
  }

  /// Converts this ClothingItem to a JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'type': type.name,
      'color': color,
      'seasons': seasons.map((s) => s.name).toList(),
      'price': price,
      'usageCount': usageCount,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  /// Creates a ClothingItem from a JSON map.
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      type: ClothingType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      color: json['color'] as String,
      seasons: (json['seasons'] as List<dynamic>)
          .map((s) => Season.values.firstWhere((e) => e.name == s))
          .toList(),
      price: json['price'] as double?,
      usageCount: json['usageCount'] as int,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }
}

/// Enum representing the different types of clothing items.
enum ClothingType {
  tops,
  bottoms,
  outerwear,
  shoes,
  accessories,
}

/// Enum representing the seasons a clothing item is suitable for.
enum Season {
  spring,
  summer,
  fall,
  winter,
}
