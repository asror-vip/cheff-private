import '../../../orders/domain/entities/order_entity.dart';

// KDS da faqat ovqatlar darajasida (Item level) ko'rsatish uchun entity.
// Bu to'g'ridan-to'g'ri OrderItemEntity dagi sent, cooking, ready stauslarga bog'lanadi.

class KitchenItemEntity {
  final String id;
  final String orderId;
  final String recipeId;
  final String name;
  final int quantity;
  final OrderItemStatus status;
  final String comment;
  final String station;
  final DateTime createdAt;
  
  // Qo'shimcha UI uchun ma'lumotlar
  final String tableName;
  final String assignedWaiterId;
  final String orderNumber;

  KitchenItemEntity({
    required this.id,
    required this.orderId,
    required this.recipeId,
    required this.name,
    required this.quantity,
    required this.status,
    required this.comment,
    required this.station,
    required this.createdAt,
    required this.tableName,
    required this.assignedWaiterId,
    required this.orderNumber,
  });

  KitchenItemEntity copyWith({
    String? id,
    String? orderId,
    String? recipeId,
    String? name,
    int? quantity,
    OrderItemStatus? status,
    String? comment,
    String? station,
    DateTime? createdAt,
    String? tableName,
    String? assignedWaiterId,
    String? orderNumber,
  }) {
    return KitchenItemEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      station: station ?? this.station,
      createdAt: createdAt ?? this.createdAt,
      tableName: tableName ?? this.tableName,
      assignedWaiterId: assignedWaiterId ?? this.assignedWaiterId,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }
}
