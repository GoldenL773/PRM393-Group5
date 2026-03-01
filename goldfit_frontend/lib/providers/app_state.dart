import 'package:flutter/foundation.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/filter_state.dart';
import '../models/weather_data.dart';
import '../models/wardrobe_analytics.dart';
import 'mock_data_provider.dart';

/// Enum representing the try-on mode.
enum TryOnMode {
  quick,
  realistic,
}

/// Enum representing the calendar view mode.
enum CalendarView {
  week,
  month,
}

/// Main application state manager that extends ChangeNotifier for reactive updates.
/// 
/// This class serves as the single source of truth for all application state,
/// managing wardrobe items, filters, try-on state, planner state, and more.
/// It uses the MockDataProvider as its data source and notifies listeners
/// whenever state changes occur.
/// 
/// Requirements: 13.1, 13.5
class AppState extends ChangeNotifier {
  final MockDataProvider _dataProvider;

  // ============================================================================
  // Wardrobe State
  // ============================================================================
  
  /// Current filter state for wardrobe browsing
  FilterState _filterState = FilterState.empty();
  
  /// Currently selected category (null means "All")
  ClothingType? _selectedCategory;

  // ============================================================================
  // Try-On State
  // ============================================================================
  
  /// Current try-on mode (quick or realistic)
  TryOnMode _tryOnMode = TryOnMode.quick;
  
  /// List of item IDs selected for try-on
  final List<String> _selectedItemIds = [];

  // ============================================================================
  // Planner State
  // ============================================================================
  
  /// Current calendar view mode
  CalendarView _calendarView = CalendarView.month;
  
  /// Currently selected date in the planner
  DateTime _selectedDate = DateTime.now();

  // ============================================================================
  // Constructor
  // ============================================================================

  AppState(this._dataProvider);

  // ============================================================================
  // Wardrobe Getters
  // ============================================================================

  /// Returns all wardrobe items from the data provider.
  List<ClothingItem> get allItems => _dataProvider.getAllItems();

  /// Returns filtered items based on current category and filter state.
  /// 
  /// This getter applies both category filtering (if a category is selected)
  /// and attribute filtering (colors and seasons) to return the appropriate
  /// subset of wardrobe items.
  List<ClothingItem> get filteredItems {
    List<ClothingItem> items;
    
    // First apply category filter
    if (_selectedCategory != null) {
      items = _dataProvider.getItemsByCategory(_selectedCategory!);
    } else {
      items = _dataProvider.getAllItems();
    }
    
    // Then apply attribute filters
    if (!_filterState.isEmpty) {
      items = items.where((item) => _filterState.matches(item)).toList();
    }
    
    return items;
  }

  /// Returns the current filter state.
  FilterState get filterState => _filterState;

  /// Returns the currently selected category (null means "All").
  ClothingType? get selectedCategory => _selectedCategory;

  // ============================================================================
  // Try-On Getters
  // ============================================================================

  /// Returns the current try-on mode.
  TryOnMode get tryOnMode => _tryOnMode;

  /// Returns the list of selected item IDs for try-on.
  List<String> get selectedItemIds => List.unmodifiable(_selectedItemIds);

  /// Returns the actual ClothingItem objects for selected try-on items.
  List<ClothingItem> get selectedTryOnItems {
    return _selectedItemIds
        .map((id) => _dataProvider.getItemById(id))
        .where((item) => item != null)
        .cast<ClothingItem>()
        .toList();
  }

  // ============================================================================
  // Planner Getters
  // ============================================================================

  /// Returns the current calendar view mode.
  CalendarView get calendarView => _calendarView;

  /// Returns the currently selected date.
  DateTime get selectedDate => _selectedDate;

  // ============================================================================
  // Data Provider Access
  // ============================================================================

  /// Returns the mock data provider for direct access when needed.
  MockDataProvider get dataProvider => _dataProvider;

  /// Returns current weather data.
  WeatherData get currentWeather => _dataProvider.getCurrentWeather();

  /// Returns weather-based outfit recommendations.
  List<Outfit> get weatherRecommendations => 
      _dataProvider.getWeatherBasedRecommendations();

  /// Returns wardrobe analytics.
  WardrobeAnalytics get analytics => _dataProvider.getAnalytics();

  /// Returns all saved outfits.
  List<Outfit> get allOutfits => _dataProvider.getAllOutfits();

  // ============================================================================
  // Wardrobe State Methods
  // ============================================================================

  /// Applies the given filter state to the wardrobe.
  /// 
  /// This updates the internal filter state and notifies listeners
  /// so that the UI can update to show only matching items.
  void applyFilters(FilterState filters) {
    _filterState = filters;
    notifyListeners();
  }

  /// Selects a category to filter the wardrobe.
  /// 
  /// Pass null to select "All" categories.
  void selectCategory(ClothingType? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Updates an existing clothing item.
  /// 
  /// This is typically used after editing item tags in the detail screen.
  void updateItem(ClothingItem item) {
    _dataProvider.updateItem(item);
    notifyListeners();
  }

  /// Adds a new clothing item to the wardrobe.
  void addItem(ClothingItem item) {
    _dataProvider.addItem(item);
    notifyListeners();
  }

  /// Deletes a clothing item by its ID.
  void deleteItem(String id) {
    _dataProvider.deleteItem(id);
    notifyListeners();
  }

  /// Clears all active filters.
  void clearFilters() {
    _filterState = FilterState.empty();
    notifyListeners();
  }

  // ============================================================================
  // Try-On State Methods
  // ============================================================================

  /// Toggles between quick and realistic try-on modes.
  void toggleTryOnMode() {
    _tryOnMode = _tryOnMode == TryOnMode.quick 
        ? TryOnMode.realistic 
        : TryOnMode.quick;
    notifyListeners();
  }

  /// Sets the try-on mode explicitly.
  void setTryOnMode(TryOnMode mode) {
    _tryOnMode = mode;
    notifyListeners();
  }

  /// Selects an item for try-on by adding its ID to the selection.
  /// 
  /// If the item is already selected, this has no effect.
  void selectItemForTryOn(String itemId) {
    if (!_selectedItemIds.contains(itemId)) {
      _selectedItemIds.add(itemId);
      notifyListeners();
    }
  }

  /// Removes an item from the try-on selection.
  void deselectItemForTryOn(String itemId) {
    _selectedItemIds.remove(itemId);
    notifyListeners();
  }

  /// Clears all selected items from try-on.
  void clearTryOnSelection() {
    _selectedItemIds.clear();
    notifyListeners();
  }

  /// Loads an outfit into the try-on screen.
  /// 
  /// This replaces the current selection with the items from the outfit.
  void loadOutfitForTryOn(Outfit outfit) {
    _selectedItemIds.clear();
    _selectedItemIds.addAll(outfit.itemIds);
    notifyListeners();
  }

  // ============================================================================
  // Planner State Methods
  // ============================================================================

  /// Toggles between week and month calendar views.
  void toggleCalendarView() {
    _calendarView = _calendarView == CalendarView.week 
        ? CalendarView.month 
        : CalendarView.week;
    notifyListeners();
  }

  /// Sets the calendar view explicitly.
  void setCalendarView(CalendarView view) {
    _calendarView = view;
    notifyListeners();
  }

  /// Sets the selected date in the planner.
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Assigns an outfit to a specific date.
  void assignOutfitToDate(String outfitId, DateTime date) {
    _dataProvider.assignOutfitToDate(outfitId, date);
    notifyListeners();
  }

  /// Removes outfit assignment from a specific date.
  void unassignOutfitFromDate(DateTime date) {
    _dataProvider.unassignOutfitFromDate(date);
    notifyListeners();
  }

  /// Returns the outfit assigned to a specific date, or null if none.
  Outfit? getOutfitForDate(DateTime date) {
    final outfits = _dataProvider.getOutfitsByDate(date);
    return outfits.isNotEmpty ? outfits.first : null;
  }

  // ============================================================================
  // Outfit Management Methods
  // ============================================================================

  /// Saves a new outfit or updates an existing one.
  void saveOutfit(Outfit outfit) {
    _dataProvider.saveOutfit(outfit);
    notifyListeners();
  }

  /// Deletes an outfit by its ID.
  void deleteOutfit(String id) {
    _dataProvider.deleteOutfit(id);
    notifyListeners();
  }

  /// Returns outfit recommendations based on a vibe/occasion.
  List<Outfit> getVibeBasedRecommendations(String vibe) {
    return _dataProvider.getVibeBasedRecommendations(vibe);
  }
}
