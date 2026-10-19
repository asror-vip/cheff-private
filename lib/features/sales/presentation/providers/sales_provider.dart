import 'package:flutter/material.dart';
import '../../domain/entities/sales_summary.dart';
import '../../data/repositories/sales_repository.dart';

class SalesProvider extends ChangeNotifier {
  final SalesRepository _repository = SalesRepository();
  
  SalesSummary? _summary;
  SalesSummary? get summary => _summary;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  final bool _useMockData = false;

  Future<void> fetchTodaySales({bool background = false}) async {
    if (!background && _summary == null) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final data = await _repository.getTodaySalesSummary();
      if (data.totalReceipts == 0 && _useMockData) {
        _summary = _getMockSummary();
      } else {
        _summary = data;
      }
    } catch (e) {
      _error = e.toString();
      if (_useMockData) {
         _summary = _getMockSummary();
      }
    }
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> fetchSalesByRange(DateTime start, DateTime end, {bool background = false}) async {
    if (!background) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _repository.getSalesSummaryByRange(start, end);
      _summary = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (_isLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  SalesSummary _getMockSummary() {
    return SalesSummary(
      totalRevenue: 1250000,
      previousRevenue: 1086956, // to get +15%
      totalReceipts: 45,
      averageReceipt: 27000,
      topDishes: [
        TopDish(name: 'Pasta Karbonara', portions: 15, sum: 225000),
        TopDish(name: 'Steyk Ribay', portions: 8, sum: 960000),
        TopDish(name: 'Salat Sezar', portions: 12, sum: 144000),
      ]
    );
  }
}
