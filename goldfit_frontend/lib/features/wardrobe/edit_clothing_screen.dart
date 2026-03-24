import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';
import 'package:goldfit_frontend/shared/services/gemini_service.dart';
import 'package:intl/intl.dart';

class EditClothingScreen extends StatefulWidget {
  const EditClothingScreen({super.key});

  @override
  State<EditClothingScreen> createState() => _EditClothingScreenState();
}

class _EditClothingScreenState extends State<EditClothingScreen> {
  late TextEditingController _priceController;
  late ClothingType _selectedType;
  late List<Season> _selectedSeasons;
  late String _selectedColor;
  String? _newImagePath;
  bool _isProcessingImage = false;
  bool _isInitialized = false;

  // Colors
  static const bgColor = Color(0xFFFCFBF8);
  static const surfaceColor = Color(0xFFF6F5F2);
  static const textDark = Color(0xFF1E1E1E);
  static const textGrey = Color(0xFF8E8E8E);
  static const goldAccent = Color(0xFF8B6914);
  static const goldLight = Color(0xFFD4AF37);

  final List<String> availableColors = [
    'black', 'white', 'navy', 'gray', 'beige', 'brown',
    'red', 'blue', 'green', 'yellow', 'pink', 'purple',
    'maroon', 'teal', 'olive'
  ];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final itemId = args?['itemId'] as String?;

    if (itemId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Item')),
        body: const Center(child: Text('No item ID provided')),
      );
    }

    final viewModel = Provider.of<WardrobeViewModel>(context, listen: false);
    final item = viewModel.items.firstWhere((i) => i.id == itemId);

    if (!_isInitialized) {
      _priceController = TextEditingController(text: item.price?.toStringAsFixed(2) ?? '');
      _selectedType = item.type;
      _selectedSeasons = List.from(item.seasons);
      _selectedColor = item.color.toLowerCase();
      if (!availableColors.contains(_selectedColor)) {
        availableColors.add(_selectedColor); // safe fallback
      }
      _isInitialized = true;
    }

    final currentDisplayImage = _newImagePath ?? item.imageUrl;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Item',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveChanges(item, viewModel),
            child: const Text('Save', style: TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Area (Image + Buttons)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: currentDisplayImage.startsWith('http')
                              ? Image.network(currentDisplayImage, fit: BoxFit.cover)
                              : LocalImageWidget(imagePath: currentDisplayImage, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildImageActionButton(
                            icon: Icons.camera_alt,
                            label: 'RETAKE',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                          const SizedBox(height: 16),
                          _buildImageActionButton(
                            icon: Icons.photo_library,
                            label: 'GALLERY',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Item Label (Read Only aesthetically)
                _buildSectionHeader('ITEM LABEL'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '${_capitalize(_selectedColor)} ${_formatClothingType(_selectedType)}',
                    style: const TextStyle(fontSize: 16, color: textDark, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 24),

                // Value and Category Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('VALUE (USD)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(color: textGrey, fontSize: 16),
                              filled: true,
                              fillColor: surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('CATEGORY'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ClothingType>(
                            value: _selectedType,
                            icon: const Icon(Icons.unfold_more, color: textGrey),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            items: ClothingType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(_formatClothingType(type), style: const TextStyle(fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Seasonal Versatility
                _buildSectionHeader('SEASONAL VERSATILITY'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Season.values.map((season) {
                    final isSelected = _selectedSeasons.contains(season);
                    return ChoiceChip(
                      label: Text(_formatSeason(season)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSeasons.add(season);
                          } else if (_selectedSeasons.length > 1) {
                            _selectedSeasons.remove(season);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('At least one season must be selected')),
                            );
                          }
                        });
                      },
                      backgroundColor: surfaceColor,
                      selectedColor: goldLight,
                      labelStyle: TextStyle(
                        color: isSelected ? textDark : textGrey,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Core Palette
                _buildSectionHeader('CORE PALETTE'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getColorFromName(_selectedColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedColor,
                            isExpanded: true,
                            icon: const SizedBox.shrink(), // hide default icon
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            items: availableColors.map((color) {
                              return DropdownMenuItem(
                                value: color,
                                child: Text(_capitalize(color)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedColor = val);
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('CHANGE', style: TextStyle(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textGrey, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: goldAccent),
                                const SizedBox(width: 6),
                                Text(item.usageCount > 5 ? 'High Utility Score' : 'Trending Score', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: goldAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('ADDED DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textGrey, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM dd, yyyy').format(item.addedDate), style: const TextStyle(fontSize: 12, color: textDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _saveChanges(item, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('DISCARD CHANGES', style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          if (_isProcessingImage)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: goldAccent),
                    SizedBox(height: 16),
                    Text('Processing image...', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: textGrey),
    );
  }

  Widget _buildImageActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: textDark, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: textDark)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1080);
      if (pickedFile != null) {
        setState(() => _isProcessingImage = true);

        final storage = ImageStorageManager();
        final geminiService = GeminiService();
        String relativePath;

        try {
          final processedBase64 = await geminiService.removeBackground(pickedFile.path);
          if (processedBase64 != null) {
            final bytes = base64Decode(processedBase64);
            relativePath = await storage.saveImageFromBytes(bytes);
          } else {
            final file = File(pickedFile.path);
            relativePath = await storage.saveImage(file);
          }
        } catch (e) {
          final file = File(pickedFile.path);
          relativePath = await storage.saveImage(file);
        }

        if (mounted) {
          setState(() {
            _newImagePath = relativePath;
            _isProcessingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _saveChanges(ClothingItem item, WardrobeViewModel viewModel) async {
    if (_selectedSeasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one season')));
      return;
    }

    double? newPrice;
    if (_priceController.text.isNotEmpty) {
      newPrice = double.tryParse(_priceController.text);
      if (newPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price format')));
        return;
      }
    }

    final updatedItem = item.copyWith(
      imageUrl: _newImagePath ?? item.imageUrl,
      price: newPrice,
      type: _selectedType,
      color: _selectedColor,
      seasons: _selectedSeasons,
    );

    try {
      await viewModel.updateItem(updatedItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: goldAccent));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatClothingType(ClothingType type) {
    switch (type) {
      case ClothingType.tops: return 'Tops';
      case ClothingType.bottoms: return 'Bottoms';
      case ClothingType.outerwear: return 'Outerwear';
      case ClothingType.shoes: return 'Shoes';
      case ClothingType.accessories: return 'Accessories';
    }
  }

  String _formatSeason(Season season) {
    switch (season) {
      case Season.spring: return 'Spring';
      case Season.summer: return 'Summer';
      case Season.fall: return 'Autumn'; // "Autumn" matches design better than "Fall"
      case Season.winter: return 'Winter';
    }
  }

  Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red, 'blue': Colors.blue, 'green': Colors.green, 'yellow': Colors.yellow,
      'black': Colors.black, 'white': Colors.white, 'grey': Colors.grey, 'gray': Colors.grey,
      'brown': Colors.brown, 'pink': Colors.pink, 'purple': Colors.purple, 'beige': const Color(0xFFF5F5DC),
      'navy': const Color(0xFF000080), 'maroon': const Color(0xFF800000), 'teal': Colors.teal, 'olive': const Color(0xFF808000),
    };
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }
}
