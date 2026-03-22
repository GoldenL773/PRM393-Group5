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
import 'package:goldfit_frontend/features/home/settings_screen.dart';

import 'package:goldfit_frontend/features/debug/debug_log_viewer_screen.dart';

// Authentication imports
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';
import 'package:goldfit_frontend/features/auth/auth_screen.dart';
import 'package:goldfit_frontend/shared/repositories/auth_repository.dart';
import 'package:goldfit_frontend/shared/repositories/auth_repository_impl.dart';

void main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('DEBUG: Flutter bindings initialized');

  try {
    // Load environment variables
    debugPrint('DEBUG: Loading .env...');
    await dotenv.load(fileName: ".env");
    debugPrint('DEBUG: .env loaded successfully');

  // Initialize database factory for the current platform
  await initializeDatabaseFactory();

  // Initialize database
  debugPrint('DEBUG: Initializing DatabaseManager...');
  final dbManager = DatabaseManager();
  debugPrint('DEBUG: Getting database instance (may trigger migrations)...');
  await dbManager.database; // Ensure database is initialized
  debugPrint('DEBUG: Database initialized successfully');

  // Create repository instances
  final clothingRepo = ClothingRepositoryImpl(dbManager);
  final outfitRepo = OutfitRepositoryImpl(dbManager);
  final analyticsRepo = AnalyticsRepositoryImpl(dbManager);
  final collectionRepo = CollectionRepositoryImpl(dbManager);

    // Create auth repository with database
    final authRepo = AuthRepositoryImpl(dbManager);

    // Initialize and run data migration if needed
    debugPrint('DEBUG: Starting data migration check...');
    final mockDataProvider = MockDataProvider();
    final migrationService = DataMigrationService(
      dbManager,
      clothingRepo,
      outfitRepo,
    );
    await migrationService.migrateIfNeeded(mockDataProvider);
    debugPrint('DEBUG: Data migration check/execution finished');

    debugPrint('DEBUG: Calling runApp...');
    runApp(
      GoldFitApp(
        authRepository: authRepo,
        clothingRepository: clothingRepo,
        outfitRepository: outfitRepo,
        analyticsRepository: analyticsRepo,
        collectionRepository: collectionRepo,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('DEBUG: FATAL ERROR during startup: $e');
    debugPrint('DEBUG: StackTrace: $stackTrace');
    
    // Fallback to show error in app if possible, or at least keep log visible
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to start GoldFit:\n$e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
  }
}

class GoldFitApp extends StatelessWidget {
  final AuthRepository authRepository;
  final ClothingRepository clothingRepository;
  final OutfitRepository outfitRepository;
  final AnalyticsRepository analyticsRepository;
  final CollectionRepository collectionRepository;

  const GoldFitApp({
    super.key,
    required this.authRepository,
    required this.clothingRepository,
    required this.outfitRepository,
    required this.analyticsRepository,
    required this.collectionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Repository and ViewModel
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
        ),

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
        home: Consumer<AuthViewModel>(
          builder: (context, authVm, _) {
            // Show loading indicator while checking auth state
            if (authVm.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC5A028),
                  ),
                ),
              );
            }

            // If authenticated, show main app, otherwise show auth screen
            if (authVm.isAuthenticated) {
              return const AppShell();
            }

            return const AuthScreen();
          },
        ),
        routes: {
          AppRoutes.itemDetail: (context) => const ItemDetailScreen(),
          AppRoutes.editItem: (context) => const EditClothingScreen(),
          AppRoutes.tryOn: (context) => const TryOnScreen(),
          AppRoutes.styling: (context) => const StylingScreen(),
          AppRoutes.recommendations: (context) => const RecommendationsScreen(),
          AppRoutes.favorites: (context) => const FavoritesScreen(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.debugLogs: (context) => const DebugLogViewerScreen(),
          AppRoutes.auth: (context) => const AuthScreen(),
          AppRoutes.collectionEditor: (context) =>
              const CollectionEditorScreen(),
        },
      ),
    );
  }
}