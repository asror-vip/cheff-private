class IngredientOption {
  final String id;
  final String name;
  final String unit;
  final double currentQuantity;
  final double averageCost;

  IngredientOption({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.averageCost,
  });

  factory IngredientOption.fromJson(Map<String, dynamic> json) {
    return IngredientOption(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String? ?? 'kg',
      currentQuantity: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      averageCost: (json['average_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
