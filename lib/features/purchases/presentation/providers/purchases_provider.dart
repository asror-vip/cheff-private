import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/audit/audit_service.dart';
import '../../domain/entities/order.dart';
import '../../data/repositories/purchases_repository.dart';

class PurchasesProvider extends ChangeNotifier {
  final PurchasesRepository _repository = PurchasesRepository();
  
  List<PurchaseOrder> _orders = [];
  List<PurchaseOrder> get orders => _orders;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  

  Future<void> fetchPurchases({bool background = false}) async {
    if (!background && _orders.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final data = await _repository.getPurchases();
      if (data.isEmpty) {
        _orders = _getMockOrders();
      } else {
        _orders = data;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> get suppliers => _suppliers;
  bool _suppliersLoaded = false;

  Future<List<Map<String, dynamic>>> getSuppliers({bool force = false}) async {
    if (!_suppliersLoaded || force) {
      _suppliers = await _repository.getSuppliers();
      _suppliersLoaded = true;
      // notifyListeners(); // optional, but better return it
    }
    return _suppliers;
  }

  Future<void> addSupplier({required String name, required String contactName, required String phone}) async {
    await _repository.addSupplier(name: name, contactName: contactName, phone: phone);
    _suppliersLoaded = false;
    notifyListeners();
  }
  
  Future<void> createRequest(List<Map<String, dynamic>> items, String supplierId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createRequest(items, supplierId);
      AuditService().logAction(
        department: 'purchases',
        action: 'Yangi zayavka yaratildi',
        details: '${items.length} ta tovar bo`yicha xarid buyurtmasi shakllantirildi.',
      );
      await fetchPurchases();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRequest(String orderId, List<Map<String, dynamic>> items, String supplierId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateRequest(orderId, items, supplierId);
      await fetchPurchases();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRequest(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteRequest(orderId);
      _orders.removeWhere((o) => o.id == orderId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  List<PurchaseOrder> _getMockOrders() {
    return [
      PurchaseOrder(
        id: '1',
        supplierName: 'MChJ "Baraka Savdo"',
        date: '2023-10-25',
        totalAmount: 1250000,
        status: OrderStatus.delivered,
        itemsCount: 15,
      ),
      PurchaseOrder(
        id: '2',
        supplierName: 'AgroFarm',
        date: '2023-10-26',
        totalAmount: 840000,
        status: OrderStatus.active,
        itemsCount: 8,
      ),
      PurchaseOrder(
        id: '3',
        supplierName: 'Green World',
        date: '2023-10-27',
        totalAmount: 450000,
        status: OrderStatus.active,
        itemsCount: 5,
      ),
    ];
  }
  Future<void> saveAIPurchase(List<Map<String, dynamic>> items, {File? imageFile, String? existingPurchaseId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveAIPurchase(items, imageFile: imageFile, existingPurchaseId: existingPurchaseId);
      AuditService().logAction(
        department: 'purchases',
        action: 'AI Nakladnoy saqlandi',
        details: '${items.length} ta tovarli nakladnoy AI orqali tizimga kiritildi.',
      );
      await fetchPurchases(); // Refresh list after saving
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPurchaseDetails(String purchaseId) async {
    return await _repository.getPurchaseDetails(purchaseId);
  }

  Future<String?> getPurchaseDocumentUrl(String purchaseId) async {
    return await _repository.getPurchaseDocumentUrl(purchaseId);
  }
}
