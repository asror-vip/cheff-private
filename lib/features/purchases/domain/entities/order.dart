enum OrderStatus {
  active,
  delivered,
  cancelled,
}

class PurchaseOrder {
  final String id;
  final String supplierName;
  final String date;
  final double totalAmount;
  final OrderStatus status;
  final int itemsCount;

  PurchaseOrder({
    required this.id,
    required this.supplierName,
    required this.date,
    required this.totalAmount,
    required this.status,
    this.itemsCount = 0,
  });
}
