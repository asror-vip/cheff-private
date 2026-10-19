import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/utils/unit_converter.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/order.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_model.dart';
class PurchasesRepository {
  final SupabaseClient _client = SupabaseService.client;
  
  Future<List<PurchaseOrder>> getPurchases() async {
    try {
      final response = await _client
          .from('purchases')
          .select('''
            *,
            suppliers (*),
            purchase_items (
              *,
              products (name)
            )
          ''')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .order('date', ascending: false);
          
      final List<PurchaseModel> models = (response as List)
          .map((json) => PurchaseModel.fromJson(json))
          .toList();
          
      return models.map((e) {
        return PurchaseOrder(
          id: e.id,
          supplierName: e.supplier?.name ?? 'Неизвестный поставщик',
          date: e.date.toString().split(' ')[0], // simple formatting
          totalAmount: e.totalAmount,
          status: e.status == 'completed' ? OrderStatus.delivered : OrderStatus.active,
          itemsCount: e.items.length,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching purchases: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response = await _client
          .from('suppliers')
          .select('id, name, notes, phone')
          .eq('restaurant_id', SupabaseService.currentRestaurantId);
      // Ensure notes is renamed to contact_name in the result if needed
      return List<Map<String, dynamic>>.from(response).map((e) {
        return {
          'id': e['id'],
          'name': e['name'],
          'contact_name': e['notes'] ?? '',
          'phone': e['phone'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
      return [];
    }
  }

  Future<void> addSupplier({required String name, required String contactName, required String phone}) async {
    try {
      await _client.from('suppliers').insert({
        'id': const Uuid().v4(),
        'restaurant_id': SupabaseService.currentRestaurantId,
        'name': name,
        'phone': phone,
        'notes': contactName,
      });
    } catch (e) {
      debugPrint('Error adding supplier: $e');
      rethrow;
    }
  }
  
  Future<void> createRequest(List<Map<String, dynamic>> items, String supplierId) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      final purchaseId = const Uuid().v4();
      
      // Calculate total amount (can be 0 for requests if prices are unknown)
      double totalAmount = 0;
      for (var item in items) {
        totalAmount += (item['quantity'] ?? 0) * (item['price'] ?? 0);
      }
      
      // Fetch products to match or create new ones
      final existingProducts = await _client
          .from('products')
          .select('id, name')
          .eq('restaurant_id', restaurantId);
          
      // Insert into purchases
      await _client.from('purchases').insert({
        'id': purchaseId,
        'restaurant_id': restaurantId,
        'supplier_id': supplierId,
        'date': DateTime.now().toIso8601String(),
        'total_amount': totalAmount,
        'status': 'active', // Active status for unfulfilled requests
      });
      
      // Process items
      final List<Map<String, dynamic>> purchaseItemsToInsert = [];
      for (var item in items) {
        final String itemName = item['name'].toString().trim();
        final double itemQty = (item['quantity'] ?? 0).toDouble();
        final double itemPrice = (item['price'] ?? 0).toDouble();
        final String itemUnit = item['unit'] ?? 'kg';
        
        // Find existing product or create
        var match = existingProducts.firstWhere(
            (p) => p['name'].toString().toLowerCase() == itemName.toLowerCase(),
            orElse: () => {});
            
        String productId;
        if (match.isNotEmpty) {
          productId = match['id'];
        } else {
          productId = const Uuid().v4();
          await _client.from('products').insert({
            'id': productId,
            'restaurant_id': restaurantId,
            'name': itemName,
            'normalized_name': itemName.toLowerCase(),
            'category': 'Разное',
            'unit': itemUnit,
            'minimum_stock': 0,
            'is_active': true,
            'is_new': true,
          });
          existingProducts.add({'id': productId, 'name': itemName, 'unit': itemUnit});
        }
        
        purchaseItemsToInsert.add({
          'id': const Uuid().v4(),
          'purchase_id': purchaseId,
          'product_id': productId,
          'quantity': itemQty,
          'unit': itemUnit,
          'unit_price': itemPrice,
          'total_price': itemQty * itemPrice,
        });
      }

      if (purchaseItemsToInsert.isNotEmpty) {
        await _client.from('purchase_items').insert(purchaseItemsToInsert);
      }
    } catch (e) {
      debugPrint('Error creating request: $e');
      rethrow;
    }
  }
  
  Future<void> updateRequest(String orderId, List<Map<String, dynamic>> items, String supplierId) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      double totalAmount = 0;
      for (var item in items) {
        totalAmount += (item['quantity'] ?? 0) * (item['price'] ?? 0);
      }
      
      await _client.from('purchases').update({
        'supplier_id': supplierId,
        'total_amount': totalAmount,
      }).eq('id', orderId);
      
      await _client.from('purchase_items').delete().eq('purchase_id', orderId);
      
      final existingProducts = await _client.from('products').select('id, name').eq('restaurant_id', restaurantId);
      
      final List<Map<String, dynamic>> purchaseItemsToInsert = [];
      for (var item in items) {
        final String itemName = item['name'].toString().trim();
        final double itemQty = (item['quantity'] ?? 0).toDouble();
        final double itemPrice = (item['price'] ?? 0).toDouble();
        final String itemUnit = item['unit'] ?? 'kg';
        
        var match = existingProducts.firstWhere(
            (p) => p['name'].toString().toLowerCase() == itemName.toLowerCase(),
            orElse: () => {});
            
        String productId;
        if (match.isNotEmpty) {
          productId = match['id'];
        } else {
          productId = const Uuid().v4();
          await _client.from('products').insert({
            'id': productId,
            'restaurant_id': restaurantId,
            'name': itemName,
            'normalized_name': itemName.toLowerCase(),
            'category': 'Разное',
            'unit': itemUnit,
            'minimum_stock': 0,
            'is_active': true,
            'is_new': true,
          });
          existingProducts.add({'id': productId, 'name': itemName, 'unit': itemUnit});
        }
        
        purchaseItemsToInsert.add({
          'id': const Uuid().v4(),
          'purchase_id': orderId,
          'product_id': productId,
          'quantity': itemQty,
          'unit': itemUnit,
          'unit_price': itemPrice,
          'total_price': itemQty * itemPrice,
        });
      }

      if (purchaseItemsToInsert.isNotEmpty) {
        await _client.from('purchase_items').insert(purchaseItemsToInsert);
      }
    } catch (e) {
      debugPrint('Error updating request: $e');
      rethrow;
    }
  }

  Future<void> deleteRequest(String orderId) async {
    try {
      await _client.from('purchase_items').delete().eq('purchase_id', orderId);
      await _client.from('purchases').delete().eq('id', orderId);
    } catch (e) {
      debugPrint('Error deleting request: $e');
      rethrow;
    }
  }

  Future<void> saveAIPurchase(List<Map<String, dynamic>> items, {File? imageFile, String? existingPurchaseId}) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;


      double totalAmount = 0;
      for (var item in items) {
        totalAmount += (item['quantity'] ?? 0) * (item['price'] ?? 0);
      }

      // 1. Fetch all products with stock to match and update average cost
      final existingProducts = await _client
          .from('products_with_stock')
          .select('id, name, unit, current_stock, average_cost')
          .eq('restaurant_id', restaurantId);

      // 2. Create or Update the Purchase record
      final purchaseId = existingPurchaseId ?? const Uuid().v4();
      if (existingPurchaseId != null) {
        await _client.from('purchases').update({
          'status': 'completed',
          'total_amount': totalAmount,
        }).eq('id', existingPurchaseId);
        
        await _client.from('purchase_items').delete().eq('purchase_id', existingPurchaseId);
      } else {
        await _client.from('purchases').insert({
          'id': purchaseId,
          'restaurant_id': restaurantId,
          'date': DateTime.now().toIso8601String(),
          'total_amount': totalAmount,
          'status': 'completed',
        });
      }
      
      // 3. Process each item
      final List<Map<String, dynamic>> stockMovementsToInsert = [];
      final List<Map<String, dynamic>> purchaseItemsToInsert = [];

      for (var item in items) {
        final String aiName = item['name'].toString().trim().toLowerCase();
        final double aiQuantity = (item['quantity'] ?? 0).toDouble();
        final double aiPrice = (item['price'] ?? 0).toDouble();
        final String aiUnit = item['unit'] ?? 'шт';

        // Find match
        var match = existingProducts.firstWhere(
            (p) => p['name'].toString().toLowerCase().contains(aiName) || aiName.contains(p['name'].toString().toLowerCase()),
            orElse: () => {});

        String productId;
        String baseUnit;
        
        if (match.isNotEmpty) {
          productId = match['id'];
          baseUnit = match['unit']?.toString() ?? aiUnit;
        } else {
          baseUnit = aiUnit;
          productId = const Uuid().v4();
        }

        final double convertedQty = UnitConverter.convert(aiQuantity, aiUnit, baseUnit);
        final double incomingUnitCost = convertedQty > 0 ? (aiQuantity * aiPrice) / convertedQty : aiPrice;

        if (match.isNotEmpty) {
          final double currentStock = (match['current_stock'] ?? 0).toDouble();
          final double currentAvgCost = (match['average_cost'] ?? 0).toDouble();
          final double newAvgCost = (currentStock <= 0 || currentAvgCost <= 0)
              ? incomingUnitCost
              : ((currentStock * currentAvgCost) + (convertedQty * incomingUnitCost)) / (currentStock + convertedQty);

          await _client.from('products').update({
            'average_cost': newAvgCost,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', productId);
        } else {
          await _client.from('products').insert({
            'id': productId,
            'restaurant_id': restaurantId,
            'name': item['name'],
            'normalized_name': item['name'].toString().toLowerCase(),
            'category': 'Разное',
            'unit': aiUnit,
            'minimum_stock': 0,
            'average_cost': incomingUnitCost,
            'is_active': true,
            'is_new': true,
          });
          existingProducts.add({
            'id': productId,
            'name': item['name'],
            'unit': aiUnit,
            'current_stock': convertedQty,
            'average_cost': incomingUnitCost,
          });
        }

        // Add to stock_movements for inventory balance
        stockMovementsToInsert.add({
          'id': const Uuid().v4(),
          'restaurant_id': restaurantId,
          'product_id': productId,
          'quantity': convertedQty,
          'unit': baseUnit,
          'type': 'purchase',
          'reference_id': purchaseId,
          'reason': 'Приход по накладной',
        });

        // Add to purchase_items
        purchaseItemsToInsert.add({
          'id': const Uuid().v4(),
          'purchase_id': purchaseId,
          'product_id': productId,
          'quantity': aiQuantity,
          'unit': aiUnit,
          'unit_price': aiPrice,
          'total_price': aiQuantity * aiPrice,
        });
      }

      if (stockMovementsToInsert.isNotEmpty) {
        await _client.from('stock_movements').insert(stockMovementsToInsert);
      }
      if (purchaseItemsToInsert.isNotEmpty) {
        await _client.from('purchase_items').insert(purchaseItemsToInsert);
      }
      
      // 4. Save image document if provided
      if (imageFile != null) {
        final ext = imageFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storagePath = '$restaurantId/invoices/$fileName';
        
        try {
          await _client.storage.from('documents').upload(storagePath, imageFile);
          final String publicUrl = _client.storage.from('documents').getPublicUrl(storagePath);
          
          await _client.from('purchase_documents').insert({
            'id': const Uuid().v4(),
            'purchase_id': purchaseId,
            'document_url': publicUrl,
            'storage_path': storagePath,
            'mime_type': 'image/$ext',
            'file_size': await imageFile.length(),
          });
        } catch (storageError) {
          debugPrint('Warning: Failed to upload invoice image: $storageError');
          // Proceed anyway as purchase items are saved
        }
      }
      
    } catch (e) {
      debugPrint('Error saving AI purchase: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPurchaseDetails(String purchaseId) async {
    try {
      final response = await _client
          .from('purchase_items')
          .select('quantity, unit, unit_price, total_price, products(name)')
          .eq('purchase_id', purchaseId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching purchase details: $e');
      return [];
    }
  }

  Future<String?> getPurchaseDocumentUrl(String purchaseId) async {
    try {
      final response = await _client
          .from('purchase_documents')
          .select('document_url')
          .eq('purchase_id', purchaseId)
          .maybeSingle();
      return response?['document_url'] as String?;
    } catch (e) {
      debugPrint('Error fetching purchase document url: $e');
      return null;
    }
  }
}
