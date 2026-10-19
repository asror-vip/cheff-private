import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/recipe_item_entity.dart';

class RecipeModel {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double sellingPrice;
  final double outputQuantity;
  final String outputUnit;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // We can attach joined items
  final List<RecipeItemModel> items;

  RecipeModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.sellingPrice,
    required this.outputQuantity,
    required this.outputUnit,
    required this.isActive,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <RecipeItemModel>[];
    if (json['recipe_items'] != null) {
      itemsList = (json['recipe_items'] as List)
          .map((i) => RecipeItemModel.fromJson(i))
          .toList();
    }

    return RecipeModel(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'],
      description: json['description'],
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      outputQuantity: (json['output_quantity'] ?? 0).toDouble(),
      outputUnit: json['output_unit'] ?? 'g',
      isActive: json['is_active'] ?? true,
      imageUrl: json['image_url'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      items: itemsList,
    );
  }

  RecipeEntity toEntity() {
    List<RecipeItemEntity> recipeItems = [];

    for (var item in items) {
      double itemPrice = item.productPrice; 
      
      recipeItems.add(
        RecipeItemEntity(
          id: item.id,
          recipeId: item.recipeId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unit: item.unit,
          productPrice: itemPrice,
        ),
      );
    }

    String parsedCategory = 'Asosiy';
    String cleanDescription = '';
    if (description != null) {
      if (description!.startsWith('Category: ')) {
        final parts = description!.split('\n---\n');
        parsedCategory = parts[0].replaceFirst('Category: ', '').trim();
        if (parts.length > 1) {
          cleanDescription = parts.sublist(1).join('\n---\n');
        }
      } else {
        cleanDescription = description!;
      }
    }

    return RecipeEntity(
      id: id,
      name: name,
      category: parsedCategory,
      description: cleanDescription.isEmpty ? null : cleanDescription,
      sellingPrice: sellingPrice,
      outputQuantity: outputQuantity,
      outputUnit: outputUnit,
      isActive: isActive,
      imageUrl: imageUrl,
      items: recipeItems,
    );
  }
}

class RecipeItemModel {
  final String id;
  final String recipeId;
  final String productId;
  final double quantity;
  final String unit;
  
  // Joined fields from 'products' table
  final String productName;
  final double productPrice;

  RecipeItemModel({
    required this.id,
    required this.recipeId,
    required this.productId,
    required this.quantity,
    required this.unit,
    this.productName = '',
    this.productPrice = 0.0,
  });

  factory RecipeItemModel.fromJson(Map<String, dynamic> json) {
    // Handling joined product data if available
    String pName = 'Unknown Product';
    double pPrice = 0.0; // In reality, price comes from latest purchase or standard cost
    
    if (json['products'] != null) {
      pName = json['products']['name'] ?? pName;
      pPrice = (json['products']['average_cost'] as num?)?.toDouble() ?? 0.0;
    }

    return RecipeItemModel(
      id: json['id'],
      recipeId: json['recipe_id'],
      productId: json['product_id'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'g',
      productName: pName,
      productPrice: pPrice,
    );
  }
}
