import 'package:flutter/material.dart';
import '../../domain/entities/table_entity.dart';

class TablesProvider extends ChangeNotifier {
  // Mock data for tables
  List<TableEntity> _tables = [
    TableEntity(id: '1', name: 'Stol 1', capacity: 4, zone: 'Zal 1'),
    TableEntity(id: '2', name: 'Stol 2', capacity: 2, zone: 'Zal 1', status: TableStatus.occupied, currentOrderId: 'ord_01'),
    TableEntity(id: '3', name: 'Stol 3', capacity: 6, zone: 'Zal 1'),
    TableEntity(id: '4', name: 'Stol 4', capacity: 4, zone: 'Zal 1', status: TableStatus.reserved),
    TableEntity(id: '5', name: 'VIP 1', capacity: 8, zone: 'VIP'),
    TableEntity(id: '6', name: 'VIP 2', capacity: 10, zone: 'VIP', status: TableStatus.occupied, currentOrderId: 'ord_02'),
    TableEntity(id: '7', name: 'Terassa 1', capacity: 4, zone: 'Terassa'),
    TableEntity(id: '8', name: 'Terassa 2', capacity: 4, zone: 'Terassa', status: TableStatus.needsCleaning),
  ];

  List<TableEntity> get tables => _tables;
  
  String _selectedZone = 'Barchasi';
  String get selectedZone => _selectedZone;

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

  void updateTableStatus(String tableId, TableStatus newStatus, {String? orderId}) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(
        status: newStatus,
        currentOrderId: orderId,
      );
      notifyListeners();
    }
  }
}
