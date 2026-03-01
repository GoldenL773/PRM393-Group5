import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/app_shell.dart';
import 'screens/item_detail_screen.dart';
import 'screens/styling_screen.dart';
import 'screens/recommendations_screen.dart';
import 'providers/app_state.dart';
import 'providers/mock_data_provider.dart';
import 'utils/theme.dart';
import 'utils/routes.dart';
import 'utils/navigation_manager.dart';

void main() {
  runApp(const GoldFitApp());
}

class GoldFitApp extends StatelessWidget {
  const GoldFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(MockDataProvider()),
        ),
        Provider<NavigationManager>(
          create: (_) => NavigationManager(),
        ),
      ],
      child: MaterialApp(
        title: 'GoldFit',
        theme: GoldFitTheme.lightTheme,
        home: const AppShell(),
        routes: {
          AppRoutes.itemDetail: (context) => const ItemDetailScreen(),
          AppRoutes.styling: (context) => const StylingScreen(),
          AppRoutes.recommendations: (context) => const RecommendationsScreen(),
        },
      ),
    );
  }
}
