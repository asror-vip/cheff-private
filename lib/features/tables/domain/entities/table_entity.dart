enum TableStatus {
  available,      // Bo'sh
  occupied,       // Band
  billRequested,  // Hisob so'ralgan (Pre-chek chiqarilgan)
  cleaning,       // Tozalanmoqda
  outOfService    // Ishlamaydi
}

class TableEntity {
  final String id;
  final String restaurantId;
  final String name;
  final int capacity;
  final String zone; // Zal 1, Terassa, VIP
  final TableStatus status;
  final String? currentOrderId; // Agar occupied bo'lsa
  final String? assignedWaiterId; // Qaysi ofitsiant javobgar

  TableEntity({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.capacity,
    required this.zone,
    this.status = TableStatus.available,
    this.currentOrderId,
    this.assignedWaiterId,
  });

  TableEntity copyWith({
    String? id,
    String? restaurantId,
    String? name,
    int? capacity,
    String? zone,
    TableStatus? status,
    String? currentOrderId,
    String? assignedWaiterId,
  }) {
    return TableEntity(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      zone: zone ?? this.zone,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      assignedWaiterId: assignedWaiterId ?? this.assignedWaiterId,
    );
  }
}
