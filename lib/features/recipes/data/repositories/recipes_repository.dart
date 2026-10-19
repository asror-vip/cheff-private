import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/recipe_model.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/ingredient_option.dart';

class RecipesRepository {
  final SupabaseClient _client = SupabaseService.client;
  
  Future<List<RecipeEntity>> getRecipes() async {
    try {
      final response = await _client
          .from('recipes')
          .select('''
            *,
            recipe_items (
              *,
              products (
                name,
                average_cost
              )
            )
          ''')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('is_active', true)
          .order('name');
          
      final List<RecipeModel> models = (response as List)
          .map((json) => RecipeModel.fromJson(json))
          .toList();
          
      return models.map((e) => e.toEntity()).toList();
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
      rethrow;
    }
  }

  Future<RecipeEntity> addRecipe({
    required String name,
    required String category,
    required double sellingPrice,
    required double outputQuantity,
    required String outputUnit,
  }) async {
    final restaurantId = SupabaseService.currentRestaurantId;

    final response = await _client.from('recipes').insert({
      'id': const Uuid().v4(),
      'restaurant_id': restaurantId,
      'name': name,
      'description': 'Category: $category',
      'selling_price': sellingPrice,
      'output_quantity': outputQuantity,
      'output_unit': outputUnit,
      'is_active': true,
    }).select().single();

    final RecipeModel newRecipe = RecipeModel.fromJson(response);
    return newRecipe.toEntity();
  }

  Future<void> addRecipeItem({
    required String recipeId,
    required String productId,
    required double quantity,
    required String unit,
  }) async {
    await _client.from('recipe_items').insert({
      'id': const Uuid().v4(),
      'recipe_id': recipeId,
      'product_id': productId,
      'quantity': quantity,
      'unit': unit,
    });
  }

  Future<String> uploadRecipeImage(String recipeId, String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final String path = 'recipe_${recipeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await _client.storage.from('images').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    
    final imageUrl = _client.storage.from('images').getPublicUrl(path);
    await _client.from('recipes').update({'image_url': imageUrl}).eq('id', recipeId);
    return imageUrl;
  }

  Future<List<IngredientOption>> getIngredientOptions() async {
    try {
      final response = await _client
          .from('products_with_stock')
          .select()
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('is_active', true)
          .order('name');

      final pricesResponse = await _client
          .from('purchase_items')
          .select('product_id, unit_price, purchases!inner(date)')
          .eq('purchases.restaurant_id', SupabaseService.currentRestaurantId)
          .order('date', referencedTable: 'purchases', ascending: false);

      final Map<String, double> latestPrices = {};
      for (var row in (pricesResponse as List)) {
        final String pid = row['product_id'];
        if (!latestPrices.containsKey(pid)) {
          latestPrices[pid] = (row['unit_price'] ?? 0).toDouble();
        }
      }
          
      return (response as List).map((json) {
        final option = IngredientOption.fromJson(json);
        final currentStock = (json['current_stock'] ?? 0).toDouble();
        final currentPrice = latestPrices[option.id] ?? option.averageCost;
        return IngredientOption(
          id: option.id,
          name: option.name,
          unit: option.unit,
          averageCost: currentPrice,
          currentQuantity: currentStock,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteRecipeItem(String itemId) async {
    await _client.from('recipe_items').delete().eq('id', itemId);
  }

  Future<void> updateRecipeDescription(String recipeId, String description) async {
    await _client.from('recipes').update({
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', recipeId);
  }
}
