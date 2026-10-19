import 'recipe_item_entity.dart';

class RecipeEntity {
  final String id;
  final String name;
  final String category;
  final String? description;
  final double sellingPrice;
  final double outputQuantity;
  final String outputUnit;
  final bool isActive;
  final String? imageUrl;
  final List<RecipeItemEntity> items;

  RecipeEntity({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.sellingPrice,
    required this.outputQuantity,
    required this.outputUnit,
    required this.isActive,
    this.imageUrl,
    required this.items,
  });

  double get costPrice {
    double total = 0;
    for (var item in items) {
      total += item.sum;
    }
    return total;
  }

  double get foodcostPercentage {
    if (sellingPrice == 0) return 0.0;
    return (costPrice / sellingPrice) * 100;
  }
}
