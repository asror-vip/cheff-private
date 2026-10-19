enum TableStatus {
  available,
  occupied,
  reserved,
  needsCleaning
}

class TableEntity {
  final String id;
  final String name;
  final int capacity;
  final String zone; // e.g., 'Zal 1', 'VIP', 'Terassa'
  final TableStatus status;
  final String? currentOrderId; // If occupied, which order is attached

  TableEntity({
    required this.id,
    required this.name,
    required this.capacity,
    required this.zone,
    this.status = TableStatus.available,
    this.currentOrderId,
  });

  TableEntity copyWith({
    String? id,
    String? name,
    int? capacity,
    String? zone,
    TableStatus? status,
    String? currentOrderId,
  }) {
    return TableEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      zone: zone ?? this.zone,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }
}
