enum AgentActionType {
  produce,
  expense,
  waste,
  stockQuery,
  salesQuery,
  lowStockQuery,
  financeQuery,
  none,
}

class AgentActionEntity {
  final AgentActionType type;
  final String title;
  final String target;
  final double quantity;
  final String unit;
  final String details;
  final bool isSuccess;
  final String? errorMessage;
  final List<String> impactedItems;

  const AgentActionEntity({
    required this.type,
    required this.title,
    required this.target,
    this.quantity = 0.0,
    this.unit = '',
    required this.details,
    this.isSuccess = true,
    this.errorMessage,
    this.impactedItems = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'target': target,
      'quantity': quantity,
      'unit': unit,
      'details': details,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'impactedItems': impactedItems,
    };
  }

  factory AgentActionEntity.fromMap(Map<String, dynamic> map) {
    return AgentActionEntity(
      type: AgentActionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AgentActionType.none,
      ),
      title: map['title'] ?? '',
      target: map['target'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      details: map['details'] ?? '',
      isSuccess: map['isSuccess'] ?? true,
      errorMessage: map['errorMessage'],
      impactedItems: List<String>.from(map['impactedItems'] ?? []),
    );
  }
}
