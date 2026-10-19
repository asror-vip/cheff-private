import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../recipes/presentation/pages/recipes_page.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../recipes/presentation/providers/recipes_provider.dart';

class MenuFoodcostPage extends StatefulWidget {
  const MenuFoodcostPage({super.key});

  @override
  State<MenuFoodcostPage> createState() => _MenuFoodcostPageState();
}

class _MenuFoodcostPageState extends State<MenuFoodcostPage> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipesProvider>().fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipesProvider = context.watch<RecipesProvider>();
    final allRecipes = recipesProvider.recipes;

    final Set<String> categorySet = {};
    for (var dish in allRecipes) {
      if (dish.category.trim().isNotEmpty) {
        categorySet.add(dish.category.trim());
      }
    }
    final sortedCategories = categorySet.toList()..sort();
    final categories = ['common.all'.tr(), ...sortedCategories];

    if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    final filteredDishes = _selectedCategory == 'common.all'.tr()
        ? allRecipes
        : allRecipes.where((d) {
            final cat = d.category.trim().isEmpty ? 'inventory.col_category'.tr() : d.category.trim();
            return cat == _selectedCategory;
          }).toList();

    final int totalDishesCount = allRecipes.length;
    final validDishesWithPrice = allRecipes.where((d) => d.sellingPrice > 0).toList();
    final double avgFoodcost = validDishesWithPrice.isEmpty
        ? 0.0
        : validDishesWithPrice.fold(0.0, (sum, d) => sum + d.foodcostPercentage) / validDishesWithPrice.length;

    final double expectedProfit = allRecipes.fold(0.0, (sum, d) {
      final profit = d.sellingPrice - d.costPrice;
      return sum + (profit > 0 ? profit : 0.0);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('menu.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () {
              context.read<RecipesProvider>().fetchRecipes(background: true);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Dropdown Main Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('menu.total_dishes'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$totalDishesCount', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('menu.avg_foodcost'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${avgFoodcost.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: avgFoodcost > 30 ? AppColors.error : AppColors.success,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('menu.expected_profit'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(locale: 'uz', symbol: 'common.currency_sum'.tr(), decimalDigits: 0).format(expectedProfit),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List of dishes
          Expanded(
            child: recipesProvider.isLoading && allRecipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredDishes.isEmpty
                    ? Center(
                        child: Text(
                          'common.no_data'.tr(),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDishes.length,
                        itemBuilder: (context, index) {
                          final dish = filteredDishes[index];
                          final isHighFoodcost = dish.foodcostPercentage > 30;
                          
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailPage(recipe: dish),
                                ),
                              ).then((_) {
                                if (context.mounted) {
                                  context.read<RecipesProvider>().fetchRecipes(background: true);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (dish.imageUrl != null && dish.imageUrl!.isNotEmpty)
                                        ? Image.network(
                                            dish.imageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => _buildLetterAvatar(dish.name),
                                          )
                                        : _buildLetterAvatar(dish.name),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dish.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              NumberFormat.currency(locale: 'uz', symbol: 'common.currency_sum'.tr(), decimalDigits: 0).format(dish.sellingPrice),
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${dish.costPrice.toInt()} ${'common.currency_sum'.tr()})',
                                              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${dish.foodcostPercentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: isHighFoodcost ? AppColors.error : AppColors.success,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddDishModal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('menu.add_to_menu'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLetterAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddDishModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const AddRecipeModal();
      },
    );
  }
}
