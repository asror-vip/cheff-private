class ExpenseCategory {
  final String name;
  final double amount;

  ExpenseCategory({
    required this.name,
    required this.amount,
  });
}

class FinanceSummary {
  final double revenue;
  final double revenueChange;
  
  final double expenses;
  final double expensesChange;
  
  final double profit;
  final double profitChange;
  
  final double margin; // percentage
  final double marginChange;
  
  final double foodCost;
  final double purchasesTotal;
  final List<ExpenseCategory> expenseCategories;

  FinanceSummary({
    required this.revenue,
    required this.revenueChange,
    required this.expenses,
    required this.expensesChange,
    required this.profit,
    required this.profitChange,
    required this.margin,
    required this.marginChange,
    this.foodCost = 0.0,
    this.purchasesTotal = 0.0,
    this.expenseCategories = const [],
  });
}
