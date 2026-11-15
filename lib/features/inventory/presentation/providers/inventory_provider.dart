import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/audit/audit_service.dart';
import '../../domain/entities/inventory_item.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();
  InventoryRepository get repository => _repository;
  
  List<InventoryItem> _items = [];
  List<InventoryItem> get items => _items;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  

  Future<void> fetchInventory({bool background = false}) async {
    if (!background && _items.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final data = await _repository.getProducts();
      _items = data;
    } catch (e) {
      _error = e.toString();
    }
    
    if (!background) {
      _isLoading = false;
      notifyListeners();
    } else {
      // Even if background, we notify to update the UI with new data
      notifyListeners();
    }
    
    // Clear NEW tags in the database so they disappear next time
    if (_items.any((item) => item.isNew)) {
      _repository.clearNewStatus().catchError((e) => debugPrint('Failed to clear new status: $e'));
    }
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required String unit,
    required double minimumStock,
    double initialStock = 0,
    double costPrice = 0,
    bool isSemiFinished = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItem = await _repository.addProduct(
        name: name,
        category: category,
        unit: unit,
        minimumStock: minimumStock,
        initialStock: initialStock,
        isSemiFinished: isSemiFinished,
        costPrice: costPrice,
      );
      
      _items.add(newItem);
      AuditService().logAction(
        department: 'warehouse',
        action: 'Omborga mahsulot qo`shildi',
        details: '$name ($category) qo`shildi. Boshlang`ich qoldiq: $initialStock $unit.',
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProductsBulk(List<Map<String, dynamic>> products) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newItems = await _repository.addProductsBulk(products);
      _items.addAll(newItems);
      AuditService().logAction(
        department: 'warehouse',
        action: 'Ommaviy mahsulot kirimi',
        details: '${products.length} ta mahsulot omborga kiritildi.',
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    required String unit,
  }) async {
    try {
      await _repository.updateProduct(id: id, name: name, category: category, unit: unit);
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final old = _items[index];
        _items[index] = InventoryItem(
          id: old.id,
          name: name,
          category: category,
          unit: unit,
          quantity: old.quantity,
          totalValue: old.totalValue,
          isLowStock: old.isLowStock,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }


}
