import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/models/wardrobe_analytics.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';

/// ViewModel for the Insights/Analytics screen that manages UI state and business logic.
/// 
/// Extends ChangeNotifier to provide reactive state updates to the UI.
/// Handles loading analytics data and managing error states.
/// 
/// **Validates Requirements:** 14.1, 14.2, 14.3, 14.4, 14.5
class InsightsViewModel extends ChangeNotifier {
  final AnalyticsRepository _analyticsRepository;

  // State properties
  WardrobeAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  // Getters
  WardrobeAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  InsightsViewModel(this._analyticsRepository);

  /// Loads analytics data from the repository.
  /// 
  /// Sets loading state, clears errors, and fetches comprehensive analytics
  /// including total items, total value, most worn items, and least worn items.
  /// Updates error state if the operation fails.
  Future<void> loadAnalytics() async {
    _setLoading(true);
    _setError(null);

    try {
      _analytics = await _analyticsRepository.getAnalytics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load analytics: $e');
    } finally {
      _setLoading(false);
    }
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
