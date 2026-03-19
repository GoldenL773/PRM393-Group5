import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GoldFit theme configuration with gold/yellow color scheme
/// Based on design reference in stitch_ai_personal_stylist_suggestions
class GoldFitTheme {
  // Primary colors (from design reference)
  static const Color primary = Color(0xFFF0F04C); // Bright yellow (#f0f04c)
  static const Color backgroundLight = Color(0xFFFDFDF2); // Cream background (#fdfdf2)
  static const Color backgroundDark = Color(0xFFFEFCE8); // Light yellow background (#fefce8)
  static const Color surfaceLight = Color(0xFFFFFFFF); // White cards
  
  // Gold accent colors
  static const Color gold600 = Color(0xFFCA8A04); // Dark gold for text
  static const Color gold700 = Color(0xFFA16207); // Darker gold
  static const Color yellow100 = Color(0xFFFEF9C3); // Light yellow surface
  static const Color yellow200 = Color(0xFFFEF08A); // Yellow borders
  
  // Text colors
  static const Color textDark = Color(0xFF1E293B); // Slate 900
  static const Color textMedium = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400
  
  /// Get the light theme for the application
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.montserratTextTheme(); // Thay đổi thành Montserrat cho thanh thoát hơn
    
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600, // Thanh thoát hơn bold
          color: textDark,
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: gold600,
        unselectedItemColor: textLight,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 4, // Tăng elevation để đổ bóng rõ hơn
        shadowColor: Colors.black.withOpacity(0.08), // Màu đổ bóng nhạt, mềm mại
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Tăng bo góc cho hiện đại
          side: const BorderSide(color: Color(0xFFF8FAFC), width: 1), // Viền siêu mờ
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textDark,
          elevation: 4, // Tăng elevation
          shadowColor: primary.withOpacity(0.4), // Đổ bóng cùng tone vàng
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc to hơn
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Padding rộng hơn
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Bo góc to hơn
          borderSide: const BorderSide(color: yellow200),
        ),
        enabledBorder: OutlineInputBorder( // Thêm enabledBorder để viền mờ khi chưa focus
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Tăng padding
        labelStyle: GoogleFonts.montserrat(
          color: textMedium,
          fontSize: 14,
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: yellow100.withOpacity(0.5), // Giảm màu nền đi một chút
        labelStyle: GoogleFonts.montserrat(
          color: gold700, 
          fontSize: 12,
          fontWeight: FontWeight.w600, // Đổi từ w500 -> w600
        ),
        side: const BorderSide(color: Colors.transparent), // Bỏ viền cho hiện đại hơn
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.montserrat(
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
