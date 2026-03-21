import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';
import 'package:goldfit_frontend/shared/services/pose_detection_service.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';
import 'package:uuid/uuid.dart';

/// Try-On screen for virtual try-on with Quick Try and Realistic Fitting modes
/// Displays base photo, mode toggle, clothing selector, and save outfit button
/// 
/// Requirements: 8.1, 8.2, 8.3
class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  bool _isProcessingRealistic = false;
  bool _hasRealisticResult = false;
  bool _isPickingImage = false;
  String? _basePhotoPath;
  PoseAlignmentResult? _poseResult;
  final GeminiService _geminiService = GeminiService();
  final PoseDetectionService _poseService = PoseDetectionService();

  // --- New state variables for Advanced VTO ---
  bool _isStandardizingModel = false;
  String? _standardizedModelPath;
  String _vtoLoadingStep = '';
  final Map<String, String> _cleanedGarmentsCache = {}; // item.id -> file path
  final Set<String> _processingItems = {}; // To prevent concurrent processing of the same item
  final ImageStorageManager _imageStorageManager = ImageStorageManager();
  
  // Track manual offsets for clothing items in Quick Try mode
  final Map<String, Offset> _clothingOffsets = {};
  // ------------------------------------------

  @override
  void dispose() {
    _poseService.dispose();
    super.dispose();
  }

  String? _realisticImagePath; // Path to AI-generated image? _poseResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    // Extract outfit argument if navigation happened via route
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    Outfit? outfitFromArgs;
    
    if (args is Outfit) {
      outfitFromArgs = args;
    } else if (args is Map<String, dynamic> && args.containsKey('outfit')) {
      outfitFromArgs = args['outfit'] as Outfit?;
    }
    
    if (outfitFromArgs != null && appState.selectedItemIds.isEmpty) {
      // Use a microtask to avoid calling notifyListeners during build
      Future.microtask(() => appState.loadOutfitForTryOn(outfitFromArgs!));
    }
    
    // Reset realistic mode state when switching to Quick Try mode
    if (appState.tryOnMode == TryOnMode.quick) {
      if (_isProcessingRealistic || _hasRealisticResult) {
        setState(() {
          _isProcessingRealistic = false;
          _hasRealisticResult = false;
          _realisticImagePath = null; // Clear image
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Try-On'),
        actions: [
          // Save outfit button
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => _saveToFavorites(),
            tooltip: 'Save Outfit',
          ),
        ],
      ),
      body: isLandscape
          ? _buildLandscapeLayout(context, appState)
          : _buildPortraitLayout(context, appState),
    );
  }

  /// Builds the portrait layout (vertical arrangement)
  /// Requirements: 15.5
  Widget _buildPortraitLayout(BuildContext context, AppState appState) {
    return Column(
      children: [
        // Mode toggle buttons at top
        _buildModeToggle(context, appState),
        
        // Base photo display (main content area)
        Expanded(
          child: _buildBasePhotoArea(context, appState, Orientation.portrait),
        ),
        
        // Clothing selector button at bottom
        _buildClothingSelectorButton(context, appState),
      ],
    );
  }

  /// Builds the landscape layout (horizontal arrangement)
  /// Optimizes for wider screen by placing controls on the side
  /// Requirements: 15.5
  Widget _buildLandscapeLayout(BuildContext context, AppState appState) {
    return Row(
      children: [
        // Base photo display (main content area) - takes most of the space
        Expanded(
          flex: 3,
          child: _buildBasePhotoArea(context, appState, Orientation.landscape),
        ),
        
        // Controls panel on the right side
        SizedBox(
          width: 280,
          child: Column(
            children: [
              // Mode toggle buttons
              _buildModeToggle(context, appState),
              
              // Spacer
              const Expanded(child: SizedBox()),
              
              // Clothing selector button
              _buildClothingSelectorButton(context, appState),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the mode toggle buttons (Quick Try / Realistic Fitting)
  Widget _buildModeToggle(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ModeToggleButton(
              label: 'Quick Try',
              isSelected: appState.tryOnMode == TryOnMode.quick,
              onTap: () => appState.setTryOnMode(TryOnMode.quick),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeToggleButton(
              label: 'Realistic Fitting',
              isSelected: appState.tryOnMode == TryOnMode.realistic,
              onTap: () => appState.setTryOnMode(TryOnMode.realistic),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the base photo display area
  /// Adjusts aspect ratio based on orientation for optimal viewing
  /// Requirements: 15.5
  Widget _buildBasePhotoArea(BuildContext context, AppState appState, Orientation orientation) {
    final isLandscape = orientation == Orientation.landscape;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLandscape ? 8 : 16,
        vertical: isLandscape ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: GoldFitTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Target aspect ratio
            final targetAspectRatio = isLandscape ? 16 / 9 : 2 / 3;
            
            // Return content centered and fitted to aspect ratio
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
                child: AspectRatio(
                  aspectRatio: targetAspectRatio,
                  child: appState.tryOnMode == TryOnMode.quick
                      ? _buildQuickTryMode(context, appState)
                      : _buildRealisticMode(context, appState),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the Quick Try Mode with 2D overlay
  /// Uses Stack widget to layer clothing items on base photo
  /// Requirements: 8.4
  Widget _buildQuickTryMode(BuildContext context, AppState appState) {
    if (_isStandardizingModel) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(GoldFitTheme.gold600),
            ),
            const SizedBox(height: 24),
            Text(
              _vtoLoadingStep.isNotEmpty ? _vtoLoadingStep : 'Standardizing model photo...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: GoldFitTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final selectedItems = appState.selectedTryOnItems;
    
    // If no items selected, show placeholder
    if (selectedItems.isEmpty) {
      return Center(child: _buildBasePhotoPlaceholder(context));
    }
    
    // Trigger background removal if needed, but don't block the UI
    _cleanGarmentsIfNeeded(selectedItems);
    
    // Sort items by layering order (bottoms -> tops -> outerwear)
    final sortedItems = _sortItemsByLayerOrder(selectedItems);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = constraints.hasBoundedHeight 
            ? constraints.maxHeight 
            : MediaQuery.of(context).size.width * 1.5; // Fallback to 2:3 ratio

        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base photo layer / default silhouette background
              if (_basePhotoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LocalImageWidget(
                    imagePath: _basePhotoPath!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                // Default model background when no photo chosen
                GestureDetector(
                  onTap: _pickBasePhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [GoldFitTheme.yellow100, GoldFitTheme.backgroundLight],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 100,
                          color: GoldFitTheme.gold600.withOpacity(0.35),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to add your photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: GoldFitTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Overlay clothing items in correct order
              ...sortedItems.map((item) => _buildClothingOverlay(item, BoxConstraints.tightFor(width: constraints.maxWidth, height: height))),

              // Heart Icon (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: _buildFavoriteHeartButton(),
              ),

            ],
          ),
        );
      },
    );
  }

  /// Builds the Realistic Fitting Mode with loading and result display
  /// Shows loading indicator, simulates 2-second processing, then displays mock result
  /// Requirements: 8.5
  Widget _buildRealisticMode(BuildContext context, AppState appState) {
    // If processing, show loading indicator
    if (_isProcessingRealistic || _isStandardizingModel) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(GoldFitTheme.gold600),
              ),
              const SizedBox(height: 24),
              Text(
                _vtoLoadingStep.isNotEmpty ? _vtoLoadingStep : 'Generating realistic fitting...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: GoldFitTheme.textMedium,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GoldFitTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // If result is ready, show mock realistic result
    if (_hasRealisticResult) {
      return _buildRealisticResult(context, appState);
    }
    
    // Initial state: show placeholder with generate button
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBasePhotoPlaceholder(context),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: appState.selectedTryOnItems.isEmpty 
                    ? null 
                    : () => _generateRealisticFitting(),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Generate Realistic Fitting'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            if (appState.selectedTryOnItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Select clothing items to generate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GoldFitTheme.textLight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Simulates realistic fitting generation and calls Gemini for feedback
  /// Requirements: 8.5
  Future<void> _generateRealisticFitting() async {
    setState(() {
      _isProcessingRealistic = true;
      _hasRealisticResult = false;
      _realisticImagePath = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final selectedItems = appState.selectedTryOnItems;

    // Call Gemini API if we have a base photo
    if (_basePhotoPath != null) {
      try {
        final storage = ImageStorageManager();
        final absolutePath = await storage.getImagePath(_basePhotoPath!);
        
        // Resolve absolute/asset paths for garments
        final garmentPaths = <String>[];
        for (var item in selectedItems) {
          if (item.imageUrl.startsWith('http')) {
            // Network URL - skip (can't pass to local Gemini)
          } else if (item.imageUrl.startsWith('assets/')) {
            // Asset path - pass as-is
            garmentPaths.add(item.imageUrl);
          } else if (item.imageUrl.isNotEmpty) {
            // Local relative path
            garmentPaths.add(await storage.getImagePath(item.imageUrl));
          }
        }
        
        // Call Gemini API if we have a base photo
        final base64Image = await _geminiService.generateVirtualTryOnImage(absolutePath, garmentPaths);
        
        if (mounted) {
          
          if (base64Image != null) {
            final tempPath = await _imageStorageManager.saveTempImageFromBytes(base64Decode(base64Image));
            setState(() {
              _realisticImagePath = tempPath;
            });
          } else {
            setState(() {
              // _fittingFeedback = feedback; // Removed as per user request
            });
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error analyzing fit with Gemini: $e');
        if (mounted) {
          setState(() {
            // Fitting feedback removed as per user request
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // Simulate 2-second processing delay if no photo
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          // No photo provided
        });
      }
    }

    if (mounted) {
      setState(() {
        _isProcessingRealistic = false;
        _hasRealisticResult = true;
      });
    }
  }

  /// Builds the realistic result display
  /// Prioritizes AI generated image over the placeholder
  /// Requirements: 8.5
  Widget _buildRealisticResult(BuildContext context, AppState appState) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_realisticImagePath != null)
          // Display the actual AI generated image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(_realisticImagePath!),
              fit: BoxFit.cover,
            ),
          )
        else if (_basePhotoPath != null)
          // Fallback to base photo if AI failed but photo exists
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LocalImageWidget(
              imagePath: _basePhotoPath!,
              fit: BoxFit.cover,
            ),
          )
        else
          // Original placeholder logic
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GoldFitTheme.yellow100,
                  GoldFitTheme.backgroundLight,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Icon(
                    Icons.person,
                    size: 120,
                    color: GoldFitTheme.gold600.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

        // Result overlay and controls
        if (_realisticImagePath != null) ...[
          // Top badge
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: _buildTryOnCompleteBadge(),
            ),
          ),

          // Heart Icon (Top Right)
          Positioned(
            top: 12,
            right: 12,
            child: _buildFavoriteHeartButton(),
          ),
        ],

        // Bottom controls & feedback
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: _buildRealisticControlPanel(),
        ),
      ],
    );
  }

  /// Builds the small badge indicating VTO is complete
  Widget _buildTryOnCompleteBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: GoldFitTheme.gold600,
          ),
          const SizedBox(width: 6),
          Text(
            'Try-On Complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: GoldFitTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the heart icon button for saving to favorites
  Widget _buildFavoriteHeartButton() {
    return GestureDetector(
      onTap: _saveToFavorites,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite_border, // Make it outlined to show it's clickable and not necessarily saved yet
          color: Colors.red,
          size: 24,
        ),
      ),
    );
  }

  /// Builds the bottom panel with controls for realistic mode
  Widget _buildRealisticControlPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _generateRealisticFitting(),
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: GoldFitTheme.textDark,
                ),
              ),
              if (_realisticImagePath != null)
                ElevatedButton.icon(
                  onPressed: () => _showPoseSelectionDialog(),
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Change Pose'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveToFavorites() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final selectedItems = appState.selectedTryOnItems;

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select clothing items first')),
      );
      return;
    }

    final nameController = TextEditingController(
      text: 'My Outfit ${DateFormat('MMM d').format(DateTime.now())}',
    );

    final String? outfitName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Favorites'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Outfit Name',
            hintText: 'e.g., Summer Casual',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (outfitName == null || outfitName.isEmpty) return;

    try {
      final outfit = Outfit(
        id: const Uuid().v4(),
        name: outfitName,
        itemIds: selectedItems.map((i) => i.id).toList(),
        createdDate: DateTime.now(),
        isFavorite: true,
        modelImagePath: _basePhotoPath,
        resultImagePath: appState.tryOnMode == TryOnMode.realistic ? _realisticImagePath : null,
        vibe: 'Custom', // Default vibe
      );

      final favoritesViewModel = Provider.of<FavoritesViewModel>(context, listen: false);
      await favoritesViewModel.saveOutfit(outfit);
      // Refresh favorites list immediately so the saved item appears
      await favoritesViewModel.loadFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Favorite Outfits!'),
            backgroundColor: GoldFitTheme.gold600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPoseSelectionDialog() {
    final poses = [
      "Full frontal view, hands on hips",
      "Slightly turned, 3/4 view",
      "Side profile view",
      "Walking towards camera",
      "Leaning against a wall",
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Pose'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: poses.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(poses[index]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _changePose(poses[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePose(String poseInstruction) async {
    if (_realisticImagePath == null) return;

    setState(() {
      _isProcessingRealistic = true;
      _vtoLoadingStep = 'Changing pose to: $poseInstruction...';
    });

    try {
      final file = File(_realisticImagePath!);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final newImageBase64 = await _geminiService.generatePoseVariationForBase64(base64Image, poseInstruction);
      
      if (mounted) {
        if (newImageBase64 != null) {
          final tempPath = await _imageStorageManager.saveTempImageFromBytes(base64Decode(newImageBase64));
          setState(() {
            _realisticImagePath = tempPath;
          });
        } else {
          setState(() {
             // Pose variation failed
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Error changing pose
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingRealistic = false;
          _vtoLoadingStep = '';
        });
      }
    }
  }

  /// Sorts clothing items by their layering order
  /// Triggers background removal for new garments - uses ID-based persistent storage
  void _cleanGarmentsIfNeeded(List<ClothingItem> items) async {
    List<ClothingItem> itemsToClean = [];

    // Check all items: prioritize by ID-based file on disk
    for (final item in items) {
      // 1. Already in memory cache
      if (_cleanedGarmentsCache.containsKey(item.id)) continue;
      // 2. Currently processing
      if (_processingItems.contains(item.id)) continue;

      // 3. Check persistent file by item ID (cleaned_garments/{id}.png)
      final absoluteIdPath = await _imageStorageManager.getCleanedGarmentPath(item.id);
      if (await File(absoluteIdPath).exists()) {
        _cleanedGarmentsCache[item.id] = absoluteIdPath;
        continue;
      }

      // 4. Check if DB has a relative path saved (older format)
      if (item.cleanedImageUrl != null && item.cleanedImageUrl!.isNotEmpty) {
        try {
          final dbPath = await _imageStorageManager.getImagePath(item.cleanedImageUrl!);
          if (await File(dbPath).exists()) {
            _cleanedGarmentsCache[item.id] = dbPath;
            continue;
          }
        } catch (_) {}
      }

      // 5. Needs API call
      // itemsToClean.add(item); // Disabled per user request to prevent getting stuck at refining
    }

    if (itemsToClean.isEmpty) {
      // All items already cached or ignoring unrefined - refresh UI if needed
      if (mounted) setState(() {});
      return;
    }

    // Use microtask to avoid calling setState during build phase
    Future.microtask(() async {
      for (var item in itemsToClean) {
        _processingItems.add(item.id);
      }

      if (mounted) {
        setState(() {
          _vtoLoadingStep = 'Removing garment backgrounds...';
        });
      }

      try {
        final wardrobeViewModel = Provider.of<WardrobeViewModel>(context, listen: false);
        
        for (final item in itemsToClean) {
          if (item.imageUrl.isEmpty) continue;
          try {
            final absolutePath = await _imageStorageManager.getImagePath(item.imageUrl);
            if (!await File(absolutePath).exists()) continue;

            // Call Remove.bg API
            final cleanedBase64 = await _geminiService.removeBackground(absolutePath);
            if (cleanedBase64 != null) {
              final bytes = base64Decode(cleanedBase64);
              // Save persistently by item ID → always findable by ID, never lost on restart
              final persistentAbsolutePath = await _imageStorageManager.saveCleanedGarment(item.id, bytes);
              _cleanedGarmentsCache[item.id] = persistentAbsolutePath;
              
              // Also store relative path in DB for cross-device compatibility
              final relativeCleanedPath = 'cleaned_garments/${item.id}.png';
              final updatedItem = item.copyWith(cleanedImageUrl: relativeCleanedPath);
              await wardrobeViewModel.updateItem(updatedItem);
            }
          } catch (e) {
            // ignore: avoid_print
            print('Error cleaning garment ${item.id}: $e');
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error in _cleanGarmentsIfNeeded: $e');
      } finally {
        for (var item in itemsToClean) {
          _processingItems.remove(item.id);
        }
        if (mounted) {
          setState(() {
            _vtoLoadingStep = '';
          });
        }
      }
    });
  }

  /// Order: bottoms (back) -> tops (middle) -> outerwear (front)
  /// Requirements: 8.4
  List<ClothingItem> _sortItemsByLayerOrder(List<ClothingItem> items) {
    final layerOrder = {
      ClothingType.shoes: 0,
      ClothingType.bottoms: 1,
      ClothingType.tops: 2,
      ClothingType.outerwear: 3,
      ClothingType.accessories: 4,
    };
    
    final sorted = List<ClothingItem>.from(items);
    sorted.sort((a, b) {
      final orderA = layerOrder[a.type] ?? 0;
      final orderB = layerOrder[b.type] ?? 0;
      return orderA.compareTo(orderB);
    });
    
    return sorted;
  }

  /// Builds an overlay for a single clothing item
  /// Positions the item based on its type and pose detection
  Widget _buildClothingOverlay(ClothingItem item, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    double? top, left, right, bottom;
    double? itemWidth, itemHeight;

    // Use standardized model if available, otherwise fallback to base photo
    final photoPath = _standardizedModelPath ?? _basePhotoPath;

    if (_poseResult != null && photoPath != null && _poseResult!.imageHeight > 0) {
      // Calculate scaling factors assuming the image roughly fills the container (BoxFit.cover approximation)
      final scale = height / _poseResult!.imageHeight;
      final xOffset = (width - (_poseResult!.imageWidth * scale)) / 2;

      if (item.type == ClothingType.tops || item.type == ClothingType.outerwear) {
        final rect = _poseResult!.topRect;
        itemWidth = rect.width * scale * 1.3; // Increased slightly for standardized model
        itemHeight = rect.height * scale * 1.3;
        left = (rect.left * scale) + xOffset - (itemWidth - rect.width * scale) / 2;
        top = (rect.top * scale) - (itemHeight - rect.height * scale) / 2;
      } else if (item.type == ClothingType.bottoms) {
        final rect = _poseResult!.bottomRect;
        if (rect != Rect.zero) {
          itemWidth = rect.width * scale * 1.2; // Increased slightly
          itemHeight = rect.height * scale * 1.2;
          left = (rect.left * scale) + xOffset - (itemWidth - rect.width * scale) / 2;
          top = (rect.top * scale) - (itemHeight - rect.height * scale) / 2;
        }
      }

      // Final NaN/Infinity check
      if (top != null && (top.isNaN || top.isInfinite)) top = null;
      if (left != null && (left.isNaN || left.isInfinite)) left = null;
      if (itemWidth != null && (itemWidth.isNaN || itemWidth.isInfinite)) itemWidth = null;
      if (itemHeight != null && (itemHeight.isNaN || itemHeight.isInfinite)) itemHeight = null;
    }

    // Fallback to default positioning if pose data is unavailable or not applicable
    if (top == null || left == null) {
      final position = _getPositionForType(item.type);
      top = position.top != null ? position.top! * height : null;
      left = position.left != null ? position.left! * width : null;
      right = position.right != null ? position.right! * width : null;
      bottom = position.bottom != null ? position.bottom! * height : null;
      itemWidth = width * (position.widthScale ?? 0.6);
      itemHeight = height * (position.heightScale ?? 0.5);
      
      // Keep it centered based on new scaled width
      if (left != null && right == null) {
        left = (width - itemWidth) / 2;
      }
    }

    return Positioned(
      top: top != null ? top + (_clothingOffsets[item.id]?.dy ?? 0) : null,
      left: left != null ? left + (_clothingOffsets[item.id]?.dx ?? 0) : null,
      right: right != null ? right - (_clothingOffsets[item.id]?.dx ?? 0) : null,
      bottom: bottom != null ? bottom - (_clothingOffsets[item.id]?.dy ?? 0) : null,
      width: itemWidth,
      height: itemHeight,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _clothingOffsets[item.id] = (_clothingOffsets[item.id] ?? Offset.zero) + details.delta;
          });
        },
        child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: 0.95, // Increased opacity for better realism on standardized model
          child: _buildClothingImage(item, width: itemWidth, height: itemHeight),
        ),
      ),
    ),
  );
}

  /// Returns positioning for a clothing type
  /// Bottoms: lower portion, Tops: middle, Outerwear: top
  _OverlayPosition _getPositionForType(ClothingType type) {
    switch (type) {
      case ClothingType.shoes:
        return _OverlayPosition(
          top: null,
          left: null,
          right: null,
          bottom: 0.05,
          widthScale: 0.4,
          heightScale: 0.2,
        );
      case ClothingType.bottoms:
        return _OverlayPosition(
          top: 0.5,
          left: null,
          right: null,
          bottom: null,
          widthScale: 0.65,
          heightScale: 0.45,
        );
      case ClothingType.tops:
        return _OverlayPosition(
          top: 0.15,
          left: null,
          right: null,
          bottom: null,
          widthScale: 0.75,
          heightScale: 0.45,
        );
      case ClothingType.outerwear:
        return _OverlayPosition(
          top: 0.15,
          left: null,
          right: null,
          bottom: null,
          widthScale: 0.8,
          heightScale: 0.5,
        );
      case ClothingType.accessories:
        return _OverlayPosition(
          top: 0.1,
          left: null,
          right: null,
          bottom: null,
          widthScale: 0.3,
          heightScale: 0.2,
        );
    }
  }

  /// Builds the image widget for a clothing item
  Widget _buildClothingImage(ClothingItem item, {double? width, double? height}) {
    // Priority 1: cleaned image in memory cache
    if (_cleanedGarmentsCache.containsKey(item.id)) {
      return Image.file(
        File(_cleanedGarmentsCache[item.id]!),
        fit: BoxFit.contain,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildColorPlaceholder(item, width, height),
      );
    }

    // Priority 2: cleaned DB url
    if (item.cleanedImageUrl != null && item.cleanedImageUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: ImageStorageManager().getImagePath(item.cleanedImageUrl!),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cleanedGarmentsCache[item.id] = snapshot.data!;
            return Image.file(
              File(snapshot.data!),
              fit: BoxFit.contain,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) => _buildColorPlaceholder(item, width, height),
            );
          }
          return _buildLoadingPlaceholder(width, height);
        },
      );
    }

    // Priority 3: Asset image (mock data uses assets/folder/image.jpg)
    if (item.imageUrl.startsWith('assets/')) {
      return Image.asset(
        item.imageUrl,
        fit: BoxFit.contain,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildColorPlaceholder(item, width, height),
      );
    }

    // Priority 4: HTTP url
    if (item.imageUrl.startsWith('http')) {
      return Image.network(
        item.imageUrl,
        fit: BoxFit.contain,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildColorPlaceholder(item, width, height),
      );
    }

    // Priority 5: Local file path (user-added items: relative path via ImageStorageManager)
    if (item.imageUrl.isNotEmpty) {
      return LocalImageWidget(
        imagePath: item.imageUrl,
        fit: BoxFit.contain,
        width: width,
        height: height,
      );
    }

    return _buildColorPlaceholder(item, width, height);
  }

  Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.transparent,
      child: const Center(
        child: SizedBox(
          width: 24, 
          height: 24, 
          child: CircularProgressIndicator(strokeWidth: 2)
        )
      ),
    );
  }

  Widget _buildColorPlaceholder(ClothingItem item, double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _getColorFromName(item.color).withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          _getIconForType(item.type),
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Converts color name to Color object
  Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'black': Colors.black,
      'white': Colors.white,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'brown': Colors.brown,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'beige': const Color(0xFFF5F5DC),
      'navy': const Color(0xFF000080),
      'cream': const Color(0xFFFFFDD0),
    };
    
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }

  /// Returns icon for clothing type
  IconData _getIconForType(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
        return Icons.checkroom;
      case ClothingType.bottoms:
        return Icons.checkroom;
      case ClothingType.outerwear:
        return Icons.checkroom;
      case ClothingType.shoes:
        return Icons.shopping_bag;
      case ClothingType.accessories:
        return Icons.watch;
    }
  }

  /// Builds a placeholder for the base photo
  /// Uses a simple placeholder until actual photo functionality is implemented
  Widget _buildBasePhotoPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: _pickBasePhoto,
      child: AspectRatio(
        aspectRatio: 2 / 3, // Ép tỷ lệ khung hình chuẩn model
        child: Container(
          decoration: BoxDecoration(
            color: GoldFitTheme.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GoldFitTheme.yellow200.withOpacity(0.5)),
          ),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              if (_basePhotoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LocalImageWidget(
                    imagePath: _basePhotoPath!,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_basePhotoPath == null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: GoldFitTheme.yellow100,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: GoldFitTheme.gold600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload Base Photo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: GoldFitTheme.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Tap to select a photo of yourself for the AI to process',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GoldFitTheme.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              if (_basePhotoPath != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const Offset(0, 0) == const Offset(0, 0) ? const EdgeInsets.all(8) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBasePhoto() async {
    if (_isPickingImage) return;
    
    final picker = ImagePicker();
    try {
      setState(() => _isPickingImage = true);
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        final storage = ImageStorageManager();
        final file = File(pickedFile.path);
        final originalRelativePath = await storage.saveImage(file);
        final originalAbsolutePath = await storage.getImagePath(originalRelativePath);
        
        if (mounted) {
          setState(() {
            _basePhotoPath = originalRelativePath; // Temporarily show original
            _isStandardizingModel = true;
            _vtoLoadingStep = 'Standardizing model photo...';
          });
        }

        // 1. Standardize the model photo using Gemini
        final standardizedBase64 = await _geminiService.generateModelImage(originalAbsolutePath);
        
        String finalRelativePath = originalRelativePath;
        String finalAbsolutePath = originalAbsolutePath;

        if (standardizedBase64 != null) {
          try {
            // Save the standardized image
            final standardizedRelativePath = await storage.saveImageFromBytes(base64Decode(standardizedBase64));
            finalAbsolutePath = await storage.getImagePath(standardizedRelativePath);
            finalRelativePath = standardizedRelativePath;
          } catch (e) {
             print("Error saving standardized model: $e");
          }
        }

        // 2. Analyze pose on the final (preferably standardized) photo
        if (mounted) {
          setState(() {
            _vtoLoadingStep = 'Analyzing pose...';
          });
        }
        final poseResult = await _poseService.analyzeImage(finalAbsolutePath);

        if (mounted) {
          setState(() {
            _basePhotoPath = finalRelativePath;
            _standardizedModelPath = finalRelativePath;
            _poseResult = poseResult;
            _isStandardizingModel = false;
            _vtoLoadingStep = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick/process image: $e')),
        );
      }
      setState(() {
        _isStandardizingModel = false;
        _vtoLoadingStep = '';
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  /// Builds the clothing selector button at the bottom
  Widget _buildClothingSelectorButton(BuildContext context, AppState appState) {
    final selectedCount = appState.selectedItemIds.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldFitTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showClothingSelectorBottomSheet(context, appState),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.checkroom, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selectedCount > 0 
                        ? 'Select Clothing ($selectedCount selected)'
                        : 'Select Clothing',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the clothing selector bottom sheet
  /// Displays a grid of wardrobe items with multi-select capability
  /// Requirements: 8.3, 8.4
  void _showClothingSelectorBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClothingSelectorBottomSheet(appState: appState),
    );
  }
}

/// Custom widget for mode toggle buttons
class _ModeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? GoldFitTheme.primary : GoldFitTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GoldFitTheme.primary : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? GoldFitTheme.textDark : GoldFitTheme.textMedium,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper class for positioning overlay items
/// Stores fractional positions (0.0 to 1.0) for top, left, right, bottom
class _OverlayPosition {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double? widthScale;
  final double? heightScale;

  _OverlayPosition({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.widthScale,
    this.heightScale,
  });
}

/// Clothing selector bottom sheet widget
/// Displays a grid of wardrobe items with multi-select capability
/// Requirements: 8.3, 8.4
class _ClothingSelectorBottomSheet extends StatefulWidget {
  final AppState appState;

  const _ClothingSelectorBottomSheet({
    required this.appState,
  });

  @override
  State<_ClothingSelectorBottomSheet> createState() => _ClothingSelectorBottomSheetState();
}

class _ClothingSelectorBottomSheetState extends State<_ClothingSelectorBottomSheet> {
  ClothingType? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: GoldFitTheme.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GoldFitTheme.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Clothing',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: GoldFitTheme.textDark,
                      ),
                    ),
                    Row(
                      children: [
                        if (appState.selectedItemIds.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              appState.clearTryOnSelection();
                            },
                            child: const Text('Clear All'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Category tabs
              _buildCategoryTabs(),
              
              // Grid of clothing items
              Expanded(
                child: _buildClothingGrid(appState),
              ),
              
              // Done button
              _buildDoneButton(context, appState),
            ],
          ),
        );
      },
    );
  }

  /// Builds the category filter tabs
  Widget _buildCategoryTabs() {
    final categories = [
      (null, 'All'),
      (ClothingType.tops, 'Tops'),
      (ClothingType.bottoms, 'Bottoms'),
      (ClothingType.outerwear, 'Outerwear'),
      (ClothingType.shoes, 'Shoes'),
      (ClothingType.accessories, 'Accessories'),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category.$1;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category.$1;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? GoldFitTheme.primary : GoldFitTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? GoldFitTheme.primary : const Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category.$2,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? GoldFitTheme.textDark : GoldFitTheme.textMedium,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the grid of clothing items
  Widget _buildClothingGrid(AppState appState) {
    final wardrobeViewModel = Provider.of<WardrobeViewModel>(context, listen: false);
    
    // Get items based on selected category
    final items = _selectedCategory != null
        ? wardrobeViewModel.items.where((i) => i.type == _selectedCategory).toList()
        : wardrobeViewModel.items;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: GoldFitTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No items in this category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: GoldFitTheme.textMedium,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = appState.selectedItemIds.contains(item.id);
        
        return _ClothingItemSelector(
          item: item,
          isSelected: isSelected,
          onTap: () {
            if (isSelected) {
              appState.deselectItemForTryOn(item.id);
            } else {
              appState.selectItemForTryOn(item.id);
            }
          },
        );
      },
    );
  }

  /// Builds the done button at the bottom
  Widget _buildDoneButton(BuildContext context, AppState appState) {
    final selectedCount = appState.selectedItemIds.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldFitTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              selectedCount > 0 
                  ? 'Done ($selectedCount selected)'
                  : 'Done',
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual clothing item selector widget with selection indicator
class _ClothingItemSelector extends StatelessWidget {
  final ClothingItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClothingItemSelector({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Item card
          Container(
            decoration: BoxDecoration(
              color: GoldFitTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? GoldFitTheme.primary : const Color(0xFFF1F5F9),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: GoldFitTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildItemImage(),
            ),
          ),
          
          // Selection indicator
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: GoldFitTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: GoldFitTheme.textDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the item image or placeholder
  Widget _buildItemImage() {
    if (item.imageUrl.contains('/')) {
      return LocalImageWidget(
        imagePath: item.imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      return _buildPlaceholder();
    }
  }

  /// Builds a colored placeholder with an icon
  Widget _buildPlaceholder() {
    return Container(
      color: _getColorFromName(item.color),
      child: Center(
        child: Icon(
          _getIconForType(item.type),
          size: 32,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  /// Returns a Color based on the color name string
  Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red.shade300,
      'blue': Colors.blue.shade300,
      'green': Colors.green.shade300,
      'yellow': Colors.yellow.shade300,
      'black': Colors.grey.shade800,
      'white': Colors.grey.shade200,
      'gray': Colors.grey.shade400,
      'grey': Colors.grey.shade400,
      'brown': Colors.brown.shade300,
      'pink': Colors.pink.shade300,
      'purple': Colors.purple.shade300,
      'orange': Colors.orange.shade300,
      'beige': const Color(0xFFF5F5DC),
      'navy': Colors.indigo.shade700,
      'burgundy': const Color(0xFF800020),
      'olive': const Color(0xFF808000),
      'teal': Colors.teal.shade300,
    };
    
    return colorMap[colorName.toLowerCase()] ?? Colors.grey.shade300;
  }

  /// Returns an icon based on the clothing type
  IconData _getIconForType(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
        return Icons.checkroom;
      case ClothingType.bottoms:
        return Icons.dry_cleaning;
      case ClothingType.outerwear:
        return Icons.ac_unit;
      case ClothingType.shoes:
        return Icons.shopping_bag;
      case ClothingType.accessories:
        return Icons.watch;
    }
  }
}
