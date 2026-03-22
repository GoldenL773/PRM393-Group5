import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';

class TryOnCompareScreen extends StatefulWidget {
  final String? currentTryOnPath;
  final String? currentOutfitName;
  
  const TryOnCompareScreen({
    super.key, 
    this.currentTryOnPath,
    this.currentOutfitName,
  });

  @override
  State<TryOnCompareScreen> createState() => _TryOnCompareScreenState();
}

class _TryOnCompareScreenState extends State<TryOnCompareScreen> {
  String? _selectedComparePath;
  String? _selectedCompareName;
  int _activeOption = 0; // 0 = none, 1 = alpha, 2 = beta
  bool _showSelectGuide = false;

  static const _backgroundColor = Color(0xFF131313);
  static const _surfaceColor = Color(0xFF1C1B1B);
  static const _goldColor = Color(0xFFF7BD48);
  static const _goldDimColor = Color(0xFFBA880F);
  static const _textColor = Color(0xFFE5E2E1);
  static const _textMutedColor = Color(0xFFD3C4AF);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesViewModel>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAlphaCard(),
                    _buildGoldDivider(),
                    _buildBetaCard(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    _buildFavoritesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surfaceColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: _goldColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURATION LAB',
                  style: TextStyle(
                    color: _goldColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Compare Outfits',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlphaCard() {
    final isSelected = _activeOption == 1;
    return GestureDetector(
      onTap: () => setState(() => _activeOption = isSelected ? 0 : 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _goldColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: widget.currentTryOnPath != null
                  ? Image.file(
                      File(widget.currentTryOnPath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _surfaceColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 64, color: _goldColor.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('No try-on image\nGo back and try an outfit',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _textMutedColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
            ),
            // OPTION ALPHA label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: _goldColor,
                child: const Text(
                  'OPTION ALPHA',
                  style: TextStyle(
                    color: Color(0xFF271900),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            // Outfit name label at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Text(
                  widget.currentOutfitName ?? 'Current Look',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Selected indicator
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: _goldColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 18, color: Color(0xFF271900)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 1,
      color: _goldDimColor.withOpacity(0.4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: _backgroundColor,
            child: Text(
              'VS',
              style: TextStyle(
                color: _goldColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetaCard() {
    final isSelected = _activeOption == 2;
    return GestureDetector(
      onTap: () {
        if (_selectedComparePath == null) {
          setState(() => _showSelectGuide = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showSelectGuide = false);
          });
          return;
        }
        setState(() => _activeOption = isSelected ? 0 : 2);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _goldColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: _selectedComparePath != null
                  ? Image.file(
                      File(_selectedComparePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _surfaceColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _showSelectGuide ? Icons.arrow_downward : Icons.image_search_outlined,
                              size: 64,
                              color: _showSelectGuide ? _goldColor : _goldColor.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showSelectGuide
                                ? 'Tap a favorite below ↓'
                                : 'Select from favorites below\nto compare outfits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _showSelectGuide ? _goldColor : _textMutedColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // OPTION BETA label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: _surfaceColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, color: _goldColor),
                    const SizedBox(width: 6),
                    const Text(
                      'OPTION BETA',
                      style: TextStyle(
                        color: _goldColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Outfit name if selected
            if (_selectedCompareName != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    _selectedCompareName!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            // Selected indicator
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: _goldColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 18, color: Color(0xFF271900)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Select Alpha
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _activeOption == 1 || _activeOption == 0
                  ? () {
                      setState(() => _activeOption = 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Option Alpha selected!'), backgroundColor: Color(0xFFBA880F)),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldColor,
                foregroundColor: const Color(0xFF271900),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                'SELECT OPTION ALPHA',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Save Both
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Both outfits saved to Favorites!'), backgroundColor: Color(0xFFBA880F)),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _goldColor,
                side: const BorderSide(color: _goldDimColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text(
                'SAVE BOTH TO CLOSET',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return Consumer<FavoritesViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: _goldColor)),
          );
        }

        final outfitsWithImages = viewModel.favoriteOutfits
            .where((o) => o.resultImagePath != null || o.modelImagePath != null)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SELECT FROM FAVORITES',
                    style: TextStyle(
                      color: _textMutedColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${outfitsWithImages.length} outfits',
                    style: TextStyle(color: _goldColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (outfitsWithImages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(color: _surfaceColor),
                  child: Center(
                    child: Text(
                      'Save realistic try-on outfits to compare',
                      style: TextStyle(color: _textMutedColor, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: outfitsWithImages.length,
                  itemBuilder: (context, index) {
                    final outfit = outfitsWithImages[index];
                    final imagePath = outfit.resultImagePath ?? outfit.modelImagePath!;
                    final isSelected = _selectedComparePath == imagePath;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedComparePath = imagePath;
                          _selectedCompareName = outfit.name;
                          // Auto-select Beta
                          _activeOption = 2;
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? _goldColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _surfaceColor,
                                child: Icon(Icons.broken_image, color: _textMutedColor),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: Colors.black.withOpacity(0.6),
                                child: Text(
                                  outfit.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
