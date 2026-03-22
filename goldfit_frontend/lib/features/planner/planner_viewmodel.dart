import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Map<DateTime, Map<String, Outfit>> _calendar = {};
  bool _isLoading = false;
  String? _error;

  // Daily notes state
  final Map<DateTime, String> _dailyNotes = {};

  // Getters
  List<Outfit> get outfits => _outfits;
  Map<DateTime, Map<String, Outfit>> get calendar => _calendar;
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
      
      // Load daily notes
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('planner_note_'));
      for (final key in keys) {
        final dateStr = key.substring('planner_note_'.length);
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          _dailyNotes[date] = prefs.getString(key) ?? '';
        }
      }
      
      // Populate calendar map with normalized dates
      for (final outfit in assignments) {
        if (outfit.assignedDate != null && outfit.timeSlot != null) {
          final normalizedDate = _normalizeDate(outfit.assignedDate!);
          _calendar.putIfAbsent(normalizedDate, () => <String, Outfit>{});
          _calendar[normalizedDate]![outfit.timeSlot!] = outfit;
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
  Future<void> assignOutfit(String outfitId, DateTime date, String timeSlot, {String? eventName, String? startTime}) async {
    try {
      final normalizedDate = _normalizeDate(date);
      
      // Assign in repository
      await _outfitRepository.assignToDate(outfitId, normalizedDate, timeSlot, eventName: eventName, startTime: startTime);
      
      // Update local state
      final outfit = _outfits.firstWhere(
        (o) => o.id == outfitId,
        orElse: () => throw Exception('Outfit not found'),
      );
      
      _calendar.putIfAbsent(normalizedDate, () => <String, Outfit>{});
      _calendar[normalizedDate]![timeSlot] = outfit.copyWith(assignedDate: normalizedDate, timeSlot: timeSlot, eventName: eventName, startTime: startTime);
      notifyListeners();
    } catch (e) {
      _setError('Failed to assign outfit: $e');
    }
  }

  /// Assigns a single ClothingItem to the calendar by creating an ephemeral Outfit wrapper.
  Future<void> assignSingleItemToDate(ClothingItem item, DateTime date, String timeSlot, {String? eventName, String? startTime}) async {
    try {
      final outfitId = 'virtual_${item.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      final newOutfit = Outfit(
        id: outfitId,
        name: item.type.name.toUpperCase(),
        itemIds: [item.id],
        createdDate: DateTime.now(),
        modelImagePath: item.cleanedImageUrl ?? item.imageUrl,
        resultImagePath: item.cleanedImageUrl ?? item.imageUrl, // Use as result image too for consistency
      );
      
      // Save it to repo to satisfy foreign keys
      await _outfitRepository.create(newOutfit);
      
      // Keep it in local state
      _outfits.insert(0, newOutfit);
      
      // Assign to the calendar!
      await assignOutfit(outfitId, date, timeSlot, eventName: eventName, startTime: startTime);
    } catch (e) {
      _setError('Failed to assign item: $e');
    }
  }

  /// Removes the outfit assignment from a specific date.
  /// 
  /// Deletes the calendar assignment from the repository and updates the local state.
  /// The date is normalized to midnight for consistent calendar operations.
  /// Updates error state if the operation fails.
  Future<void> unassignOutfit(DateTime date, String timeSlot) async {
    try {
      final normalizedDate = _normalizeDate(date);
      
      // Unassign in repository
      await _outfitRepository.unassignFromDate(normalizedDate, timeSlot);
      
      // Update local state
      _calendar[normalizedDate]?.remove(timeSlot);
      if (_calendar[normalizedDate]?.isEmpty ?? false) {
        _calendar.remove(normalizedDate);
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to unassign outfit: $e');
    }
  }

  /// Gets the outfit assigned to a specific date for a specific time slot.
  /// 
  /// Returns the outfit if one is assigned to the date and slot, null otherwise.
  /// The date is normalized to midnight for consistent calendar lookups.
  Outfit? getOutfitForDateAndTime(DateTime date, String timeSlot) {
    final normalizedDate = _normalizeDate(date);
    return _calendar[normalizedDate]?[timeSlot];
  }

  /// Check if a date has any outfits assigned
  bool hasAnyOutfitForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return _calendar.containsKey(normalizedDate) && _calendar[normalizedDate]!.isNotEmpty;
  }

  /// Clones all outfits from the source date to the target date.
  Future<void> cloneDay(DateTime sourceDate, DateTime targetDate) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final sourceNormalized = _normalizeDate(sourceDate);
      final targetNormalized = _normalizeDate(targetDate);
      
      final sourceOutfits = _calendar[sourceNormalized];
      if (sourceOutfits == null || sourceOutfits.isEmpty) {
        throw Exception('No outfits to clone on the source date.');
      }
      
      for (final entry in sourceOutfits.entries) {
        final timeSlot = entry.key;
        final outfit = entry.value;
        await _outfitRepository.assignToDate(
          outfit.id, 
          targetNormalized, 
          timeSlot, 
          eventName: outfit.eventName, 
          startTime: outfit.startTime
        );
      }
      
      // Reload calendar to reflect new assignments
      final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0);
      await loadCalendar(startOfMonth, endOfMonth);
    } catch (e) {
      _setError('Failed to clone day: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Gets the note for a specific date
  String? getNoteForDate(DateTime date) {
    return _dailyNotes[_normalizeDate(date)];
  }

  /// Saves a note for a specific date
  Future<void> saveNoteForDate(DateTime date, String note) async {
    final normalizedDate = _normalizeDate(date);
    _dailyNotes[normalizedDate] = note;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    if (note.isEmpty) {
      await prefs.remove('planner_note_${normalizedDate.toIso8601String()}');
    } else {
      await prefs.setString('planner_note_${normalizedDate.toIso8601String()}', note);
    }
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
