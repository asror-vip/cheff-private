import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/product_model.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryRepository {
  final SupabaseClient _client = SupabaseService.client;
  
  Future<List<InventoryItem>> getProducts() async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      
      // Fetch products with stock from SQL view
      final response = await _client
          .from('products_with_stock')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .order('name');
          
      final List<ProductModel> models = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
          
      return models.map((e) => InventoryItem(
        id: e.id,
        name: e.name,
        quantity: e.currentStock,
        unit: e.unit,
        totalValue: e.currentStock * e.averageCost,
        category: e.category,
        isLowStock: e.currentStock <= e.minimumStock,
        isNew: e.isNew,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<InventoryItem> addProduct({
    required String name,
    required String category,
    required String unit,
    required double minimumStock,
    double initialStock = 0,
    double costPrice = 0,
  }) async {
    final restaurantId = SupabaseService.currentRestaurantId;

    // Insert into products table
    final response = await _client.from('products').insert({
      'id': const Uuid().v4(),
      'restaurant_id': restaurantId,
      'name': name,
      'normalized_name': name.toLowerCase(),
      'category': category,
      'unit': unit,
      'minimum_stock': minimumStock,
      'average_cost': costPrice,
      'is_active': true,
    }).select().single();

    final ProductModel newProduct = ProductModel.fromJson(response);
    
    // Insert initial stock movement if quantity > 0
    if (initialStock > 0) {
      await _client.from('stock_movements').insert({
        'id': const Uuid().v4(),
        'restaurant_id': restaurantId,
        'product_id': newProduct.id,
        'quantity': initialStock,
        'unit': unit,
        'type': 'initial_stock',
        'reason': 'Начальный остаток',
      });
    }

    return InventoryItem(
      id: newProduct.id,
      name: newProduct.name,
      quantity: initialStock,
      unit: newProduct.unit,
      totalValue: initialStock * costPrice,
      category: newProduct.category,
      isLowStock: initialStock <= newProduct.minimumStock,
    );
  }

  Future<List<InventoryItem>> addProductsBulk(List<Map<String, dynamic>> products) async {
    final restaurantId = SupabaseService.currentRestaurantId;
    final List<Map<String, dynamic>> productInserts = [];
    final List<Map<String, dynamic>> movementInserts = [];
    final List<InventoryItem> items = [];
    
    for (var p in products) {
      final pid = const Uuid().v4();
      final initialStock = (p['initialStock'] ?? 0.0) as double;
      final costPrice = (p['costPrice'] ?? 0.0) as double;
      
      productInserts.add({
        'id': pid,
        'restaurant_id': restaurantId,
        'name': p['name'],
        'normalized_name': p['name'].toString().toLowerCase(),
        'category': p['category'],
        'unit': p['unit'],
        'minimum_stock': p['minimumStock'] ?? 0.0,
        'average_cost': costPrice,
        'is_active': true,
      });
      
      if (initialStock > 0) {
        movementInserts.add({
          'id': const Uuid().v4(),
          'restaurant_id': restaurantId,
          'product_id': pid,
          'quantity': initialStock,
          'unit': p['unit'],
          'type': 'initial_stock',
          'reason': 'Начальный остаток',
        });
      }
      
      items.add(InventoryItem(
        id: pid,
        name: p['name'],
        quantity: initialStock,
        unit: p['unit'],
        totalValue: initialStock * costPrice,
        category: p['category'],
        isLowStock: initialStock <= (p['minimumStock'] ?? 0.0),
      ));
    }

    if (productInserts.isNotEmpty) {
      await _client.from('products').insert(productInserts);
    }
    
    if (movementInserts.isNotEmpty) {
      await _client.from('stock_movements').insert(movementInserts);
    }

    return items;
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    required String unit,
  }) async {
    await _client.from('products').update({
      'name': name,
      'normalized_name': name.toLowerCase(),
      'category': category,
      'unit': unit,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> clearNewStatus() async {
    final restaurantId = SupabaseService.currentRestaurantId;
    await _client.from('products').update({
      'is_new': false,
    }).eq('restaurant_id', restaurantId).eq('is_new', true);
  }

  Future<void> submitInventoryCount(List<InventoryItem> currentItems, Map<String, double> actualCounts) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      
      // 1. Create inventory_counts record
      final countResponse = await _client.from('inventory_counts').insert({
        'restaurant_id': restaurantId,
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      final countId = countResponse['id'];

      // 2. Create inventory_count_items AND stock_movements
      List<Map<String, dynamic>> countItems = [];
      List<Map<String, dynamic>> movements = [];

      for (var item in currentItems) {
        if (actualCounts.containsKey(item.id)) {
          final double expectedQty = item.quantity;
          final double actualQty = actualCounts[item.id]!;
          final double difference = actualQty - expectedQty;

          countItems.add({
            'inventory_count_id': countId,
            'product_id': item.id,
            'expected_qty': expectedQty,
            'actual_qty': actualQty,
            'difference': difference,
          });

          if (difference != 0) {
            movements.add({
              'restaurant_id': restaurantId,
              'product_id': item.id,
              'quantity': difference,
              'unit': item.unit,
              'type': 'inventory_adjustment',
              'reference_id': countId,
              'reason': 'Reviziya (Farq: $difference ${item.unit})',
            });
          }
        }
      }

      if (countItems.isNotEmpty) {
        await _client.from('inventory_count_items').insert(countItems);
      }
      
      if (movements.isNotEmpty) {
        await _client.from('stock_movements').insert(movements);
      }
    } catch (e) {
      throw Exception('Reviziyani saqlashda xatolik: $e');
    }
  }
}
