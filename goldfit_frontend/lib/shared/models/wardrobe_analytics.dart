import 'package:goldfit_frontend/shared/models/clothing_item.dart';

/// Analytics data model for wardrobe insights and statistics
class WardrobeAnalytics {
  final int totalItems;
  final double totalValue;
  final List<ClothingItem> mostWorn;
  final List<ClothingItem> leastWorn;
  final List<ClothingItem> mostValueForMoney;
  final List<ClothingItem> mostWasteful;
  final Map<String, double> categoryValueDistribution;

  WardrobeAnalytics({
    required this.totalItems,
    required this.totalValue,
    required this.mostWorn,
    required this.leastWorn,
    this.mostValueForMoney = const [],
    this.mostWasteful = const [],
    this.categoryValueDistribution = const {},
  });

  /// Create a copy with modified fields
  WardrobeAnalytics copyWith({
    int? totalItems,
    double? totalValue,
    List<ClothingItem>? mostWorn,
    List<ClothingItem>? leastWorn,
    List<ClothingItem>? mostValueForMoney,
    List<ClothingItem>? mostWasteful,
    Map<String, double>? categoryValueDistribution,
  }) {
    return WardrobeAnalytics(
      totalItems: totalItems ?? this.totalItems,
      totalValue: totalValue ?? this.totalValue,
      mostWorn: mostWorn ?? this.mostWorn,
      leastWorn: leastWorn ?? this.leastWorn,
      mostValueForMoney: mostValueForMoney ?? this.mostValueForMoney,
      mostWasteful: mostWasteful ?? this.mostWasteful,
      categoryValueDistribution: categoryValueDistribution ?? this.categoryValueDistribution,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'totalValue': totalValue,
      'mostWorn': mostWorn.map((item) => item.toJson()).toList(),
      'leastWorn': leastWorn.map((item) => item.toJson()).toList(),
      'mostValueForMoney': mostValueForMoney.map((item) => item.toJson()).toList(),
      'mostWasteful': mostWasteful.map((item) => item.toJson()).toList(),
      'categoryValueDistribution': categoryValueDistribution,
    };
  }

  /// Create from JSON
  factory WardrobeAnalytics.fromJson(Map<String, dynamic> json) {
    return WardrobeAnalytics(
      totalItems: json['totalItems'] as int? ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      mostWorn: (json['mostWorn'] as List<dynamic>?)
          ?.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      leastWorn: (json['leastWorn'] as List<dynamic>?)
          ?.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      mostValueForMoney: (json['mostValueForMoney'] as List<dynamic>?)
          ?.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      mostWasteful: (json['mostWasteful'] as List<dynamic>?)
          ?.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      categoryValueDistribution: (json['categoryValueDistribution'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
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
