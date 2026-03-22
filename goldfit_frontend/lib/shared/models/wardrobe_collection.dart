class WardrobeCollection {
  final String id;
  final String name;
  final List<String> itemIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  WardrobeCollection({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.createdAt,
    required this.updatedAt,
  });

  WardrobeCollection copyWith({
    String? name,
    List<String>? itemIds,
    DateTime? updatedAt,
  }) {
    return WardrobeCollection(
      id: id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
