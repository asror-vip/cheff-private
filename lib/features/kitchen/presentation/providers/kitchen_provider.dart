import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/kitchen_item_entity.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../data/repositories/kitchen_repository.dart';

class KitchenProvider extends ChangeNotifier {
  final KitchenRepository _repository = KitchenRepository();
  
  List<KitchenItemEntity> _items = [];
  String _currentStation = 'hot_kitchen'; // Oshpaz qaysi planshetdaligi (hozircha qotirilgan)
  
  Timer? _timer;
  StreamSubscription? _subscription;

  List<KitchenItemEntity> get items => _items;

  List<KitchenItemEntity> get pendingItems => _items.where((i) => i.status == OrderItemStatus.sent).toList();
  List<KitchenItemEntity> get cookingItems => _items.where((i) => i.status == OrderItemStatus.cooking).toList();
  List<KitchenItemEntity> get readyItems => _items.where((i) => i.status == OrderItemStatus.ready).toList();

  KitchenProvider() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
    
    // KDS ekran ochilishi bilan faol elementlarni tinglashni boshlaymiz
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    _subscription = _repository.streamKitchenItems(_currentStation).listen((data) {
      _items = data;
      if (_items.isEmpty) {
        _items = _getMockItems();
      }
      notifyListeners();
    }, onError: (err) {
       if (_items.isEmpty) {
        _items = _getMockItems();
        notifyListeners();
      }
    });
  }

  void setStation(String station) {
    _currentStation = station;
    _startListening();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> updateItemStatus(String itemId, OrderItemStatus newStatus) async {
    // Optimistic UI Update
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(status: newStatus);
      notifyListeners();
    }
    await _repository.updateItemStatus(itemId, newStatus);
  }

  Future<void> rejectItem(String itemId, String reason) async {
    // Oshpaz mahsulot tugaganida yoki qabul qila olmaganida rad etadi
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items.removeAt(index);
      notifyListeners();
    }
    await _repository.rejectItem(itemId, reason);
  }

  List<KitchenItemEntity> _getMockItems() {
    final now = DateTime.now();
    return [
      KitchenItemEntity(
        id: '1', orderId: 'ord1', recipeId: 'r1', name: 'Ribay Steyk', quantity: 2, 
        status: OrderItemStatus.sent, comment: 'Yaxshi pishsin', station: 'hot_kitchen', 
        createdAt: now.subtract(const Duration(minutes: 5)), tableName: 'Stol 5', assignedWaiterId: 'w1', orderNumber: '101'
      ),
      KitchenItemEntity(
        id: '2', orderId: 'ord1', recipeId: 'r2', name: 'Moxito', quantity: 1, 
        status: OrderItemStatus.cooking, comment: 'Muzsiz', station: 'hot_kitchen', 
        createdAt: now.subtract(const Duration(minutes: 12)), tableName: 'Stol 5', assignedWaiterId: 'w1', orderNumber: '101'
      ),
      KitchenItemEntity(
        id: '3', orderId: 'ord2', recipeId: 'r3', name: 'Tovuqli Sho\'rva', quantity: 1, 
        status: OrderItemStatus.ready, comment: '', station: 'hot_kitchen', 
        createdAt: now.subtract(const Duration(minutes: 18)), tableName: 'Terassa 1', assignedWaiterId: 'w2', orderNumber: '102'
      ),
    ];
  }
}
