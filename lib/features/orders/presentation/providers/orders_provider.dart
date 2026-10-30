import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/order_entity.dart';
import '../../data/repositories/orders_repository.dart';
import '../../../tables/domain/entities/table_entity.dart';
import '../../../tables/presentation/providers/tables_provider.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/network/supabase_service.dart';

class OrdersProvider extends ChangeNotifier {
  final OrdersRepository _repository = OrdersRepository();
  final _uuid = const Uuid();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  OrderEntity? _currentOrder;
  OrderEntity? get currentOrder => _currentOrder;

  StreamSubscription? _orderItemsSub;

  @override
  void dispose() {
    _orderItemsSub?.cancel();
    super.dispose();
  }

  Future<void> openOrderForTable(TableEntity table, TablesProvider tablesProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = SessionManager();
      final currentUserId = session.currentEmployee?.id ?? session.bossProfile.id;
      
      if (table.status == TableStatus.available) {
        final newOrderId = _uuid.v4();
        _currentOrder = OrderEntity(
          id: newOrderId,
          restaurantId: SupabaseService.currentRestaurantId,
          tableId: table.id,
          tableName: table.name,
          assignedWaiterId: currentUserId,
          createdAt: DateTime.now(),
        );

        await _repository.createOrder(_currentOrder!);
        await tablesProvider.updateTableStatus(table.id, TableStatus.occupied, orderId: newOrderId, waiterId: currentUserId);
      } else {
        // Band stol, uning ID sini olib buyurtmani tiklaymiz
        _currentOrder = OrderEntity(
          id: table.currentOrderId ?? _uuid.v4(),
          restaurantId: SupabaseService.currentRestaurantId,
          tableId: table.id,
          tableName: table.name,
          assignedWaiterId: table.assignedWaiterId ?? currentUserId,
          createdAt: DateTime.now(),
        );
      }

      // Realtime listener for order items
      _orderItemsSub?.cancel();
      _orderItemsSub = _repository.streamOrderItems(_currentOrder!.id).listen((items) {
        if (_currentOrder != null) {
          // Boshqa barcha eski propertylarni saqlab faqat items larni yangilaymiz.
          // Ammo o'zimizning hali jo'natilmagan draft savatimizdagi ovqatlarni ham ustiga qo'shishimiz kerak
          final draftItems = _currentOrder!.items.where((i) => i.status == OrderItemStatus.draft).toList();
          final allItems = [...items, ...draftItems];

          _currentOrder = OrderEntity(
            id: _currentOrder!.id,
            restaurantId: _currentOrder!.restaurantId,
            tableId: _currentOrder!.tableId,
            tableName: _currentOrder!.tableName,
            assignedWaiterId: _currentOrder!.assignedWaiterId,
            type: _currentOrder!.type,
            status: _currentOrder!.status,
            items: allItems,
            createdAt: _currentOrder!.createdAt,
            serviceFeePercentage: _currentOrder!.serviceFeePercentage,
          );
          notifyListeners();
        }
      });
      
      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _error = "Buyurtma ochishda xatolik: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  void addDraftItem({
    required String recipeId,
    required String name,
    required double price,
    required String station,
    int quantity = 1,
  }) {
    if (_currentOrder == null) return;

    final existingIndex = _currentOrder!.items.indexWhere((i) => i.recipeId == recipeId && i.status == OrderItemStatus.draft);
    List<OrderItemEntity> updatedItems = List.from(_currentOrder!.items);

    if (existingIndex != -1) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      updatedItems.add(
        OrderItemEntity(
          id: _uuid.v4(),
          orderId: _currentOrder!.id,
          recipeId: recipeId,
          name: name,
          quantity: quantity,
          price: price,
          station: station,
          status: OrderItemStatus.draft,
          createdAt: DateTime.now(),
        ),
      );
    }

    _currentOrder = OrderEntity(
      id: _currentOrder!.id,
      restaurantId: _currentOrder!.restaurantId,
      tableId: _currentOrder!.tableId,
      tableName: _currentOrder!.tableName,
      assignedWaiterId: _currentOrder!.assignedWaiterId,
      items: updatedItems,
      createdAt: _currentOrder!.createdAt,
    );
    notifyListeners();
  }

  void updateDraftItemQuantity(String itemId, int delta) {
    if (_currentOrder == null) return;
    
    List<OrderItemEntity> updatedItems = List.from(_currentOrder!.items);
    final index = updatedItems.indexWhere((i) => i.id == itemId && i.status == OrderItemStatus.draft);
    
    if (index != -1) {
      final item = updatedItems[index];
      final newQty = item.quantity + delta;
      
      if (newQty <= 0) {
        updatedItems.removeAt(index);
      } else {
        updatedItems[index] = item.copyWith(quantity: newQty);
      }

      _currentOrder = OrderEntity(
        id: _currentOrder!.id,
        restaurantId: _currentOrder!.restaurantId,
        tableId: _currentOrder!.tableId,
        tableName: _currentOrder!.tableName,
        assignedWaiterId: _currentOrder!.assignedWaiterId,
        items: updatedItems,
        createdAt: _currentOrder!.createdAt,
      );
      notifyListeners();
    }
  }

  Future<bool> sendDraftsToKitchen() async {
    if (_currentOrder == null) return false;

    final draftItems = _currentOrder!.items.where((i) => i.status == OrderItemStatus.draft).toList();
    if (draftItems.isEmpty) return true;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idempotencyKey = _uuid.v4(); 
      await _repository.submitOrderItems(
        orderId: _currentOrder!.id,
        newItems: draftItems,
        idempotencyKey: idempotencyKey,
      );

      // Local optimistic update
      final updatedItems = _currentOrder!.items.map((item) {
        if (item.status == OrderItemStatus.draft) {
          return item.copyWith(status: OrderItemStatus.sent);
        }
        return item;
      }).toList();

      _currentOrder = OrderEntity(
        id: _currentOrder!.id,
        restaurantId: _currentOrder!.restaurantId,
        tableId: _currentOrder!.tableId,
        tableName: _currentOrder!.tableName,
        assignedWaiterId: _currentOrder!.assignedWaiterId,
        items: updatedItems,
        createdAt: _currentOrder!.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = "Oshxonaga yuborishda xatolik: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void exitOrder() {
    _orderItemsSub?.cancel();
    _currentOrder = null;
    notifyListeners();
  }
}
