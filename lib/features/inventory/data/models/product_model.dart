class ProductModel {
  final String id;
  final String restaurantId;
  final String name;
  final String? normalizedName;
  final String category;
  final String unit;
  final double minimumStock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // For UI representation of current stock
  final double currentStock;
  final double averageCost;
  final bool isNew;

  ProductModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.normalizedName,
    required this.category,
    required this.unit,
    required this.minimumStock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.currentStock = 0.0,
    this.averageCost = 0.0,
    this.isNew = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'],
      normalizedName: json['normalized_name'],
      category: json['category'] ?? 'Без категории',
      unit: json['unit'] ?? 'dona',
      minimumStock: (json['minimum_stock'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      currentStock: (json['current_stock'] ?? 0).toDouble(), // If we have a view
      averageCost: (json['average_cost'] ?? 0).toDouble(),
      isNew: json['is_new'] ?? false,
    );
  }
}
