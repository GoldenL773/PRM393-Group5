import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';
import 'package:goldfit_frontend/features/planner/planner_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';

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
  bool _isAnalyzing = false;

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

  void _showFavoritesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<FavoritesViewModel>(
              builder: (context, viewModel, child) {
                final outfits = viewModel.favoriteOutfits
                    .where((o) => o.resultImagePath != null || o.modelImagePath != null)
                    .toList();

                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: _goldColor));
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _goldDimColor, width: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SELECT RECENT TRY-ON',
                            style: TextStyle(
                              color: _goldColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: _textColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    if (outfits.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No saved outfits found. Try on some items first!',
                              style: TextStyle(color: _textMutedColor)),
                        ),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: outfits.length,
                          itemBuilder: (context, index) {
                            final outfit = outfits[index];
                            final imagePath = outfit.resultImagePath ?? outfit.modelImagePath!;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedComparePath = imagePath;
                                  _selectedCompareName = outfit.name;
                                });
                                Navigator.pop(context);
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: _backgroundColor,
                                      child: const Icon(Icons.broken_image, color: _textMutedColor),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.black.withOpacity(0.7),
                                      child: Text(
                                        outfit.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _askAIStylist() async {
    if (widget.currentTryOnPath == null || _selectedComparePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two outfits to compare!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Prompt for context event/weather before analyzing
    final contextController = TextEditingController();
    final eventContext = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        title: const Text('Event / Weather', style: TextStyle(color: _textColor)),
        content: TextField(
          controller: contextController,
          style: const TextStyle(color: Colors.black87), // Dark text on light background
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'e.g., Summer beach party, Office meeting...',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldDimColor)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _goldColor)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textMutedColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, contextController.text.isNotEmpty ? contextController.text : "an upcoming event"),
            style: ElevatedButton.styleFrom(backgroundColor: _goldColor, foregroundColor: Colors.black),
            child: const Text('Ask AI'),
          ),
        ],
      ),
    );

    if (eventContext == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final aiService = GeminiService();
      final advice = await aiService.compareOutfits(
        widget.currentTryOnPath!,
        _selectedComparePath!,
        eventContext,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: _surfaceColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _goldColor),
                  const SizedBox(width: 12),
                  const Text(
                    'AI STYLIST VERDICT',
                    style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                advice,
                style: const TextStyle(color: _textColor, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _goldColor,
                    side: const BorderSide(color: _goldColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get AI analysis.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _selectOutfit(String? path, String optionName) async {
    if (path == null) return;

    final plannerViewModel = Provider.of<PlannerViewModel>(context, listen: false);
    
    final selectedSlot = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        title: Text('Add to Planner', style: TextStyle(color: _goldColor, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Which session would you like to assign this look to?', 
                style: TextStyle(color: _textColor, fontSize: 14)),
            const SizedBox(height: 20),
            _buildSlotButton(context, 'Morning', Icons.wb_sunny_outlined),
            const SizedBox(height: 12),
            _buildSlotButton(context, 'Afternoon', Icons.light_mode),
            const SizedBox(height: 12),
            _buildSlotButton(context, 'Evening', Icons.nightlight_round),
          ],
        ),
      ),
    );

    if (selectedSlot == null) return;

    setState(() => _isAnalyzing = true); // Use loader for saving too

    try {
      await plannerViewModel.createAndAssignOutfit(
        name: '${optionName.replaceAll('OPTION ', '')} Style',
        resultImagePath: path,
        date: DateTime.now(),
        timeSlot: selectedSlot,
        eventName: 'New Look Selection',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Planner for $selectedSlot!'),
          backgroundColor: _goldDimColor,
          action: SnackBarAction(
            label: 'VIEW PLANNER',
            textColor: Colors.white,
            onPressed: () {
              // Navigation logic here if needed, or user can tap back
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save to Planner.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _buildSlotButton(BuildContext context, String slot, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: _goldColor, size: 20),
        label: Text(slot, style: const TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.pop(context, slot),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _goldDimColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    );
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
              child: Row(
                children: [
                  Expanded(child: _buildAlphaCard()),
                  Container(width: 1, color: _goldDimColor.withOpacity(0.3)),
                  Expanded(child: _buildBetaCard()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAskAIButton(),
            const SizedBox(height: 24),
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
              decoration: const BoxDecoration(color: _surfaceColor, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: _goldColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURATION LAB',
                  style: TextStyle(color: _goldColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2),
                ),
                Text(
                  'Compare Outfits',
                  style: TextStyle(color: _textColor, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlphaCard() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.currentTryOnPath != null
                  ? LocalImageWidget(
                      imagePath: widget.currentTryOnPath!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _surfaceColor,
                      child: const Center(
                        child: Text('No original try-on', style: TextStyle(color: _textMutedColor), textAlign: TextAlign.center),
                      ),
                    ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: _goldColor,
                  child: const Text('OPTION ALPHA',
                      style: TextStyle(color: Color(0xFF271900), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: OutlinedButton(
            onPressed: () => _selectOutfit(widget.currentTryOnPath, 'Option Alpha'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textColor,
              side: const BorderSide(color: _surfaceColor, width: 2),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('SELECT THIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBetaCard() {
    final hasImage = _selectedComparePath != null;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showFavoritesBottomSheet,
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasImage
                    ? LocalImageWidget(
                        imagePath: _selectedComparePath!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: _surfaceColor,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: _goldColor.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to select\nan outfit',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _textMutedColor, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: _surfaceColor,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, color: _goldColor),
                        const SizedBox(width: 4),
                        const Text('OPTION BETA',
                            style: TextStyle(color: _goldColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: OutlinedButton(
            onPressed: hasImage ? () => _selectOutfit(_selectedComparePath, 'Option Beta') : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textColor,
              disabledForegroundColor: _textMutedColor.withOpacity(0.3),
              side: BorderSide(color: hasImage ? _surfaceColor : Colors.transparent, width: 2),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('SELECT THIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildAskAIButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isAnalyzing ? () {} : _askAIStylist, // Don't return null to keep color
          icon: _isAnalyzing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Icon(Icons.auto_awesome, color: Colors.black, size: 24),
          label: Text(
            _isAnalyzing ? 'ANALYZING...' : '✨ ASK AI STYLIST',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 15, color: Colors.black),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _goldColor,
            disabledBackgroundColor: _goldColor, // Keep color when "disabled"
            disabledForegroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
    );
  }
}
