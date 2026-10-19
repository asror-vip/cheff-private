class RecipeItemEntity {
  final String id;
  final String recipeId;
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double productPrice;

  RecipeItemEntity({
    required this.id,
    required this.recipeId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.productPrice,
  });

  double get sum => quantity * productPrice;
}
