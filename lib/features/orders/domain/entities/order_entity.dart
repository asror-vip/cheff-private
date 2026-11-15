// ignore_for_file: constant_identifier_names

enum OrderStatus {
  open,              // Faol hisob
  in_progress,       // Oshxonaga ketgan
  ready_for_payment, // Tayyor / Pre-chek yopilgan
  partially_paid,    // Qisman to'langan
  paid,              // To'liq yopilgan
  cancelled          // Bekor qilingan
}

enum OrderItemStatus {
  draft,     // Ofitsiant savatida, hali jo'natilmagan
  sent,      // Oshxonaga yuborilgan
  cooking,   // Pishirilmoqda
  ready,     // Tayyor
  served,    // Tortildi
  cancelled, // O'chirilgan/Bekor qilingan
  rejected   // Oshxona rad etgan (Tugagan)
}

enum OrderType {
  dine_in,
  takeaway,
  delivery
}

class OrderItemEntity {
  final String id;
  final String orderId;
  final String recipeId;
  final String name;
  final int quantity;
  final double price;
  final OrderItemStatus status;
  final String comment;
  final String station; // hot_kitchen, cold_kitchen, bar, none
  final DateTime createdAt;

  OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.recipeId,
    required this.name,
    required this.quantity,
    required this.price,
    this.status = OrderItemStatus.draft,
    this.comment = '',
    this.station = 'none',
    required this.createdAt,
  });

  OrderItemEntity copyWith({
    String? id,
    String? orderId,
    String? recipeId,
    String? name,
    int? quantity,
    double? price,
    OrderItemStatus? status,
    String? comment,
    String? station,
    DateTime? createdAt,
  }) {
    return OrderItemEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      station: station ?? this.station,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OrderEntity {
  final String id;
  final String restaurantId;
  final String? tableId;
  final String? tableName;
  final String assignedWaiterId;
  final OrderType type;
  final OrderStatus status;
  final List<OrderItemEntity> items; // Barcha taomlar zanjiri
  final DateTime createdAt;
  final double serviceFeePercentage;

  OrderEntity({
    required this.id,
    required this.restaurantId,
    this.tableId,
    this.tableName,
    required this.assignedWaiterId,
    this.type = OrderType.dine_in,
    this.status = OrderStatus.open,
    this.items = const [],
    required this.createdAt,
    this.serviceFeePercentage = 10.0,
  });
  
  List<OrderItemEntity> get activeItems => items.where((i) => i.status != OrderItemStatus.cancelled && i.status != OrderItemStatus.rejected).toList();
  
  double get subtotal => activeItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get serviceFee => type == OrderType.dine_in ? (subtotal * serviceFeePercentage / 100) : 0;
  double get total => subtotal + serviceFee;
}
