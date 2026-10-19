class TopDish {
  final String name;
  final int portions;
  final double sum;

  TopDish({
    required this.name,
    required this.portions,
    required this.sum,
  });
}

class SalesSummary {
  final double totalRevenue;
  final double previousRevenue;
  final int totalReceipts;
  final double averageReceipt;
  final List<TopDish> topDishes;
  final List<double> dailyRevenues;

  SalesSummary({
    required this.totalRevenue,
    required this.previousRevenue,
    required this.totalReceipts,
    required this.averageReceipt,
    this.topDishes = const [],
    this.dailyRevenues = const [],
  });

  double get percentageChange {
    if (previousRevenue == 0) return 100.0;
    return ((totalRevenue - previousRevenue) / previousRevenue) * 100;
  }
}
