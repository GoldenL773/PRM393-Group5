import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

class EditClothingScreen extends StatefulWidget {
  const EditClothingScreen({super.key});

  @override
  State<EditClothingScreen> createState() => _EditClothingScreenState();
}

class _EditClothingScreenState extends State<EditClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late ClothingType _selectedType;
  late String _selectedColor;
  late List<Season> _selectedSeasons;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
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
      _nameController = TextEditingController(text: item.name);
      _priceController = TextEditingController(text: item.price.toString());
      _selectedType = item.type;
      _selectedColor = item.color;
      _selectedSeasons = List.from(item.seasons);
      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Clothing'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              Center(
                child: Container(
                  width: 200,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LocalImageWidget(
                      imagePath: item.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              Text(
                'Item Name',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Blue Cotton Shirt',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a name';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Price Field
              Text(
                'Price (\$)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a price';
                  if (double.tryParse(value) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Type Dropdown
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClothingType>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ClothingType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.substring(0, 1).toUpperCase() + type.name.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Seasons
              Text(
                'Seasons',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Season.values.map((season) {
                  final isSelected = _selectedSeasons.contains(season);
                  return FilterChip(
                    label: Text(season.name.substring(0, 1).toUpperCase() + season.name.substring(1)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSeasons.add(season);
                        } else {
                          _selectedSeasons.remove(season);
                        }
                      });
                    },
                    selectedColor: GoldFitTheme.yellow100,
                    checkmarkColor: GoldFitTheme.gold600,
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveChanges(item, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoldFitTheme.primary,
                    foregroundColor: GoldFitTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges(ClothingItem item, WardrobeViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSeasons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one season')),
        );
        return;
      }

      final updatedItem = item.copyWith(
        name: _nameController.text,
        price: double.parse(_priceController.text),
        type: _selectedType,
        seasons: _selectedSeasons,
      );

      try {
        await viewModel.updateItem(updatedItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
