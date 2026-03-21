import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GoldFit theme configuration with gold/yellow color scheme
/// Based on design reference in stitch_ai_personal_stylist_suggestions
class GoldFitTheme {
  // Primary colors (from design reference)
  static const Color primary = Color(0xFFC5A028); // Radiant gold (#C5A028)
  static const Color backgroundLight = Color(0xFFFCFBF7); // Off-white background (#FCFBF7)
  static const Color backgroundDark = Color(0xFFF9F7F0); // Subtle darker cream background
  static const Color surfaceLight = Color(0xFFFFFFFF); // White cards
  
  // Gold accent colors
  static const Color gold600 = Color(0xFF745B00); // Deep gold for high-contrast text
  static const Color gold700 = Color(0xFF564300); // Darkest gold for labels
  static const Color yellow100 = Color(0xFFFFE08B); // Soft yellow surface/chips
  static const Color yellow200 = Color(0xFFD0C5AF); // Neutral golden borders (outline variant)
  
  // Text colors
  static const Color textDark = Color(0xFF2C2C2C); // Grounding Secondary
  static const Color textMedium = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400
  static const Color tertiary = Color(0xFFE6E1D6); // Soft beige secondary accent
  
  /// Get the light theme for the application
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(); // Body & Labels use Inter
    
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.5,
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: gold600,
        unselectedItemColor: textLight,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0, // No elevation as per "Digital Curator" system
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), // High roundedness
          side: BorderSide(color: yellow200.withOpacity(0.15), width: 1), // Ghost border
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)), // Pill-shaped
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF4F4F0), // surface-container-low
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.2), width: 1), // Ghost border on focus
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.inter(
          color: textMedium,
          fontSize: 14,
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: yellow100.withOpacity(0.3),
        labelStyle: GoogleFonts.inter(
          color: gold700, 
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99), // Pill-shaped
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: gold600,
        surface: surfaceLight,
        error: Colors.red,
        onPrimary: textDark,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
    );
  }
}
