import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/table_entity.dart';
import '../../data/repositories/tables_repository.dart';
import '../../../../core/session/session_manager.dart';

class TablesProvider extends ChangeNotifier {
  final TablesRepository _repository = TablesRepository();
  
  List<TableEntity> _tables = [];
  List<TableEntity> get tables => _tables;
  
  String _selectedZone = 'Barchasi';
  String get selectedZone => _selectedZone;

  StreamSubscription? _subscription;

  TablesProvider() {
    _subscription = _repository.streamTables().listen((data) {
      _tables = data;
      if (_tables.isEmpty) {
        _tables = _getMockTables();
      }
      notifyListeners();
    }, onError: (err) {
      if (_tables.isEmpty) {
         _tables = _getMockTables();
         notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<String> get zones {
    final Set<String> uniqueZones = {'Barchasi'};
    for (var t in _tables) {
      uniqueZones.add(t.zone);
    }
    return uniqueZones.toList();
  }

  List<TableEntity> get filteredTables {
    if (_selectedZone == 'Barchasi') return _tables;
    return _tables.where((t) => t.zone == _selectedZone).toList();
  }

  void setZone(String zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  Future<void> updateTableStatus(String tableId, TableStatus newStatus, {String? orderId, String? waiterId}) async {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(
        status: newStatus,
        currentOrderId: newStatus == TableStatus.available ? null : (orderId ?? _tables[index].currentOrderId),
        assignedWaiterId: newStatus == TableStatus.available ? null : (waiterId ?? _tables[index].assignedWaiterId),
      );
      notifyListeners();
    }
    await _repository.updateTableStatus(tableId, newStatus, orderId: orderId, waiterId: waiterId);
  }

  Future<void> addTable({
    required String name,
    required String zone,
    required int capacity,
  }) async {
    await _repository.addTable(name: name, zone: zone, capacity: capacity);
  }

  Future<void> addBatchTables({
    required String zone,
    required int startNumber,
    required int count,
    required int capacity,
    String prefix = '',
  }) async {
    await _repository.addBatchTables(
      zone: zone,
      startNumber: startNumber,
      count: count,
      capacity: capacity,
      prefix: prefix,
    );
  }

  Future<void> updateTableDetails(
    String tableId, {
    required String name,
    required String zone,
    required int capacity,
  }) async {
    await _repository.updateTableDetails(
      tableId,
      name: name,
      zone: zone,
      capacity: capacity,
    );
  }

  Future<void> deleteTable(String tableId) async {
    await _repository.deleteTable(tableId);
  }

  List<TableEntity> _getMockTables() {
    return [
      TableEntity(id: '1', restaurantId: '1', name: 'Stol 1', capacity: 4, zone: 'Zal 1'),
      TableEntity(id: '2', restaurantId: '1', name: 'Stol 2', capacity: 2, zone: 'Zal 1', status: TableStatus.occupied, currentOrderId: 'ord_01', assignedWaiterId: SessionManager().currentEmployee?.id),
      TableEntity(id: '3', restaurantId: '1', name: 'Stol 3', capacity: 6, zone: 'Zal 1'),
      TableEntity(id: '4', restaurantId: '1', name: 'Stol 4', capacity: 4, zone: 'Zal 1', status: TableStatus.billRequested),
      TableEntity(id: '5', restaurantId: '1', name: 'VIP 1', capacity: 8, zone: 'VIP'),
      TableEntity(id: '6', restaurantId: '1', name: 'VIP 2', capacity: 10, zone: 'VIP', status: TableStatus.occupied, currentOrderId: 'ord_02'),
      TableEntity(id: '7', restaurantId: '1', name: 'Terassa 1', capacity: 4, zone: 'Terassa'),
      TableEntity(id: '8', restaurantId: '1', name: 'Terassa 2', capacity: 4, zone: 'Terassa', status: TableStatus.cleaning),
    ];
  }
}
