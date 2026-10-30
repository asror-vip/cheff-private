import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../domain/entities/kitchen_item_entity.dart';

class KitchenRepository {
  final SupabaseClient _client = SupabaseService.client;

  // Oshxonadagi barcha faol taomlarni stream qilish
  // Real loyihada order_items va orders larni JOIN qilib view orqali olish tavsiya etiladi.
  Stream<List<KitchenItemEntity>> streamKitchenItems(String station) {
    return _client
        .from('kds_view') // Buni RPC yoki Supabase view qilib olish kerak, hozircha mock view kabi
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', SupabaseService.currentRestaurantId)
        .eq('station', station)
        .neq('status', OrderItemStatus.draft.name)
        .neq('status', OrderItemStatus.served.name)
        .neq('status', OrderItemStatus.cancelled.name)
        .neq('status', OrderItemStatus.rejected.name)
        .map((maps) => maps.map((m) => _fromMap(m)).toList());
  }

  Future<void> updateItemStatus(String itemId, OrderItemStatus newStatus) async {
    try {
      await _client.from('order_items').update({
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (e) {
      // Fallback
    }
  }
  
  Future<void> rejectItem(String itemId, String reason) async {
    try {
      await _client.from('order_items').update({
        'status': OrderItemStatus.rejected.name,
        'cancel_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (e) {
      // Fallback
    }
  }

  KitchenItemEntity _fromMap(Map<String, dynamic> map) {
    return KitchenItemEntity(
      id: map['id'],
      orderId: map['order_id'],
      recipeId: map['recipe_id'],
      name: map['name'] ?? 'Taom',
      quantity: map['quantity'] ?? 1,
      status: OrderItemStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => OrderItemStatus.sent),
      comment: map['comment'] ?? '',
      station: map['station'] ?? 'hot_kitchen',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      tableName: map['table_name'] ?? 'Stol',
      assignedWaiterId: map['assigned_waiter_id'] ?? '',
      orderNumber: map['order_number'] ?? '',
    );
  }
}
