import 'package:flutter/foundation.dart';
import '../../../../core/audit/audit_service.dart';
import '../../data/repositories/pos_repository.dart';

class PosProvider with ChangeNotifier {
  final PosRepository _repository = PosRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> get recipes => _recipes;

  // Cart: recipe_id -> Map of details
  final Map<String, Map<String, dynamic>> _cart = {};
  Map<String, Map<String, dynamic>> get cart => _cart;

  Future<void> fetchRecipes({bool background = false}) async {
    if (!background && _recipes.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _recipes = await _repository.fetchRecipes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void addToCart(Map<String, dynamic> recipe) {
    final id = recipe['id'];
    if (_cart.containsKey(id)) {
      _cart[id]!['quantity'] += 1;
    } else {
      _cart[id] = {
        'recipe_id': id,
        'name': recipe['name'],
        'price': (recipe['selling_price'] ?? 0).toDouble(),
        'quantity': 1,
      };
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    if (_cart.containsKey(id)) {
      if (_cart[id]!['quantity'] > 1) {
        _cart[id]!['quantity'] -= 1;
      } else {
        _cart.remove(id);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get totalAmount {
    double total = 0;
    for (var item in _cart.values) {
      total += item['quantity'] * item['price'];
    }
    return total;
  }

  Future<bool> checkout() async {
    if (_cart.isEmpty) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = _cart.values.toList();
      final currentTotal = totalAmount;
      await _repository.checkout(items, currentTotal);

      final summary = items.map((i) => '${i['name']} x${i['quantity']}').join(', ');
      AuditService().logAction(
        department: 'pos',
        action: 'POS Savdo cheki',
        details: 'Chek yopildi. Jami: ${currentTotal.toStringAsFixed(0)} so`m ($summary).',
      );

      clearCart();
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
