import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';

/// ViewModel for the Planner/Calendar screen that manages UI state and business logic.
/// 
/// Extends ChangeNotifier to provide reactive state updates to the UI.
/// Handles loading outfits, calendar assignments, and outfit scheduling operations.
/// 
/// **Validates Requirements:** 14.1, 14.2, 14.3, 14.4, 14.5
class PlannerViewModel extends ChangeNotifier {
  final OutfitRepository _outfitRepository;

  // State properties
  List<Outfit> _outfits = [];
  final Map<DateTime, Outfit> _calendar = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Outfit> get outfits => _outfits;
  Map<DateTime, Outfit> get calendar => _calendar;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlannerViewModel(this._outfitRepository);

  /// Loads all outfits from the repository.
  /// 
  /// Sets loading state, clears errors, and fetches outfits.
  /// Updates error state if the operation fails.
  Future<void> loadOutfits() async {
    _setLoading(true);
    _setError(null);

    try {
      _outfits = await _outfitRepository.getAll();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load outfits: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads calendar assignments for a specific date range.
  /// 
  /// Fetches outfit assignments from the repository and populates the calendar map.
  /// The calendar map uses normalized dates (midnight) as keys.
  /// Updates error state if the operation fails.
  Future<void> loadCalendar(DateTime start, DateTime end) async {
    _setLoading(true);
    _setError(null);

    try {
      final assignments = await _outfitRepository.getByDateRange(start, end);
      
      // Clear existing calendar data
      _calendar.clear();
      
      // Populate calendar map with normalized dates
      for (final outfit in assignments) {
        if (outfit.assignedDate != null) {
          final normalizedDate = _normalizeDate(outfit.assignedDate!);
          _calendar[normalizedDate] = outfit;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load calendar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Assigns an outfit to a specific date in the calendar.
  /// 
  /// Creates a calendar assignment in the repository and updates the local state.
  /// The date is normalized to midnight for consistent calendar operations.
  /// Updates error state if the operation fails (e.g., date already has an outfit).
  Future<void> assignOutfit(String outfitId, DateTime date) async {
    try {
      final normalizedDate = _normalizeDate(date);
      
      // Assign in repository
      await _outfitRepository.assignToDate(outfitId, normalizedDate);
      
      // Update local state
      final outfit = _outfits.firstWhere(
        (o) => o.id == outfitId,
        orElse: () => throw Exception('Outfit not found'),
      );
      
      _calendar[normalizedDate] = outfit.copyWith(assignedDate: normalizedDate);
      notifyListeners();
    } catch (e) {
      _setError('Failed to assign outfit: $e');
    }
  }

  /// Removes the outfit assignment from a specific date.
  /// 
  /// Deletes the calendar assignment from the repository and updates the local state.
  /// The date is normalized to midnight for consistent calendar operations.
  /// Updates error state if the operation fails.
  Future<void> unassignOutfit(DateTime date) async {
    try {
      final normalizedDate = _normalizeDate(date);
      
      // Unassign in repository
      await _outfitRepository.unassignFromDate(normalizedDate);
      
      // Update local state
      _calendar.remove(normalizedDate);
      notifyListeners();
    } catch (e) {
      _setError('Failed to unassign outfit: $e');
    }
  }

  /// Gets the outfit assigned to a specific date.
  /// 
  /// Returns the outfit if one is assigned to the date, null otherwise.
  /// The date is normalized to midnight for consistent calendar lookups.
  Outfit? getOutfitForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return _calendar[normalizedDate];
  }

  /// Normalizes a date to midnight (00:00:00) for consistent calendar operations.
  /// 
  /// This ensures that dates are compared correctly regardless of time components.
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Sets the loading state and notifies listeners.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets the error state and notifies listeners.
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
