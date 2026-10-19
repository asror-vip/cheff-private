class SalesModel {
  final String id;
  final String restaurantId;
  final String? orderId;
  final String paymentMethod;
  final double amount;
  final DateTime date;

  SalesModel({
    required this.id,
    required this.restaurantId,
    this.orderId,
    required this.paymentMethod,
    required this.amount,
    required this.date,
  });

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['created_at'];
    return SalesModel(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      orderId: json['order_id']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      amount: (json['total_amount'] ?? json['amount'] ?? 0).toDouble(),
      date: DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
