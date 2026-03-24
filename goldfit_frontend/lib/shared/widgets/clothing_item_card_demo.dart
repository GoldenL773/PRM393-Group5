import 'package:flutter/material.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/widgets/clothing_item_card.dart';

/// Demo screen to showcase the ClothingItemCard widgets.
/// This is for development and testing purposes only.
class ClothingItemCardDemo extends StatelessWidget {
  const ClothingItemCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final demoItems = _createDemoItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClothingItemCard Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: demoItems.length,
          itemBuilder: (context, index) {
            final item = demoItems[index];
            return ClothingItemCard(
              item: item,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped: ${item.type.name} (${item.color})'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<ClothingItem> _createDemoItems() {
    return [
      ClothingItem(
        id: '1',
        imageUrl: 'placeholder',
        type: ClothingType.tops,
        color: 'blue',
        seasons: [Season.summer],
        price: 29.99,
        usageCount: 5,
        addedDate: DateTime.now(),
      ),
      ClothingItem(
        id: '2',
        imageUrl: 'placeholder',
        type: ClothingType.bottoms,
        color: 'black',
        seasons: [Season.fall, Season.winter],
        price: 49.99,
        usageCount: 10,
        addedDate: DateTime.now(),
      ),
      ClothingItem(
        id: '3',
        imageUrl: 'placeholder',
        type: ClothingType.outerwear,
        color: 'brown',
        seasons: [Season.fall, Season.winter],
        price: 89.99,
        usageCount: 3,
        addedDate: DateTime.now(),
      ),
      ClothingItem(
        id: '4',
        imageUrl: 'placeholder',
        type: ClothingType.shoes,
        color: 'white',
        seasons: [Season.spring, Season.summer],
        price: 59.99,
        usageCount: 8,
        addedDate: DateTime.now(),
      ),
      ClothingItem(
        id: '5',
        imageUrl: 'placeholder',
        type: ClothingType.accessories,
        color: 'red',
        seasons: [Season.spring, Season.summer, Season.fall, Season.winter],
        price: 19.99,
        usageCount: 15,
        addedDate: DateTime.now(),
      ),
      ClothingItem(
        id: '6',
        imageUrl: 'placeholder',
        type: ClothingType.tops,
        color: 'green',
        seasons: [Season.spring],
        price: 34.99,
        usageCount: 2,
        addedDate: DateTime.now(),
      ),
    ];
  }
}
