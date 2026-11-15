import 'package:flutter/material.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/recipe_item_entity.dart';
import '../../domain/entities/ingredient_option.dart';
import '../../data/repositories/recipes_repository.dart';
import '../../../../core/utils/unit_converter.dart';

class RecipesProvider extends ChangeNotifier {
  final RecipesRepository _repository = RecipesRepository();
  
  List<RecipeEntity> _recipes = [];
  List<RecipeEntity> get recipes => _recipes;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  final Map<String, bool> _uploadingRecipes = {};
  bool isRecipeUploading(String id) => _uploadingRecipes[id] ?? false;
  
  String? _error;
  String? get error => _error;

  
  

  List<IngredientOption> _cachedIngredientOptions = [];
  bool _hasLoadedIngredients = false;

  Future<void> fetchRecipes({bool background = false}) async {
    if (!background && _recipes.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;
    
    try {
      final results = await Future.wait([
        _repository.getRecipes(),
        _repository.getIngredientOptions(),
      ]);
      
      List<RecipeEntity> fetchedRecipes = results[0] as List<RecipeEntity>;
      _cachedIngredientOptions = results[1] as List<IngredientOption>;
      _hasLoadedIngredients = true;
      
      // Inject the current dynamic price into the recipe items
      _recipes = fetchedRecipes.map((recipe) {
        final updatedItems = recipe.items.map((item) {
          try {
            final option = _cachedIngredientOptions.firstWhere((o) => o.id == item.productId);
            final factor = UnitConverter.convert(1.0, item.unit, option.unit);
            return RecipeItemEntity(
              id: item.id,
              recipeId: item.recipeId,
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              unit: item.unit,
              productPrice: option.averageCost * factor,
            );
          } catch (_) {
            return item;
          }
        }).toList();
        
        return RecipeEntity(
          id: recipe.id,
          name: recipe.name,
          category: recipe.category,
          description: recipe.description,
          sellingPrice: recipe.sellingPrice,
          outputQuantity: recipe.outputQuantity,
          outputUnit: recipe.outputUnit,
          isActive: recipe.isActive,
          imageUrl: recipe.imageUrl,
          items: updatedItems,
        );
      }).toList();
      
    } catch (e) {
      _error = e.toString();
    }
    if (!background) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<List<IngredientOption>> getIngredientOptions({bool forceRefresh = false}) async {
    if (_hasLoadedIngredients && !forceRefresh) {
      return _cachedIngredientOptions;
    }
    _cachedIngredientOptions = await _repository.getIngredientOptions();
    _hasLoadedIngredients = true;
    return _cachedIngredientOptions;
  }

  Future<void> addRecipe({
    required String name,
    required String category,
    required double sellingPrice,
    required double outputQuantity,
    required String outputUnit,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newRecipe = await _repository.addRecipe(
        name: name,
        category: category,
        sellingPrice: sellingPrice,
        outputQuantity: outputQuantity,
        outputUnit: outputUnit,
      );
      _recipes.add(newRecipe);
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecipeItem({
    required String recipeId,
    required String productId,
    required String productName,
    required double quantity,
    required String unit,
    required double productPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.addRecipeItem(
        recipeId: recipeId,
        productId: productId,
        quantity: quantity,
        unit: unit,
      );

      // Update local state
      final recipeIndex = _recipes.indexWhere((r) => r.id == recipeId);
      if (recipeIndex != -1) {
        final recipe = _recipes[recipeIndex];
        final newIngredient = RecipeItemEntity(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          recipeId: recipeId,
          productId: productId,
          productName: productName,
          quantity: quantity,
          unit: unit,
          productPrice: productPrice,
        );
        
        final updatedIngredients = List<RecipeItemEntity>.from(recipe.items)..add(newIngredient);
        
        _recipes[recipeIndex] = RecipeEntity(
          id: recipe.id,
          name: recipe.name,
          category: recipe.category,
          sellingPrice: recipe.sellingPrice,
          outputQuantity: recipe.outputQuantity,
          outputUnit: recipe.outputUnit,
          isActive: recipe.isActive,
          imageUrl: recipe.imageUrl,
          items: updatedIngredients,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadRecipeImage(String recipeId, String imagePath) async {
    _uploadingRecipes[recipeId] = true;
    _error = null;
    notifyListeners();
    try {
      final imageUrl = await _repository.uploadRecipeImage(recipeId, imagePath);
      final recipeIndex = _recipes.indexWhere((r) => r.id == recipeId);
      if (recipeIndex != -1) {
        final r = _recipes[recipeIndex];
        _recipes[recipeIndex] = RecipeEntity(
          id: r.id, 
          name: r.name, 
          category: r.category, 
          description: r.description,
          sellingPrice: r.sellingPrice,
          outputQuantity: r.outputQuantity, 
          outputUnit: r.outputUnit, 
          isActive: r.isActive, 
          items: r.items, 
          imageUrl: imageUrl,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    _uploadingRecipes[recipeId] = false;
    notifyListeners();
  }

  Future<void> deleteRecipeItem(String recipeId, String itemId) async {
    try {
      await _repository.deleteRecipeItem(itemId);
      await fetchRecipes(background: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRecipeDescription(String recipeId, String techText) async {
    try {
      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      final formattedDesc = 'Category: ${recipe.category}\n---\n$techText';
      await _repository.updateRecipeDescription(recipeId, formattedDesc);
      await fetchRecipes(background: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
