enum ShiftStatus {
  open,
  closed
}

class CashierShiftEntity {
  final String id;
  final String restaurantId;
  final String cashierId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final ShiftStatus status;
  
  // Moliyaviy ko'rsatkichlar
  final double initialCash; // Ertalab kassadagi qoldiq (razmenka)
  final double expectedCash; // Kun oxirida tizim hisoblagan naqd pul
  final double expectedCard; // Kun oxirida tizim hisoblagan plastik pul
  final double actualCash; // Kassir qo'li bilan sanab kiritgan naqd pul
  final double difference; // actualCash - expectedCash (Kamomad yoki Ortiqcha)
  final String? note; // Kassir izohi

  CashierShiftEntity({
    required this.id,
    required this.restaurantId,
    required this.cashierId,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    this.status = ShiftStatus.open,
    this.initialCash = 0.0,
    this.expectedCash = 0.0,
    this.expectedCard = 0.0,
    this.actualCash = 0.0,
    this.difference = 0.0,
    this.note,
  });

  CashierShiftEntity copyWith({
    String? id,
    String? restaurantId,
    String? cashierId,
    String? cashierName,
    DateTime? openedAt,
    DateTime? closedAt,
    ShiftStatus? status,
    double? initialCash,
    double? expectedCash,
    double? expectedCard,
    double? actualCash,
    double? difference,
    String? note,
  }) {
    return CashierShiftEntity(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      status: status ?? this.status,
      initialCash: initialCash ?? this.initialCash,
      expectedCash: expectedCash ?? this.expectedCash,
      expectedCard: expectedCard ?? this.expectedCard,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      note: note ?? this.note,
    );
  }
}
