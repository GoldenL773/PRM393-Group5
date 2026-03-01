import 'clothing_item.dart';

/// Analytics data model for wardrobe insights and statistics
class WardrobeAnalytics {
  final int totalItems;
  final double totalValue;
  final List<ClothingItem> mostWorn;
  final List<ClothingItem> leastWorn;

  WardrobeAnalytics({
    required this.totalItems,
    required this.totalValue,
    required this.mostWorn,
    required this.leastWorn,
  });

  /// Create a copy with modified fields
  WardrobeAnalytics copyWith({
    int? totalItems,
    double? totalValue,
    List<ClothingItem>? mostWorn,
    List<ClothingItem>? leastWorn,
  }) {
    return WardrobeAnalytics(
      totalItems: totalItems ?? this.totalItems,
      totalValue: totalValue ?? this.totalValue,
      mostWorn: mostWorn ?? this.mostWorn,
      leastWorn: leastWorn ?? this.leastWorn,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'totalValue': totalValue,
      'mostWorn': mostWorn.map((item) => item.toJson()).toList(),
      'leastWorn': leastWorn.map((item) => item.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory WardrobeAnalytics.fromJson(Map<String, dynamic> json) {
    return WardrobeAnalytics(
      totalItems: json['totalItems'] as int,
      totalValue: (json['totalValue'] as num).toDouble(),
      mostWorn: (json['mostWorn'] as List<dynamic>)
          .map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      leastWorn: (json['leastWorn'] as List<dynamic>)
          .map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WardrobeAnalytics &&
        other.totalItems == totalItems &&
        other.totalValue == totalValue &&
        _listEquals(other.mostWorn, mostWorn) &&
        _listEquals(other.leastWorn, leastWorn);
  }

  @override
  int get hashCode {
    return Object.hash(
      totalItems,
      totalValue,
      Object.hashAll(mostWorn),
      Object.hashAll(leastWorn),
    );
  }

  @override
  String toString() {
    return 'WardrobeAnalytics(totalItems: $totalItems, totalValue: $totalValue, mostWorn: ${mostWorn.length} items, leastWorn: ${leastWorn.length} items)';
  }

  /// Helper method to compare lists of ClothingItems
  bool _listEquals(List<ClothingItem> a, List<ClothingItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
