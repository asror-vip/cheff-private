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

  

  Future<void> fetchTodaySales({bool background = false}) async {
    if (!background && _summary == null) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final data = await _repository.getTodaySalesSummary();
      _summary = data;
    } catch (e) {
      _error = e.toString();
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


}
