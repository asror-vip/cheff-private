class InventoryItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double totalValue;
  final String category;
  final bool isLowStock;
  final bool isNew;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.totalValue,
    required this.category,
    this.isLowStock = false,
    this.isNew = false,
  });
}
