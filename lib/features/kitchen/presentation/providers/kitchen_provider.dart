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
      notifyListeners();
    }, onError: (err) {
      debugPrint('Error streaming kitchen items: $err');
      notifyListeners();
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


}
