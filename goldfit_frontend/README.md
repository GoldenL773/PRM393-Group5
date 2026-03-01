# GoldFit Frontend

A Flutter mobile application for wardrobe management, outfit recommendations, virtual try-on, and analytics.

## Project Structure

```
lib/
├── models/       # Data models (ClothingItem, Outfit, etc.)
├── screens/      # Screen widgets (Home, Wardrobe, TryOn, etc.)
├── widgets/      # Reusable UI components
├── providers/    # State management (Provider/Riverpod)
├── utils/        # Utilities and theme configuration
└── main.dart     # Application entry point
```

## Dependencies

- **provider** (^6.1.2): State management
- **uuid** (^4.5.1): ID generation for data models
- **google_fonts** (^6.2.1): Manrope font family
- **kiri_check** (^1.3.1): Property-based testing

## Theme

The app uses a gold/yellow color scheme inspired by the design references:
- Primary: Bright yellow (#F0F04C)
- Background: Cream (#FDFDF2)
- Font: Manrope (via Google Fonts)

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. Run tests:
   ```bash
   flutter test
   ```

## Requirements

- Flutter SDK 3.x
- Dart SDK 3.10.8+
- Android Studio / Xcode for platform-specific builds
