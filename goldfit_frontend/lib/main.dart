import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:goldfit_frontend/core/routing/app_shell.dart';
import 'package:goldfit_frontend/features/wardrobe/item_detail_screen.dart';
import 'package:goldfit_frontend/features/wardrobe/edit_clothing_screen.dart';
import 'package:goldfit_frontend/features/wardrobe/collection_editor_screen.dart';
import 'package:goldfit_frontend/features/try_on/try_on_screen.dart';
import 'package:goldfit_frontend/features/home/styling_screen.dart';
import 'package:goldfit_frontend/features/home/recommendations_screen.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/utils/routes.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_factory_initializer.dart';
import 'package:goldfit_frontend/core/database/data_migration_service.dart';

import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository.dart';
import 'package:goldfit_frontend/shared/repositories/analytics_repository_impl.dart';
import 'package:goldfit_frontend/shared/repositories/collection_repository.dart';
import 'package:goldfit_frontend/shared/repositories/collection_repository_impl.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/features/wardrobe/collection_viewmodel.dart';
import 'package:goldfit_frontend/features/planner/planner_viewmodel.dart';
import 'package:goldfit_frontend/features/insights/insights_viewmodel.dart';
import 'package:goldfit_frontend/features/home/home_viewmodel.dart';
import 'package:goldfit_frontend/features/home/recommendations_viewmodel.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';
import 'package:goldfit_frontend/features/favorites/favorites_screen.dart';

import 'package:goldfit_frontend/features/debug/debug_log_viewer_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize database factory for the current platform
  await initializeDatabaseFactory();

  // Initialize database
  final dbManager = DatabaseManager();
  await dbManager.database; // Ensure database is initialized

  // Create repository instances
  final clothingRepo = ClothingRepositoryImpl(dbManager);
  final outfitRepo = OutfitRepositoryImpl(dbManager);
  final analyticsRepo = AnalyticsRepositoryImpl(dbManager);
  final collectionRepo = CollectionRepositoryImpl(dbManager);

  // Initialize and run data migration if needed
  // migrateIfNeeded only runs once (checks a flag in DB). User data is preserved.
  final mockDataProvider = MockDataProvider();
  final migrationService = DataMigrationService(
    dbManager,
    clothingRepo,
    outfitRepo,
  );
  await migrationService.migrateIfNeeded(mockDataProvider);

  runApp(
    GoldFitApp(
      clothingRepository: clothingRepo,
      outfitRepository: outfitRepo,
      analyticsRepository: analyticsRepo,
      collectionRepository: collectionRepo,
    ),
  );
}

class GoldFitApp extends StatelessWidget {
  final ClothingRepository clothingRepository;
  final OutfitRepository outfitRepository;
  final AnalyticsRepository analyticsRepository;
  final CollectionRepository collectionRepository;

  const GoldFitApp({
    super.key,
    required this.clothingRepository,
    required this.outfitRepository,
    required this.analyticsRepository,
    required this.collectionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<ClothingRepository>.value(value: clothingRepository),
        Provider<OutfitRepository>.value(value: outfitRepository),
        Provider<AnalyticsRepository>.value(value: analyticsRepository),
        Provider<CollectionRepository>.value(value: collectionRepository),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => WardrobeViewModel(clothingRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CollectionViewModel(collectionRepository)..loadCollections(),
        ),
        ChangeNotifierProvider(
          create: (_) => PlannerViewModel(outfitRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => InsightsViewModel(analyticsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(outfitRepository, clothingRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              RecommendationsViewModel(outfitRepository, clothingRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FavoritesViewModel(outfitRepository, clothingRepository),
        ),

        // Legacy providers (to be migrated)
        ChangeNotifierProvider(
          create: (_) => AppState(
            MockDataProvider(),
            clothingRepository: clothingRepository,
            outfitRepository: outfitRepository,
          ),
        ),
        Provider<NavigationManager>(create: (_) => NavigationManager()),
      ],
      child: MaterialApp(
        title: 'GoldFit',
        theme: GoldFitTheme.lightTheme,
        home: const AppShell(),
        routes: {
          AppRoutes.itemDetail: (context) => const ItemDetailScreen(),
          AppRoutes.editItem: (context) => const EditClothingScreen(),
          AppRoutes.tryOn: (context) => const TryOnScreen(),
          AppRoutes.styling: (context) => const StylingScreen(),
          AppRoutes.recommendations: (context) => const RecommendationsScreen(),
          AppRoutes.favorites: (context) => const FavoritesScreen(),
          AppRoutes.debugLogs: (context) => const DebugLogViewerScreen(),
          AppRoutes.collectionEditor: (context) =>
              const CollectionEditorScreen(),
        },
      ),
    );
  }
}
