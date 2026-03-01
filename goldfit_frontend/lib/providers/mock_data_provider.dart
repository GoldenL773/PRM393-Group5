import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/filter_state.dart';
import '../models/weather_data.dart';
import '../models/wardrobe_analytics.dart';

/// Mock data provider that supplies sample wardrobe items, outfits, and analytics data.
/// 
/// This class serves as the data layer for the GoldFit Frontend, providing all data
/// operations without requiring backend dependencies. It uses in-memory storage with
/// Lists and Maps to manage clothing items, outfits, and their relationships.
class MockDataProvider {
  // Internal storage
  final List<ClothingItem> _items = [];
  final List<Outfit> _outfits = [];
  final Map<DateTime, String> _dateOutfitAssignments = {}; // date -> outfit ID
  late WeatherData _currentWeather;

  MockDataProvider() {
    // Initialize with mock data (to be implemented in task 3.2)
    _initializeMockData();
  }

  // ============================================================================
  // Wardrobe Data Operations
  // ============================================================================

  /// Returns all clothing items in the wardrobe.
  List<ClothingItem> getAllItems() {
    return List.unmodifiable(_items);
  }

  /// Returns clothing items filtered by category/type.
  List<ClothingItem> getItemsByCategory(ClothingType type) {
    return _items.where((item) => item.type == type).toList();
  }

  /// Returns clothing items that match the given filter criteria.
  /// 
  /// Uses the FilterState.matches method to determine if each item
  /// satisfies all active filters.
  List<ClothingItem> getItemsByFilters(FilterState filters) {
    return _items.where((item) => filters.matches(item)).toList();
  }

  /// Returns a single clothing item by its ID, or null if not found.
  ClothingItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Returns a list of clothing items by their IDs.
  /// 
  /// Items that are not found are excluded from the result.
  List<ClothingItem> getItemsByIds(List<String> ids) {
    return ids
        .map((id) => getItemById(id))
        .where((item) => item != null)
        .cast<ClothingItem>()
        .toList();
  }

  /// Updates an existing clothing item with new data.
  /// 
  /// Finds the item by ID and replaces it with the updated version.
  /// If the item is not found, this operation has no effect.
  void updateItem(ClothingItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  /// Adds a new clothing item to the wardrobe.
  void addItem(ClothingItem item) {
    _items.add(item);
  }

  /// Deletes a clothing item by its ID.
  /// 
  /// Also removes the item from any outfits that reference it.
  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    
    // Remove item from outfits
    for (var outfit in _outfits) {
      if (outfit.itemIds.contains(id)) {
        final updatedItemIds = outfit.itemIds.where((itemId) => itemId != id).toList();
        final index = _outfits.indexWhere((o) => o.id == outfit.id);
        if (index != -1) {
          _outfits[index] = outfit.copyWith(itemIds: updatedItemIds);
        }
      }
    }
  }

  // ============================================================================
  // Outfit Data Operations
  // ============================================================================

  /// Returns all saved outfits.
  List<Outfit> getAllOutfits() {
    return List.unmodifiable(_outfits);
  }

  /// Returns a single outfit by its ID, or null if not found.
  Outfit? getOutfitById(String id) {
    try {
      return _outfits.firstWhere((outfit) => outfit.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Saves a new outfit or updates an existing one.
  /// 
  /// If an outfit with the same ID exists, it will be replaced.
  /// Otherwise, the outfit will be added to the collection.
  void saveOutfit(Outfit outfit) {
    final index = _outfits.indexWhere((o) => o.id == outfit.id);
    if (index != -1) {
      _outfits[index] = outfit;
    } else {
      _outfits.add(outfit);
    }
  }

  /// Deletes an outfit by its ID.
  /// 
  /// Also removes any date assignments for this outfit.
  void deleteOutfit(String id) {
    _outfits.removeWhere((outfit) => outfit.id == id);
    
    // Remove date assignments
    _dateOutfitAssignments.removeWhere((date, outfitId) => outfitId == id);
  }

  /// Returns outfits assigned to a specific date.
  /// 
  /// Currently supports one outfit per date. Returns a list for
  /// potential future support of multiple outfits per date.
  List<Outfit> getOutfitsByDate(DateTime date) {
    // Normalize date to midnight for consistent comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final outfitId = _dateOutfitAssignments[normalizedDate];
    
    if (outfitId != null) {
      final outfit = getOutfitById(outfitId);
      return outfit != null ? [outfit] : [];
    }
    return [];
  }

  /// Assigns an outfit to a specific date.
  void assignOutfitToDate(String outfitId, DateTime date) {
    // Normalize date to midnight for consistent storage
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _dateOutfitAssignments[normalizedDate] = outfitId;
  }

  /// Removes outfit assignment from a specific date.
  void unassignOutfitFromDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _dateOutfitAssignments.remove(normalizedDate);
  }

  // ============================================================================
  // Weather and Recommendations
  // ============================================================================

  /// Returns the current mock weather data.
  WeatherData getCurrentWeather() {
    return _currentWeather;
  }

  /// Returns weather-based outfit recommendations.
  /// 
  /// For mock implementation, returns a subset of saved outfits.
  /// In a real implementation, this would use weather data and AI to
  /// recommend appropriate outfits.
  List<Outfit> getWeatherBasedRecommendations() {
    // Return up to 3 outfits as recommendations
    return _outfits.take(3).toList();
  }

  /// Returns outfit recommendations based on a vibe/occasion.
  /// 
  /// Filters outfits by the specified vibe (e.g., "Casual", "Work", "Date Night").
  /// If no outfits match the vibe, returns general recommendations.
  List<Outfit> getVibeBasedRecommendations(String vibe) {
    final matchingOutfits = _outfits
        .where((outfit) => outfit.vibe?.toLowerCase() == vibe.toLowerCase())
        .toList();
    
    // If we have matching outfits, return up to 5
    if (matchingOutfits.isNotEmpty) {
      return matchingOutfits.take(5).toList();
    }
    
    // Otherwise, return general recommendations
    return _outfits.take(5).toList();
  }

  // ============================================================================
  // Analytics
  // ============================================================================

  /// Returns wardrobe analytics including total items, value, and usage statistics.
  WardrobeAnalytics getAnalytics() {
    final totalItems = _items.length;
    final totalValue = _items
        .where((item) => item.price != null)
        .fold(0.0, (sum, item) => sum + item.price!);
    
    // Sort items by usage count
    final sortedByUsage = List<ClothingItem>.from(_items)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    // Get top 5 most worn items
    final mostWorn = sortedByUsage.take(5).toList();
    
    // Get 5 least worn items (reverse order)
    final leastWorn = sortedByUsage.reversed.take(5).toList();
    
    return WardrobeAnalytics(
      totalItems: totalItems,
      totalValue: totalValue,
      mostWorn: mostWorn,
      leastWorn: leastWorn,
    );
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /// Initializes the mock data provider with sample data.
  /// 
  /// This method generates:
  /// - 20-30 diverse clothing items across all categories
  /// - 5-7 sample outfits with valid item references
  /// - Mock weather data
  void _initializeMockData() {
    final uuid = Uuid();
    final random = Random(42); // Fixed seed for consistent mock data
    
    // Generate mock weather data
    _currentWeather = WeatherData(
      temperature: 72.0,
      condition: 'Sunny',
      location: 'San Francisco, CA',
      timestamp: DateTime.now(),
    );
    
    // Generate 25 diverse clothing items across all categories
    _items.addAll(_generateMockClothingItems(uuid, random, 25));
    
    // Generate 6 sample outfits with valid item references
    _outfits.addAll(_generateMockOutfits(uuid, random, 6));
  }

  /// Generates a list of mock clothing items with diverse attributes.
  List<ClothingItem> _generateMockClothingItems(Uuid uuid, Random random, int count) {
    final items = <ClothingItem>[];
    
    // Define color palette
    final colors = [
      'Black', 'White', 'Navy', 'Gray', 'Beige', 'Brown',
      'Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Purple'
    ];
    
    // Define item templates for each category with realistic names
    final templates = {
      ClothingType.tops: [
        'Cotton T-Shirt', 'Silk Blouse', 'Linen Shirt', 'Sweater',
        'Tank Top', 'Polo Shirt', 'Henley', 'Button-Down'
      ],
      ClothingType.bottoms: [
        'Jeans', 'Chinos', 'Dress Pants', 'Shorts',
        'Skirt', 'Leggings', 'Cargo Pants', 'Joggers'
      ],
      ClothingType.outerwear: [
        'Blazer', 'Denim Jacket', 'Trench Coat', 'Puffer Jacket',
        'Cardigan', 'Leather Jacket', 'Windbreaker'
      ],
      ClothingType.shoes: [
        'Sneakers', 'Loafers', 'Boots', 'Sandals',
        'Heels', 'Flats', 'Oxfords', 'Slip-Ons'
      ],
      ClothingType.accessories: [
        'Scarf', 'Belt', 'Hat', 'Sunglasses',
        'Watch', 'Bag', 'Necklace', 'Bracelet'
      ],
    };
    
    // Ensure each category has at least 3 items
    final itemsPerCategory = count ~/ ClothingType.values.length;
    final extraItems = count % ClothingType.values.length;
    
    for (var type in ClothingType.values) {
      final categoryTemplates = templates[type]!;
      final categoryCount = itemsPerCategory + (type.index < extraItems ? 1 : 0);
      
      for (var i = 0; i < categoryCount; i++) {
        final color = colors[random.nextInt(colors.length)];
        final template = categoryTemplates[random.nextInt(categoryTemplates.length)];
        
        // Generate season combinations
        final seasons = _generateSeasons(random);
        
        // Generate price (70% of items have prices)
        final price = random.nextDouble() < 0.7
            ? 20.0 + random.nextDouble() * 280.0 // $20-$300
            : null;
        
        // Generate usage count (0-50 wears)
        final usageCount = random.nextInt(51);
        
        // Generate added date (within last year)
        final daysAgo = random.nextInt(365);
        final addedDate = DateTime.now().subtract(Duration(days: daysAgo));
        
        // Use placeholder image URL (colored container will be used in UI)
        final imageUrl = 'placeholder://${type.name}/$color';
        
        items.add(ClothingItem(
          id: uuid.v4(),
          imageUrl: imageUrl,
          type: type,
          color: color,
          seasons: seasons,
          price: price,
          usageCount: usageCount,
          addedDate: addedDate,
        ));
      }
    }
    
    return items;
  }

  /// Generates a random list of seasons for a clothing item.
  List<Season> _generateSeasons(Random random) {
    final seasonCount = 1 + random.nextInt(3); // 1-3 seasons
    final allSeasons = List<Season>.from(Season.values)..shuffle(random);
    return allSeasons.take(seasonCount).toList();
  }

  /// Generates a list of mock outfits with valid item references.
  List<Outfit> _generateMockOutfits(Uuid uuid, Random random, int count) {
    final outfits = <Outfit>[];
    
    final vibes = ['Casual', 'Work', 'Date Night', 'Athletic', 'Formal'];
    final outfitNames = [
      'Summer Casual', 'Office Ready', 'Weekend Brunch', 'Evening Out',
      'Gym Session', 'Business Meeting', 'Coffee Date', 'Night Out',
      'Relaxed Sunday', 'Power Outfit'
    ];
    
    for (var i = 0; i < count; i++) {
      // Select 3-5 items for the outfit
      final itemCount = 3 + random.nextInt(3);
      final selectedItems = <ClothingItem>[];
      
      // Try to create a balanced outfit with different types
      final availableTypes = List<ClothingType>.from(ClothingType.values)..shuffle(random);
      
      for (var type in availableTypes) {
        if (selectedItems.length >= itemCount) break;
        
        final itemsOfType = _items.where((item) => item.type == type).toList();
        if (itemsOfType.isNotEmpty) {
          selectedItems.add(itemsOfType[random.nextInt(itemsOfType.length)]);
        }
      }
      
      // If we don't have enough items, add random ones
      while (selectedItems.length < itemCount && selectedItems.length < _items.length) {
        final randomItem = _items[random.nextInt(_items.length)];
        if (!selectedItems.contains(randomItem)) {
          selectedItems.add(randomItem);
        }
      }
      
      final itemIds = selectedItems.map((item) => item.id).toList();
      final vibe = vibes[random.nextInt(vibes.length)];
      final name = outfitNames[i % outfitNames.length];
      
      // Some outfits have assigned dates
      final assignedDate = random.nextDouble() < 0.3
          ? DateTime.now().add(Duration(days: random.nextInt(30)))
          : null;
      
      final createdDate = DateTime.now().subtract(Duration(days: random.nextInt(60)));
      
      outfits.add(Outfit(
        id: uuid.v4(),
        name: name,
        itemIds: itemIds,
        assignedDate: assignedDate,
        vibe: vibe,
        createdDate: createdDate,
      ));
    }
    
    return outfits;
  }
}
