import 'package:flutter/material.dart';
import '../../../../core/audit/audit_service.dart';
import '../../data/repositories/production_repository.dart';

class ProductionProvider extends ChangeNotifier {
  final ProductionRepository _repository = ProductionRepository();

  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Map<String, dynamic>> get filteredRecipes {
    if (_searchQuery.trim().isEmpty) return _recipes;
    return _recipes.where((r) => 
      r['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }



  // Shopping Cart logic (Recipe ID -> Quantity)
  final Map<String, double> _cart = {};
  Map<String, double> get cart => _cart;

  double getQuantity(String recipeId) => _cart[recipeId] ?? 0.0;

  void increment(String recipeId) {
    _cart[recipeId] = getQuantity(recipeId) + 1;
    notifyListeners();
  }

  void decrement(String recipeId) {
    if (getQuantity(recipeId) > 0) {
      _cart[recipeId] = getQuantity(recipeId) - 1;
      if (_cart[recipeId] == 0) {
        _cart.remove(recipeId);
      }
      notifyListeners();
    }
  }

  int get totalCartItems => _cart.values.fold(0, (sum, item) => sum + item.toInt());

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> fetchRecipes({bool background = false}) async {
    if (!background && _recipes.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _recipes = await _repository.fetchRecipes();
    _sortRecipes();
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void _sortRecipes() {
    _recipes.sort((a, b) {
      final aFav = a['is_favorite'] == true ? 1 : 0;
      final bFav = b['is_favorite'] == true ? 1 : 0;
      if (aFav != bFav) {
        return bFav.compareTo(aFav); // 1 comes before 0
      }
      return a['name'].toString().compareTo(b['name'].toString());
    });
  }

  Future<void> toggleFavorite(String recipeId) async {
    final index = _recipes.indexWhere((r) => r['id'] == recipeId);
    if (index == -1) return;
    
    final currentStatus = _recipes[index]['is_favorite'] == true;
    
    // Optimistic UI update
    _recipes[index]['is_favorite'] = !currentStatus;
    _sortRecipes();
    notifyListeners();
    
    try {
      await _repository.toggleFavorite(recipeId, !currentStatus);
    } catch (e) {
      // Revert if error
      _recipes[index]['is_favorite'] = currentStatus;
      _sortRecipes();
      notifyListeners();
    }
  }

  Future<String> submitCart() async {
    if (_cart.isEmpty) return "";
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final cartEntries = _cart.entries.toList();
      final total = totalCartItems;
      
      for (var entry in cartEntries) {
        final recipeId = entry.key;
        final qty = entry.value;
        final recipe = _recipes.firstWhere((r) => r['id'] == recipeId);
        final items = recipe['recipe_items'] as List<dynamic>? ?? [];
        await _repository.produceRecipe(recipeId, recipe['name'], qty, items);
      }
      AuditService().logAction(
        department: 'kitchen',
        action: 'Taom tayyorlandi',
        details: 'Jami $total ta porsiya tayyorlandi va ombordan chegirildi.',
      );
      _cart.clear();
      _isLoading = false;
      notifyListeners();
      return "Muvaffaqiyatli: $total ta porsiya tayyorlandi va ombordan chegirildi.";
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.toString());
    }
  }

}
