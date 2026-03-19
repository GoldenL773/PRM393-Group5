import 'package:flutter/material.dart';
import 'package:goldfit_frontend/shared/utils/routes.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';

/// Navigation manager for handling screen transitions and routing
/// Provides helper methods for common navigation patterns
class NavigationManager {
  /// Navigate to item detail screen with item ID
  void navigateToItemDetail(BuildContext context, String itemId) {
    Navigator.pushNamed(
      context,
      AppRoutes.itemDetail,
      arguments: {'itemId': itemId},
    );
  }

  /// Navigate to try-on screen with a preloaded outfit
  void navigateToTryOnWithOutfit(BuildContext context, Outfit outfit) {
    Navigator.pushNamed(
      context,
      AppRoutes.tryOn,
      arguments: {'outfit': outfit},
    );
  }

  /// Navigate to styling input screen
  void navigateToStyling(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.styling);
  }

  /// Navigate to recommendations screen with vibe or event description
  void navigateToRecommendations(
    BuildContext context, {
    String? vibe,
    String? eventDescription,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.recommendations,
      arguments: {
        'vibe': vibe,
        'eventDescription': eventDescription,
      },
    );
  }

  /// Navigate back to previous screen
  void navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  /// Navigate to a specific main tab by route name
  /// This is used for deep linking or programmatic navigation to main screens
  void navigateToMainScreen(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
    );
  }
}
