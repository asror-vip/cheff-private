class TransactionCategory {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'

  TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final TransactionCategory? category;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    TransactionCategory? cat;
    if (json['transaction_categories'] != null) {
      cat = TransactionCategory.fromJson(json['transaction_categories']);
    }
    return TransactionModel(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      category: cat,
    );
  }
}
