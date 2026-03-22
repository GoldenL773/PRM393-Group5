import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/wardrobe/collection_viewmodel.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';

class CollectionEditorScreen extends StatefulWidget {
  const CollectionEditorScreen({super.key});

  @override
  State<CollectionEditorScreen> createState() => _CollectionEditorScreenState();
}

class _CollectionEditorScreenState extends State<CollectionEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedItemIds = <String>{};

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final collectionId = args?['collectionId'] as String?;
    final isEditMode = collectionId != null;

    final collectionViewModel = Provider.of<CollectionViewModel>(
      context,
      listen: false,
    );
    final wardrobeViewModel = Provider.of<WardrobeViewModel>(
      context,
      listen: false,
    );
    final existingCollection = isEditMode
        ? collectionViewModel.getById(collectionId)
        : null;

    if (isEditMode && existingCollection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection')),
        body: const Center(child: Text('Collection not found')),
      );
    }

    if (!_isInitialized) {
      _nameController.text = existingCollection?.name ?? '';
      _selectedItemIds
        ..clear()
        ..addAll(existingCollection?.itemIds ?? const <String>[]);
      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: GoldFitTheme.backgroundLight,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Collection' : 'Create Collection'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: GoldFitTheme.yellow200.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Collection name',
                    hintText: 'Example: Summer Streetwear',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: GoldFitTheme.tertiary.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Selected ${_selectedItemIds.length} item(s)',
                    style: const TextStyle(
                      color: GoldFitTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Choose from Wardrobe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GoldFitTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: wardrobeViewModel.items.isEmpty
                ? const Center(
                    child: Text('No wardrobe items available to add'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: wardrobeViewModel.items.length,
                    itemBuilder: (context, index) {
                      final item = wardrobeViewModel.items[index];
                      final isSelected = _selectedItemIds.contains(item.id);
                      return _CollectionSelectableItemCard(
                        item: item,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedItemIds.remove(item.id);
                            } else {
                              _selectedItemIds.add(item.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _saveCollection(
                            context,
                            collectionId: collectionId,
                            isEditMode: isEditMode,
                          ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEditMode
                                ? 'Update Collection'
                                : 'Create Collection',
                          ),
                  ),
                ),
                if (isEditMode) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _confirmDelete(context, collectionId),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Collection'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCollection(
    BuildContext context, {
    required String? collectionId,
    required bool isEditMode,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a collection name')),
      );
      return;
    }

    if (_selectedItemIds.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select at least one wardrobe item')),
      );
      return;
    }

    final collectionViewModel = Provider.of<CollectionViewModel>(
      context,
      listen: false,
    );
    final duplicate = collectionViewModel.collections.any((collection) {
      if (isEditMode && collection.id == collectionId) {
        return false;
      }
      return collection.name.toLowerCase() == name.toLowerCase();
    });

    if (duplicate) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Collection name already exists')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (isEditMode) {
        await collectionViewModel.updateCollection(
          collectionId: collectionId!,
          name: name,
          itemIds: _selectedItemIds.toList(),
        );
      } else {
        await collectionViewModel.createCollection(
          name: name,
          itemIds: _selectedItemIds.toList(),
        );
      }

      if (!mounted) return;
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save collection')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String? collectionId,
  ) async {
    if (collectionId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection?'),
        content: const Text(
          'This removes the collection only. Wardrobe items stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final collectionViewModel = Provider.of<CollectionViewModel>(
        context,
        listen: false,
      );
      await collectionViewModel.deleteCollection(collectionId);

      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete collection')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _CollectionSelectableItemCard extends StatelessWidget {
  final ClothingItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _CollectionSelectableItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? GoldFitTheme.primary
                  : GoldFitTheme.yellow200.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildImage(item)),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? GoldFitTheme.primary
                              : Colors.white.withOpacity(0.85),
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? GoldFitTheme.textDark
                              : GoldFitTheme.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_capitalize(item.color)} ${_formatType(item.type)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: GoldFitTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ClothingItem item) {
    if (item.imageUrl.contains('/')) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        child: LocalImageWidget(imagePath: item.imageUrl, fit: BoxFit.cover),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: GoldFitTheme.tertiary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
      ),
      child: Center(
        child: Icon(
          _iconForType(item.type),
          size: 40,
          color: GoldFitTheme.textMedium,
        ),
      ),
    );
  }

  String _formatType(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
        return 'Top';
      case ClothingType.bottoms:
        return 'Bottom';
      case ClothingType.outerwear:
        return 'Outerwear';
      case ClothingType.shoes:
        return 'Shoes';
      case ClothingType.accessories:
        return 'Accessory';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  IconData _iconForType(ClothingType type) {
    switch (type) {
      case ClothingType.tops:
      case ClothingType.bottoms:
      case ClothingType.outerwear:
        return Icons.checkroom;
      case ClothingType.shoes:
        return Icons.shopping_bag;
      case ClothingType.accessories:
        return Icons.watch;
    }
  }
}
