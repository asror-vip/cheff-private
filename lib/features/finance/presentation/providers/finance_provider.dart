import 'package:flutter/material.dart';
import '../../domain/entities/finance_summary.dart';
import '../../data/repositories/finance_repository.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceRepository _repository = FinanceRepository();
  
  FinanceSummary? _summary;
  FinanceSummary? get summary => _summary;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  
  DateTime _currentDate = DateTime.now();
  DateTime get currentDate => _currentDate;

  Future<void> fetchFinance({bool background = false}) async {
    if (!background && _summary == null) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final data = await _repository.getMonthlyFinance(_currentDate.year, _currentDate.month);
      if (data.revenue == 0 && data.expenses == 0) {
        _summary = _getMockSummary();
      } else {
        _summary = data;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void changeDate(DateTime newDate) {
    _currentDate = newDate;
    fetchFinance();
  }

  FinanceSummary _getMockSummary() {
    return FinanceSummary(
      revenue: 125000000,
      revenueChange: 15.0,
      expenses: 85000000,
      expensesChange: -5.0,
      profit: 40000000,
      profitChange: 10.0,
      margin: 32.0,
      marginChange: 2.0,
      expenseCategories: [
        ExpenseCategory(name: 'ФудКост (Продукты)', amount: 18495000),
        ExpenseCategory(name: 'Зарплата', amount: 15000000),
        ExpenseCategory(name: 'Аренда', amount: 12000000),
        ExpenseCategory(name: 'Налоги', amount: 4110000),
        ExpenseCategory(name: 'Boshqa', amount: 6445000),
      ],
    );
  }

  Future<void> addExpense(String category, double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addExpense(category, amount);
      await fetchFinance(); // Refresh
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
