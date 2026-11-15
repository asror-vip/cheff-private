import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/table_entity.dart';

class TablesRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<List<TableEntity>> streamTables() {
    return _client
        .from('restaurant_tables')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', SupabaseService.currentRestaurantId)
        .order('zone')
        .order('name')
        .map((maps) => maps.map((m) => _fromMap(m)).toList());
  }

  Future<void> updateTableStatus(String tableId, TableStatus status, {String? orderId, String? waiterId}) async {
    // Convert enum back to db-friendly string (e.g. billRequested -> bill_requested)
    String dbStatus = status.name;
    if (status == TableStatus.billRequested) dbStatus = 'bill_requested';
    if (status == TableStatus.outOfService) dbStatus = 'out_of_service';

    final Map<String, dynamic> updates = {
      'status': dbStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (orderId != null) updates['current_order_id'] = orderId;
    if (waiterId != null) updates['assigned_waiter_id'] = waiterId;
    
    if (status == TableStatus.available || status == TableStatus.cleaning) {
       updates['current_order_id'] = null;
       updates['assigned_waiter_id'] = null;
    }

    try {
      await _client.from('restaurant_tables').update(updates).eq('id', tableId);
    } catch (e) {
      // Fallback log
    }
  }

  Future<void> addTable({
    required String name,
    required String zone,
    required int capacity,
  }) async {
    await _client.from('restaurant_tables').insert({
      'restaurant_id': SupabaseService.currentRestaurantId,
      'name': name,
      'zone': zone,
      'capacity': capacity,
      'status': 'available',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addBatchTables({
    required String zone,
    required int startNumber,
    required int count,
    required int capacity,
    String prefix = '',
  }) async {
    final List<Map<String, dynamic>> records = [];
    final now = DateTime.now().toIso8601String();
    final restId = SupabaseService.currentRestaurantId;

    for (int i = 0; i < count; i++) {
      final num = startNumber + i;
      final name = prefix.trim().isEmpty ? '$num-stol' : '$prefix $num';
      records.add({
        'restaurant_id': restId,
        'name': name,
        'zone': zone,
        'capacity': capacity,
        'status': 'available',
        'created_at': now,
        'updated_at': now,
      });
    }

    if (records.isNotEmpty) {
      await _client.from('restaurant_tables').insert(records);
    }
  }

  Future<void> updateTableDetails(
    String tableId, {
    required String name,
    required String zone,
    required int capacity,
  }) async {
    await _client.from('restaurant_tables').update({
      'name': name,
      'zone': zone,
      'capacity': capacity,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tableId);
  }

  Future<void> deleteTable(String tableId) async {
    await _client.from('restaurant_tables').delete().eq('id', tableId);
  }

  TableEntity _fromMap(Map<String, dynamic> map) {
    String statusStr = map['status'] ?? 'available';
    TableStatus ts = TableStatus.available;
    if (statusStr == 'occupied') {
      ts = TableStatus.occupied;
    } else if (statusStr == 'bill_requested') {
      ts = TableStatus.billRequested;
    } else if (statusStr == 'cleaning') {
      ts = TableStatus.cleaning;
    } else if (statusStr == 'out_of_service') {
      ts = TableStatus.outOfService;
    }

    return TableEntity(
      id: map['id'],
      restaurantId: map['restaurant_id'],
      name: map['name'] ?? 'Stol',
      capacity: map['capacity'] ?? 4,
      zone: map['zone'] ?? 'Umumiy',
      status: ts,
      currentOrderId: map['current_order_id'],
      assignedWaiterId: map['assigned_waiter_id'],
    );
  }
}
