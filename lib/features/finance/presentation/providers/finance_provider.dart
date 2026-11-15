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
      _summary = data;
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
