import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/recipes_provider.dart';
import 'package:provider/provider.dart';
import 'recipe_detail_page.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../../../core/utils/search_utils.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  String? _highlightedRecipeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecipesProvider>();
      provider.fetchRecipes(background: provider.recipes.isNotEmpty);
    });
  }
  
  void _scrollToItem(String recipeId) {
    setState(() {
      _selectedCategoryIndex = 0;
      _highlightedRecipeId = recipeId;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final provider = context.read<RecipesProvider>();
      final index = provider.recipes.indexWhere((r) => r.id == recipeId);
      if (index != -1 && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = index * 100.0;
        _scrollController.animateTo(
          targetOffset > maxScroll ? maxScroll : targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightedRecipeId = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('recipes.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () async {
              final provider = context.read<RecipesProvider>();
              final selectedId = await showSearch(
                context: context,
                delegate: RecipeSearchDelegate(provider.recipes),
              );
              if (selectedId != null) {
                _scrollToItem(selectedId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'common.refresh'.tr(),
            onPressed: () => context.read<RecipesProvider>().fetchRecipes(),
          ),
        ],
      ),
      body: Consumer<RecipesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.recipes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null && provider.recipes.isEmpty) {
            return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
          }

          final recipes = provider.recipes;
          
          final String allCategory = 'common.all'.tr();
          final Set<String> uniqueCategories = {allCategory};
          for (var recipe in recipes) {
            uniqueCategories.add(recipe.category);
          }
          final categories = uniqueCategories.toList();

          int selectedIndex = _selectedCategoryIndex;
          if (selectedIndex >= categories.length) {
            selectedIndex = 0;
          }

          final selectedCategory = categories[selectedIndex];

          final filteredRecipes = selectedCategory == allCategory
              ? recipes
              : recipes.where((r) => r.category == selectedCategory).toList();

          return Column(
            children: [
              // Categories
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueAccent : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 8),

              // Recipes List
              Expanded(
                child: filteredRecipes.isEmpty
                    ? Center(child: Text('recipes.no_recipes'.tr(), style: const TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = filteredRecipes[index];
                          final isHighlighted = recipe.id == _highlightedRecipeId;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe)),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isHighlighted ? Colors.blueAccent.withValues(alpha: 0.2) : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isHighlighted ? Colors.blueAccent : Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  // Image or Icon
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      image: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(recipe.imageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: recipe.imageUrl == null || recipe.imageUrl!.isEmpty
                                        ? Center(
                                            child: Text(
                                              recipe.name.isNotEmpty ? recipe.name[0].toUpperCase() : '?',
                                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.pie_chart, size: 14, color: AppColors.success),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Foodcost: ${recipe.foodcostPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                color: AppColors.success,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${recipe.outputQuantity} ${recipe.outputUnit}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeModal,
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddRecipeModal() {
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

class AddRecipeModal extends StatefulWidget {
  const AddRecipeModal({super.key});

  @override
  State<AddRecipeModal> createState() => _AddRecipeModalState();
}

class _AddRecipeModalState extends State<AddRecipeModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = 'Issiq taomlar';

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('recipes.add_new_ttk'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'recipes.dish_name'.tr(),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'inventory.category'.tr(),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
            ),
            items: ['Issiq taomlar', 'Salatlar', 'Ichimliklar', 'Desertlar', 'Sho\'rvalar'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedCategory = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'recipes.output_quantity_hint'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'recipes.selling_price'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final quantity = double.tryParse(_quantityController.text) ?? 0;
                final price = double.tryParse(_priceController.text) ?? 0;
                
                if (name.isNotEmpty && quantity > 0) {
                  final provider = context.read<RecipesProvider>();
                  final nav = Navigator.of(context);
                  await provider.addRecipe(
                    name: name,
                    category: _selectedCategory,
                    sellingPrice: price,
                    outputQuantity: quantity,
                    outputUnit: 'g',
                  );
                  if (nav.canPop()) {
                    nav.pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('common.save'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class RecipeSearchDelegate extends SearchDelegate<String?> {
  final List<RecipeEntity> recipes;
  static final List<String> _searchHistory = [];

  RecipeSearchDelegate(this.recipes);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('common.search_history'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        _searchHistory.clear();
                        query = ''; // Triggers rebuild
                      },
                      child: Text('common.clear'.tr(), style: const TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.history, color: AppColors.textSecondary),
                    title: Text(_searchHistory[index], style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      query = _searchHistory[index];
                      showResults(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return _buildList();
  }

  Widget _buildList() {
    final normalizedQuery = SearchUtils.normalize(query);
    
    final filteredRecipes = recipes.where((recipe) {
      final normalizedName = SearchUtils.normalize(recipe.name);
      final normalizedCategory = SearchUtils.normalize(recipe.category);
      return normalizedName.contains(normalizedQuery) || normalizedCategory.contains(normalizedQuery);
    }).toList();

    return Container(
      color: AppColors.background,
      child: filteredRecipes.isEmpty
          ? Center(child: Text('common.not_found'.tr(), style: const TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return ListTile(
                  title: Text(recipe.name, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(recipe.category, style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: Text('${recipe.outputQuantity} ${recipe.outputUnit}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  onTap: () {
                    close(context, recipe.id);
                  },
                );
              },
            ),
    );
  }
}
