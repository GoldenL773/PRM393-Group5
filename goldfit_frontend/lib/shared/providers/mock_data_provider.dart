import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/models/filter_state.dart';
import 'package:goldfit_frontend/shared/models/weather_data.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';

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
      temperature: 28.0,
      condition: 'Sunny',
      location: 'Quận 1, TP. HCM',
      timestamp: DateTime.now(),
      isDay: DateTime.now().hour > 6 && DateTime.now().hour < 18,
      season: Season.summer,
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
    
    // Map clothing types to asset folders and available images
    final assetMapping = {
      ClothingType.tops: {
        'folder': 'shirt',
        'images': [
          '00143901-a14c-4600-960f-7747b4a3a8cd.jpg',
          '0e7453e0-023c-4c34-b837-e6349846b112.jpg',
          '118fb0e8-2783-4086-b81a-d2a332fbb4f2.jpg',
          '1d2e0956-07d7-41d8-9286-ea98d1d32dbd.jpg',
          '235230d6-8a23-4981-bc43-5e62c0570f44.jpg',
          '29f8cf36-3ae6-4558-9f42-82f330c15b3d.jpg',
          '309ead9a-2672-40b7-8a09-ab5fc6abccc0.jpg',
          '31315e30-2742-4f7f-8168-10a0645d2163.jpg',
        ],
      },
      ClothingType.bottoms: {
        'folder': 'pants',
        'images': [
          '012d1ca9-baaf-4b01-8b60-955f3408b1b7.jpg',
          '0257eb81-f3d3-4704-8299-8b6ab20f1ed4.jpg',
          '081b5ec1-13a6-43c8-991f-9ad2020f646a.jpg',
          '0d0bb91d-01d7-45df-827d-da96bbc44b15.jpg',
          '17bebe65-17cc-42b3-885f-4e6c64a16f26.jpg',
          '19ff0603-c52b-4d27-a9b9-cfd9da5e9f35.jpg',
          '1f3fe0f5-4724-43f8-bfce-6e22d1f1f5ba.jpg',
          '24eb8ba7-065a-4493-8fa6-b3afa89751f6.jpg',
        ],
      },
      ClothingType.outerwear: {
        'folder': 'outwear',
        'images': [
          '0ad8629f-2e9f-4591-a661-7489d6d49737.jpg',
          '0c7412e7-81eb-40b7-be64-ce9782103529.jpg',
          '161e35df-93d4-4b30-817e-de03c8c1d55a.jpg',
          '2160a577-406a-4812-ada2-2a3cb30c2ba8.jpg',
          '2c1c3c2a-5b22-4133-9509-1877d6a106a0.jpg',
          '2ea87992-6eb5-46a2-9ac6-e4ac727179aa.jpg',
          '3108045a-9975-4ad8-b5ed-e0a065e5d397.jpg',
          '311ee106-2f12-4b1d-83fb-b3e597607cca.jpg',
        ],
      },
      ClothingType.shoes: {
        'folder': 'shoes',
        'images': [
          '24535295-abe3-4613-91f6-a7fe87954662.jpg',
          '253dc2b9-f49e-4f55-9917-c9005c29bbd9.jpg',
          '32662cf1-4440-459c-b55c-0ba39b71f768.jpg',
          '41302a0b-5faf-48a9-9b40-33885d28a7a6.jpg',
          '454fd50e-89eb-412b-b16c-17f1730ed9b5.jpg',
          '4eba049d-e813-4af9-913a-53b6877cdda2.jpg',
          '5bb088ac-ea91-419b-851e-1b04b7ce57db.jpg',
          '5e577f40-dd22-4b40-9827-ce6cae5ac3fd.jpg',
        ],
      },
      ClothingType.accessories: {
        'folder': 'hat',
        'images': [
          '014b2a1b-c5a0-469b-b115-bc02b2001db5.jpg',
          '4f04a31f-6589-4fe2-8a95-a42f6a164bd9.jpg',
          '50cf0bbc-5a25-4df9-94fe-3323d2b61bff.jpg',
          '7b4ca4a5-fd04-4a96-9f40-1a982ff6cb8b.jpg',
          '7bfaa9c2-d467-4627-9ff4-233075aa65d4.jpg',
          '7c28df10-5bfc-4deb-b57f-6c292f07b98b.jpg',
          '86a3f65f-8c08-48b6-a783-0e38ffa006ef.jpg',
          '8f809fea-1f7d-4695-be36-a061bd77c170.jpg',
        ],
      },
    };
    
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
      final assetInfo = assetMapping[type];
      
      for (var i = 0; i < categoryCount; i++) {
        final color = colors[random.nextInt(colors.length)];
        
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
        
        // Use asset image if available, otherwise use placeholder
        String imageUrl;
        if (assetInfo != null && assetInfo['images'] is List && (assetInfo['images'] as List).isNotEmpty) {
          final images = assetInfo['images'] as List<String>;
          final imageName = images[random.nextInt(images.length)];
          imageUrl = 'assets/${assetInfo['folder']}/$imageName';
        } else {
          // Fallback to placeholder
          imageUrl = 'placeholder://${type.name}/$color';
        }
        
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
        isFavorite: random.nextBool(), // Randomly mark some as favorites
      ));
    }
    
    return outfits;
  }
}
