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

  final bool _useMockData = false;

  Future<void> fetchInventory({bool background = false}) async {
    if (!background && _items.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final data = await _repository.getProducts();
      if (data.isEmpty && _useMockData) {
        _items = _getMockInventory();
      } else {
        _items = data;
      }
    } catch (e) {
      _error = e.toString();
      if (_useMockData) {
         _items = _getMockInventory();
      }
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

  List<InventoryItem> _getMockInventory() {
    return [
      InventoryItem(
        id: '1',
        name: 'Mol go\'shti (Ribay)',
        category: 'Go\'sht',
        quantity: 12.5,
        unit: 'kg',
        totalValue: 1125000,
        isLowStock: false,
      ),
      InventoryItem(
        id: '2',
        name: 'Qaymoq 33%',
        category: 'Sut mahsulotlari',
        quantity: 5.0,
        unit: 'litr',
        totalValue: 225000,
        isLowStock: true,
      ),
      InventoryItem(
        id: '3',
        name: 'Cherri pomidor',
        category: 'Sabzavotlar',
        quantity: 3.2,
        unit: 'kg',
        totalValue: 112000,
        isLowStock: true,
      ),
      InventoryItem(
        id: '4',
        name: 'Bug\'doy uni',
        category: 'Quruq mahsulotlar',
        quantity: 50.0,
        unit: 'kg',
        totalValue: 400000,
        isLowStock: false,
      ),
      InventoryItem(
        id: '5',
        name: 'Zaytun moyi',
        category: 'Yog\'lar',
        quantity: 4.5,
        unit: 'litr',
        totalValue: 540000,
        isLowStock: true,
      ),
    ];
  }
}
