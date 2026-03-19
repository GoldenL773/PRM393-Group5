import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';

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
  String? _basePhotoPath;
  String? _fittingFeedback;
  final GeminiService _geminiService = GeminiService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    // Extract outfit argument if navigation happened via route
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('outfit')) {
      final outfit = args['outfit'] as Outfit;
      // Load outfit into selection if it's different or if selection is empty
      if (appState.selectedItemIds.isEmpty) {
        // Use a microtask to avoid calling notifyListeners during build
        Future.microtask(() => appState.loadOutfitForTryOn(outfit));
      }
    }
    
    // Reset realistic mode state when switching to Quick Try mode
    if (appState.tryOnMode == TryOnMode.quick) {
      if (_isProcessingRealistic || _hasRealisticResult) {
        setState(() {
          _isProcessingRealistic = false;
          _hasRealisticResult = false;
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
            onPressed: () {
              // TODO: Implement save outfit functionality in Task 13.4
            },
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _ModeToggleButton(
              label: 'Quick Try',
              isSelected: appState.tryOnMode == TryOnMode.quick,
              onTap: () => appState.setTryOnMode(TryOnMode.quick),
            ),
          ),
          const SizedBox(width: 12),
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
            // Calculate optimal aspect ratio based on orientation
            // Portrait: taller (2:3), Landscape: wider (16:9)
            final targetAspectRatio = isLandscape ? 16 / 9 : 2 / 3;
            final availableAspectRatio = constraints.maxWidth / constraints.maxHeight;
            
            // Use AspectRatio only if it fits within available space
            // Otherwise, let content fill available space
            if ((isLandscape && availableAspectRatio >= targetAspectRatio) ||
                (!isLandscape && availableAspectRatio <= targetAspectRatio)) {
              return AspectRatio(
                aspectRatio: targetAspectRatio,
                child: appState.tryOnMode == TryOnMode.quick
                    ? _buildQuickTryMode(context, appState)
                    : _buildRealisticMode(context, appState),
              );
            } else {
              // Fill available space when aspect ratio doesn't fit
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: appState.tryOnMode == TryOnMode.quick
                    ? _buildQuickTryMode(context, appState)
                    : _buildRealisticMode(context, appState),
              );
            }
          },
        ),
      ),
    );
  }

  /// Builds the Quick Try Mode with 2D overlay
  /// Uses Stack widget to layer clothing items on base photo
  /// Requirements: 8.4
  Widget _buildQuickTryMode(BuildContext context, AppState appState) {
    final selectedItems = appState.selectedTryOnItems;
    
    // If no items selected, show placeholder
    if (selectedItems.isEmpty) {
      return Center(child: _buildBasePhotoPlaceholder(context));
    }
    
    // Sort items by layering order (bottoms -> tops -> outerwear)
    final sortedItems = _sortItemsByLayerOrder(selectedItems);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base photo layer
            _buildBasePhotoPlaceholder(context),
            
            // Overlay clothing items in correct order
            ...sortedItems.map((item) => _buildClothingOverlay(item, constraints)),
          ],
        );
      },
    );
  }

  /// Builds the Realistic Fitting Mode with loading and result display
  /// Shows loading indicator, simulates 2-second processing, then displays mock result
  /// Requirements: 8.5
  Widget _buildRealisticMode(BuildContext context, AppState appState) {
    // If processing, show loading indicator
    if (_isProcessingRealistic) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(GoldFitTheme.gold600),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating realistic fitting...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: GoldFitTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
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
      );
    }
    
    // If result is ready, show mock realistic result
    if (_hasRealisticResult) {
      return _buildRealisticResult(context, appState);
    }
    
    // Initial state: show placeholder with generate button
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBasePhotoPlaceholder(context),
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
    );
  }

  /// Simulates realistic fitting generation and calls Gemini for feedback
  /// Requirements: 8.5
  Future<void> _generateRealisticFitting() async {
    setState(() {
      _isProcessingRealistic = true;
      _hasRealisticResult = false;
      _fittingFeedback = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final selectedItems = appState.selectedTryOnItems;

    // Call Gemini API if we have a base photo
    if (_basePhotoPath != null) {
      try {
        final storage = ImageStorageManager();
        final absolutePath = await storage.getImagePath(_basePhotoPath!);
        
        final feedback = await _geminiService.analyzeFit(absolutePath, selectedItems);
        
        if (mounted) {
          setState(() {
            _fittingFeedback = feedback;
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error analyzing fit with Gemini: $e');
        if (mounted) {
          setState(() {
            _fittingFeedback = "Could not analyze the fit at this time.";
          });
        }
      }
    } else {
      // Simulate 2-second processing delay if no photo
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _fittingFeedback = "Upload a base photo to get personalized fit analysis from AI!";
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

  /// Builds the mock realistic result display
  /// Requirements: 8.5
  Widget _buildRealisticResult(BuildContext context, AppState appState) {
    final selectedItems = appState.selectedTryOnItems;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Mock realistic result - enhanced base photo with better integration
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
              // Enhanced person icon with clothing overlay effect
              Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: GoldFitTheme.gold600.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Base figure or user's photo
                    if (_basePhotoPath != null)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LocalImageWidget(
                            imagePath: _basePhotoPath!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.person,
                          size: 120,
                          color: GoldFitTheme.gold600.withOpacity(0.3),
                        ),
                      ),
                    // Overlay selected items as colored layers
                    ...selectedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Positioned(
                        top: 40 + (index * 15.0),
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getColorFromName(item.color).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getIconForType(item.type),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: GoldFitTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: GoldFitTheme.textDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Realistic Fitting Complete',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GoldFitTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_fittingFeedback != null) ...[
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GoldFitTheme.yellow200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: GoldFitTheme.gold600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fittingFeedback!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: GoldFitTheme.textDark,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Regenerate button in top-right corner
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _generateRealisticFitting(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      Icons.refresh,
                      size: 16,
                      color: GoldFitTheme.gold600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Regenerate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GoldFitTheme.gold600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sorts clothing items by their layering order
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
  /// Positions the item based on its type
  Widget _buildClothingOverlay(ClothingItem item, BoxConstraints constraints) {
    // Position based on clothing type
    final position = _getPositionForType(item.type);
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    
    return Positioned(
      top: position.top != null ? position.top! * height : null,
      left: position.left != null ? position.left! * width : null,
      right: position.right != null ? position.right! * width : null,
      bottom: position.bottom != null ? position.bottom! * height : null,
      child: Opacity(
        opacity: 0.85,
        child: _buildClothingImage(item),
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
          left: 0.25,
          right: 0.25,
          bottom: 0.05,
        );
      case ClothingType.bottoms:
        return _OverlayPosition(
          top: 0.45,
          left: 0.2,
          right: 0.2,
          bottom: 0.15,
        );
      case ClothingType.tops:
        return _OverlayPosition(
          top: 0.25,
          left: 0.15,
          right: 0.15,
          bottom: 0.45,
        );
      case ClothingType.outerwear:
        return _OverlayPosition(
          top: 0.2,
          left: 0.1,
          right: 0.1,
          bottom: 0.4,
        );
      case ClothingType.accessories:
        return _OverlayPosition(
          top: 0.15,
          left: 0.3,
          right: 0.3,
          bottom: null,
        );
    }
  }

  /// Builds the image widget for a clothing item
  Widget _buildClothingImage(ClothingItem item) {
    if (item.imageUrl.contains('/')) {
      return LocalImageWidget(
        imagePath: item.imageUrl,
        fit: BoxFit.contain,
      );
    } else {
      // Use colored container with icon as placeholder
      return Container(
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_basePhotoPath != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LocalImageWidget(
                  imagePath: _basePhotoPath!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (_basePhotoPath == null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: GoldFitTheme.yellow100,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 64,
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
                Text(
                  'Tap to select a photo of yourself',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GoldFitTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          if (_basePhotoPath != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
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
    );
  }

  Future<void> _pickBasePhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        final storage = ImageStorageManager();
        final file = File(pickedFile.path);
        final relativePath = await storage.saveImage(file);

        if (mounted) {
          setState(() {
            _basePhotoPath = relativePath;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
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

  _OverlayPosition({
    this.top,
    this.left,
    this.right,
    this.bottom,
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
    // Get items based on selected category
    final items = _selectedCategory != null
        ? appState.dataProvider.getItemsByCategory(_selectedCategory!)
        : appState.allItems;

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
