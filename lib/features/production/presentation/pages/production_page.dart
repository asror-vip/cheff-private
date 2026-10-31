import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../providers/production_provider.dart';
import '../../../../core/theme/app_colors.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  final ScrollController _scrollController = ScrollController();
  String? _highlightedRecipeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().fetchRecipes();
    });
  }

  void _scrollToItem(String recipeId) {
    setState(() {
      _highlightedRecipeId = recipeId;
    });

    final provider = context.read<ProductionProvider>();
    final index = provider.filteredRecipes.indexWhere((r) => r['id'] == recipeId);
    if (index != -1) {
      double position = index * 100.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedRecipeId = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('production.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.blueAccent),
            tooltip: 'Zagatovka qilish',
            onPressed: () => CreateZagatovkaSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final selectedId = await showSearch(
                context: context,
                delegate: ProductionSearchDelegate(provider.filteredRecipes),
              );
              if (selectedId != null) {
                _scrollToItem(selectedId);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: provider.isLoading && provider.filteredRecipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
                    itemCount: provider.filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = provider.filteredRecipes[index];
                      final recipeId = recipe['id'] as String;
                      final quantity = provider.getQuantity(recipeId);

                      final isHighlighted = _highlightedRecipeId == recipeId;
                      return Card(
                        color: isHighlighted ? AppColors.surface.withAlpha(150) : AppColors.surface,
                        shape: isHighlighted 
                            ? RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.blueAccent, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: quantity > 0 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe['name'], 
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${'production.output'.tr()}: ${recipe["output_unit"] ?? ""}', 
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (quantity == 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        recipe['is_favorite'] == true ? Icons.star : Icons.star_border,
                                        color: recipe['is_favorite'] == true ? Colors.amber : AppColors.textSecondary,
                                      ),
                                      padding: const EdgeInsets.only(bottom: 12),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => context.read<ProductionProvider>().toggleFavorite(recipeId),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => context.read<ProductionProvider>().increment(recipeId),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () => context.read<ProductionProvider>().decrement(recipeId),
                                    ),
                                    Text(
                                      quantity.toInt().toString(),
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                      onPressed: () => context.read<ProductionProvider>().increment(recipeId),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Removed AI Input Container
        ],
      ),
      floatingActionButton: provider.totalCartItems > 0
          ? FloatingActionButton.extended(
              onPressed: provider.isLoading ? null : () async {
                try {
                  final msg = await context.read<ProductionProvider>().submitCart();
                  if (msg.isNotEmpty && context.mounted) {
                    toastification.show(
                      context: context,
                      type: ToastificationType.success,
                      style: ToastificationStyle.flat,
                      title: Text('common.success'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      description: Text(msg),
                      alignment: Alignment.topRight,
                      autoCloseDuration: const Duration(seconds: 4),
                      showProgressBar: true,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    toastification.show(
                      context: context,
                      type: ToastificationType.error,
                      style: ToastificationStyle.flat,
                      title: Text('common.error'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      description: Text(e.toString().replaceAll('Exception: ', '')),
                      alignment: Alignment.topRight,
                      autoCloseDuration: const Duration(seconds: 4),
                      showProgressBar: true,
                    );
                  }
                }
              },
              backgroundColor: provider.isLoading ? Colors.grey : AppColors.primary,
              icon: provider.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check, color: Colors.white),
              label: Text(
                '${provider.totalCartItems} ${'production.produce_btn'.tr()}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}


class ProductionSearchDelegate extends SearchDelegate<String?> {
  final List<Map<String, dynamic>> recipes;
  final List<String> _searchHistory = [];

  ProductionSearchDelegate(this.recipes) : super(searchFieldLabel: 'common.search'.tr());

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
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
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.textPrimary),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
    final normalizedQuery = query.toLowerCase();
    
    final filteredRecipes = recipes.where((recipe) {
      final normalizedName = (recipe['name'] as String? ?? '').toLowerCase();
      return normalizedName.contains(normalizedQuery);
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
                  title: Text(recipe['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
                  onTap: () {
                    close(context, recipe['id'] as String?);
                  },
                );
              },
            ),
    );
  }
}
