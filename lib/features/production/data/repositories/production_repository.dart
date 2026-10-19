import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/utils/unit_converter.dart';

class ProductionRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    try {
      final response = await _client
          .from('recipes')
          .select('id, name, output_unit, is_favorite, recipe_items(product_id, quantity, unit)')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('is_active', true)
          .order('is_favorite', ascending: false)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch recipes error: $e');
      return [];
    }
  }

  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      await _client
          .from('recipes')
          .update({'is_favorite': isFavorite})
          .eq('id', recipeId);
    } catch (e) {
      throw Exception('Yulduzchani o`zgartirishda xatolik: $e');
    }
  }

  Future<void> produceRecipe(String recipeId, String recipeName, double quantity, List<dynamic> items) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      
      final eventResponse = await _client.from('business_events').insert({
        'restaurant_id': restaurantId,
        'event_type': 'production',
        'payload': {
          'recipe_id': recipeId,
          'recipe_name': recipeName,
          'quantity': quantity,
        },
      }).select().single();

      final eventId = eventResponse['id'];

      final productIds = items.map((i) => i['product_id'] as String).toList();
      final Map<String, String> baseUnits = {};
      
      if (productIds.isNotEmpty) {
        final productsResponse = await _client
            .from('products')
            .select('id, unit')
            .inFilter('id', productIds);
            
        for (var p in (productsResponse as List)) {
          baseUnits[p['id']] = p['unit']?.toString() ?? '';
        }
      }

      List<Map<String, dynamic>> movements = [];
      for (var item in items) {
        final double itemQty = (item['quantity'] ?? 0).toDouble();
        final String recipeUnit = item['unit'] ?? '';
        final String baseUnit = baseUnits[item['product_id']] ?? recipeUnit;
        final String finalUnit = baseUnit.isEmpty ? recipeUnit : baseUnit;
        
        final double convertedQty = UnitConverter.convert(itemQty, recipeUnit, finalUnit);

        movements.add({
          'restaurant_id': restaurantId,
          'product_id': item['product_id'],
          'quantity': -(convertedQty * quantity),
          'unit': finalUnit,
          'type': 'production_usage',
          'reference_id': eventId,
          'reason': 'Tayyorlash: $recipeName x $quantity',
        });
      }

      if (movements.isNotEmpty) {
        await _client.from('stock_movements').insert(movements);
      }
    } catch (e) {
      throw Exception('Tayyorlashda xatolik: $e');
    }
  }
}
