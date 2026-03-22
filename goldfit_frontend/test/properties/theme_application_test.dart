import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 4: Theme Application Consistency', () {
    test('Primary color constants are gold/yellow', () {
      // **Validates: Requirements 1.5, 11.4**
      
      // Verify primary yellow color
      expect(GoldFitTheme.primary.value, equals(0xFFF0F04C));
      
      // Verify cream background
      expect(GoldFitTheme.backgroundLight.value, equals(0xFFFDFDF2));
      
      // Verify gold accent colors
      expect(GoldFitTheme.gold600.value, equals(0xFFCA8A04));
      expect(GoldFitTheme.gold700.value, equals(0xFFA16207));
      
      // Verify yellow surface colors
      expect(GoldFitTheme.yellow100.value, equals(0xFFFEF9C3));
      expect(GoldFitTheme.yellow200.value, equals(0xFFFEF08A));
    });
    
    testWidgets('Theme applies primary yellow to main UI elements', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: Container(),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      
      // Primary color should be yellow
      expect(theme.primaryColor, equals(GoldFitTheme.primary));
      
      // Scaffold background should be cream
      expect(theme.scaffoldBackgroundColor, equals(GoldFitTheme.backgroundLight));
      
      // Color scheme primary should be yellow
      expect(theme.colorScheme.primary, equals(GoldFitTheme.primary));
      expect(theme.colorScheme.secondary, equals(GoldFitTheme.gold600));
    });
    
    testWidgets('Button theme applies primary yellow background', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Test'),
            ),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(ElevatedButton)));
      final buttonStyle = theme.elevatedButtonTheme.style;
      
      // Button background should be primary yellow
      final bgColor = buttonStyle?.backgroundColor?.resolve({});
      expect(bgColor, equals(GoldFitTheme.primary));
      
      // Button text should be dark for contrast
      final fgColor = buttonStyle?.foregroundColor?.resolve({});
      expect(fgColor, equals(GoldFitTheme.textDark));
      
      // Button should have no elevation (flat design)
      final elevation = buttonStyle?.elevation?.resolve({});
      expect(elevation, equals(0));
      
      // Button should have rounded corners
      final shape = buttonStyle?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius, equals(BorderRadius.circular(12)));
    });
    
    testWidgets('Navigation bar theme applies gold accent to selected items', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(BottomNavigationBar)));
      final navTheme = theme.bottomNavigationBarTheme;
      
      // Selected item should use gold accent
      expect(navTheme.selectedItemColor, equals(GoldFitTheme.gold600));
      
      // Unselected items should use light gray
      expect(navTheme.unselectedItemColor, equals(GoldFitTheme.textLight));
      
      // Background should be white
      expect(navTheme.backgroundColor, equals(Colors.white));
      
      // Should use fixed type for consistent layout
      expect(navTheme.type, equals(BottomNavigationBarType.fixed));
    });
    
    testWidgets('AppBar theme applies light background with dark text', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: Container(),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(AppBar)));
      final appBarTheme = theme.appBarTheme;
      
      // AppBar should use light background
      expect(appBarTheme.backgroundColor, equals(GoldFitTheme.backgroundLight));
      
      // AppBar text should use dark text for contrast
      expect(appBarTheme.foregroundColor, equals(GoldFitTheme.textDark));
      
      // AppBar should have no elevation (flat design)
      expect(appBarTheme.elevation, equals(0));
      
      // AppBar title should be centered
      expect(appBarTheme.centerTitle, isTrue);
    });
    
    testWidgets('Input decoration theme applies yellow focus state', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(labelText: 'Test'),
            ),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(TextField)));
      final inputTheme = theme.inputDecorationTheme;
      
      // Focused border should use primary yellow
      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder?;
      expect(focusedBorder?.borderSide.color, equals(GoldFitTheme.primary));
      expect(focusedBorder?.borderSide.width, equals(2));
      
      // Normal border should use yellow accent
      final normalBorder = inputTheme.border as OutlineInputBorder?;
      expect(normalBorder?.borderSide.color, equals(GoldFitTheme.yellow200));
      
      // Fill color should be white
      expect(inputTheme.fillColor, equals(GoldFitTheme.surfaceLight));
      expect(inputTheme.filled, isTrue);
    });
    
    testWidgets('Card theme applies white surface with subtle border', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: Card(child: Container()),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(Card)));
      final cardTheme = theme.cardTheme;
      
      // Card should use white surface
      expect(cardTheme.color, equals(GoldFitTheme.surfaceLight));
      
      // Card should have no elevation (flat design)
      expect(cardTheme.elevation, equals(0));
      
      // Card should have rounded corners and subtle border
      final shape = cardTheme.shape as RoundedRectangleBorder?;
      expect(shape?.borderRadius, equals(BorderRadius.circular(16)));
      expect(shape?.side.color, equals(const Color(0xFFF1F5F9)));
      expect(shape?.side.width, equals(1));
    });
    
    testWidgets('Chip theme applies yellow background and border', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: Chip(label: const Text('Test')),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(Chip)));
      final chipTheme = theme.chipTheme;
      
      // Chip should use light yellow background
      expect(chipTheme.backgroundColor, equals(GoldFitTheme.yellow100));
      
      // Chip should have yellow border
      expect(chipTheme.side?.color, equals(GoldFitTheme.yellow200));
      
      // Chip should have pill shape (high border radius)
      final shape = chipTheme.shape as RoundedRectangleBorder?;
      expect(shape?.borderRadius, equals(BorderRadius.circular(999)));
    });
    
    testWidgets('All primary UI elements consistently use gold/yellow theme', (tester) async {
      // **Validates: Requirements 1.5, 11.4**
      // This test verifies that all primary UI elements use colors from the gold/yellow palette
      
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldFitTheme.lightTheme,
          home: Scaffold(
            body: Container(),
          ),
        ),
      );
      
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      
      // Collect all gold/yellow colors used in the theme
      final goldYellowColors = {
        GoldFitTheme.primary,
        GoldFitTheme.backgroundLight,
        GoldFitTheme.backgroundDark,
        GoldFitTheme.gold600,
        GoldFitTheme.gold700,
        GoldFitTheme.yellow100,
        GoldFitTheme.yellow200,
      };
      
      // Verify primary elements use gold/yellow colors
      expect(goldYellowColors.contains(theme.primaryColor), isTrue,
          reason: 'Primary color should be from gold/yellow palette');
      
      expect(goldYellowColors.contains(theme.scaffoldBackgroundColor), isTrue,
          reason: 'Scaffold background should be from gold/yellow palette');
      
      expect(goldYellowColors.contains(theme.colorScheme.primary), isTrue,
          reason: 'Color scheme primary should be from gold/yellow palette');
      
      expect(goldYellowColors.contains(theme.colorScheme.secondary), isTrue,
          reason: 'Color scheme secondary should be from gold/yellow palette');
      
      expect(goldYellowColors.contains(theme.bottomNavigationBarTheme.selectedItemColor), isTrue,
          reason: 'Selected navigation item should be from gold/yellow palette');
      
      expect(goldYellowColors.contains(theme.chipTheme.backgroundColor), isTrue,
          reason: 'Chip background should be from gold/yellow palette');
      
      final buttonBg = theme.elevatedButtonTheme.style?.backgroundColor?.resolve({});
      expect(goldYellowColors.contains(buttonBg), isTrue,
          reason: 'Button background should be from gold/yellow palette');
      
      final focusedBorder = theme.inputDecorationTheme.focusedBorder as OutlineInputBorder?;
      expect(goldYellowColors.contains(focusedBorder?.borderSide.color), isTrue,
          reason: 'Input focused border should be from gold/yellow palette');
    });
  });
}
