import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';

class PosRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    try {
      final response = await _client
          .from('recipes')
          .select('id, name, selling_price, is_active, is_favorite')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('is_active', true)
          .order('is_favorite', ascending: false)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('POS fetch recipes error: $e');
      return [];
    }
  }

  Future<void> checkout(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      
      final formattedItems = cartItems.map((item) => {
        'recipe_id': item['recipe_id'],
        'quantity': item['quantity'],
        'price': item['price'],
      }).toList();

      await _client.rpc('process_pos_checkout', params: {
        'p_restaurant_id': restaurantId,
        'p_total_amount': totalAmount,
        'p_items': formattedItems,
      });
    } catch (e) {
      throw Exception('To`lovni amalga oshirishda xatolik: $e');
    }
  }

  Future<bool> refundSale(String saleId, {String reason = 'Mijoz qaytardi'}) async {
    try {
      final response = await _client.rpc('process_pos_refund', params: {
        'p_sale_id': saleId,
        'p_reason': reason,
      });
      return response == true;
    } catch (e) {
      debugPrint('Error refunding POS sale: $e');
      throw Exception('Chekni bekor qilishda xatolik: $e');
    }
  }
}
