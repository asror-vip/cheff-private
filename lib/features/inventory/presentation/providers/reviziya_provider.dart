import 'package:flutter/foundation.dart';
import '../providers/inventory_provider.dart';

class ReviziyaProvider with ChangeNotifier {
  final InventoryProvider _inventoryProvider;
  
  ReviziyaProvider(this._inventoryProvider);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final Map<String, double> _actualCounts = {};
  Map<String, double> get actualCounts => _actualCounts;

  void setActualCount(String productId, double count) {
    _actualCounts[productId] = count;
    notifyListeners();
  }

  void clearCounts() {
    _actualCounts.clear();
    notifyListeners();
  }

  Future<bool> submitReviziya() async {
    if (_actualCounts.isEmpty) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = _inventoryProvider.items;
      await _inventoryProvider.repository.submitInventoryCount(items, _actualCounts);
      
      // Refresh inventory after successful reviziya
      await _inventoryProvider.fetchInventory();
      
      clearCounts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
