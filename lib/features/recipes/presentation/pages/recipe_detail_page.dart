import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/recipe_entity.dart';
import '../providers/recipes_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/ingredient_option.dart';

class RecipeDetailPage extends StatefulWidget {
  final RecipeEntity recipe;
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _techController;
  bool _isSavingTech = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _techController = TextEditingController(text: widget.recipe.description ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _techController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      body: Consumer<RecipesProvider>(
        builder: (context, provider, child) {
          final updatedRecipe = provider.recipes.firstWhere(
            (r) => r.id == widget.recipe.id, 
            orElse: () => widget.recipe
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Initial & Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        image: updatedRecipe.imageUrl != null && updatedRecipe.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(updatedRecipe.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (updatedRecipe.imageUrl == null || updatedRecipe.imageUrl!.isEmpty)
                            Center(
                              child: Text(
                                updatedRecipe.name.isNotEmpty ? updatedRecipe.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (provider.isRecipeUploading(widget.recipe.id))
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: provider.isRecipeUploading(widget.recipe.id) ? null : () async {
                          final ImageSource? source = await showModalBottomSheet<ImageSource>(
                            context: context,
                            backgroundColor: AppColors.surface,
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt, color: Colors.white),
                                    title: Text('recipes.from_camera'.tr(), style: const TextStyle(color: Colors.white)),
                                    onTap: () => Navigator.pop(context, ImageSource.camera),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library, color: Colors.white),
                                    title: Text('recipes.from_gallery'.tr(), style: const TextStyle(color: Colors.white)),
                                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (source != null) {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: source);
                            if (image != null && context.mounted) {
                              context.read<RecipesProvider>().uploadRecipeImage(widget.recipe.id, image.path);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          updatedRecipe.category,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  updatedRecipe.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              
              const SizedBox(height: 16),
              // 3 Stat Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('recipes.cost_price'.tr(), '${updatedRecipe.costPrice.toInt()} ${'common.currency_sum'.tr()}', AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('recipes.dish_yield'.tr(), '${updatedRecipe.outputQuantity.toInt()} ${updatedRecipe.outputUnit}', AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('recipes.foodcost'.tr(), '${updatedRecipe.foodcostPercentage.toStringAsFixed(1)}%', AppColors.success)),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'recipes.tab_ingredients'.tr()),
                  Tab(text: 'recipes.tab_technology'.tr()),
                ],
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIngredientsTab(updatedRecipe),
                    _buildTechnologyTab(updatedRecipe),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(RecipeEntity updatedRecipe) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Table Header
        Row(
          children: [
            Expanded(flex: 3, child: Text('recipes.col_ingredient'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            Expanded(flex: 2, child: Text('recipes.col_weight'.tr(), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            Expanded(flex: 2, child: Text('recipes.col_price'.tr(), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            Expanded(flex: 2, child: Text('recipes.col_sum'.tr(), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            const SizedBox(width: 36),
          ],
        ),
        const Divider(color: Colors.white10, height: 24),
        // Ingredients List
        ...updatedRecipe.items.map((ing) {
              String qtyStr = ing.quantity == ing.quantity.toInt() ? ing.quantity.toInt().toString() : ing.quantity.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
              String priceStr = ing.productPrice == ing.productPrice.toInt() ? ing.productPrice.toInt().toString() : ing.productPrice.toStringAsFixed(2);
              String sumStr = ing.sum == ing.sum.toInt() ? ing.sum.toInt().toString() : ing.sum.toStringAsFixed(2);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(ing.productName, style: const TextStyle(color: AppColors.textPrimary))),
                    Expanded(flex: 2, child: Text('$qtyStr ${ing.unit}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textPrimary))),
                    Expanded(flex: 2, child: Text(priceStr, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textPrimary))),
                    Expanded(flex: 2, child: Text(sumStr, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textPrimary))),
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: Text('common.confirm'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                              content: Text('${ing.productName} ${'inventory.delete_confirm'.tr()}', style: const TextStyle(color: AppColors.textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            await context.read<RecipesProvider>().deleteRecipeItem(widget.recipe.id, ing.id);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // Add Button
            TextButton.icon(
              onPressed: () => _showAddIngredientModal(context, widget.recipe.id),
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: Text('recipes.add_ingredient'.tr(), style: const TextStyle(color: AppColors.primary)),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            ),
      ],
    );
  }

  Widget _buildTechnologyTab(RecipeEntity updatedRecipe) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'recipes.tab_technology'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _techController,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'recipes.tab_technology'.tr(),
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSavingTech ? null : () async {
              setState(() => _isSavingTech = true);
              await context.read<RecipesProvider>().updateRecipeDescription(
                widget.recipe.id,
                _techController.text.trim(),
              );
              if (mounted) {
                setState(() => _isSavingTech = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('common.success'.tr()),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: _isSavingTech
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('common.save'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientModal(BuildContext context, String recipeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddIngredientModal(recipeId: recipeId);
      },
    );
  }
}

class AddIngredientModal extends StatefulWidget {
  final String recipeId;
  const AddIngredientModal({super.key, required this.recipeId});

  @override
  State<AddIngredientModal> createState() => _AddIngredientModalState();
}

class _AddIngredientModalState extends State<AddIngredientModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  IngredientOption? _selectedItem;
  bool _isSaving = false;
  bool isLoading = true;
  String _searchQuery = '';
  List<IngredientOption> items = [];
  List<IngredientOption> filteredItems = [];

  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    try {
      final provider = context.read<RecipesProvider>();
      final products = await provider.getIngredientOptions();
      if (mounted) {
        setState(() {
          items = products;
          filteredItems = products;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _selectItem(IngredientOption item) {
    setState(() {
      _selectedItem = item;
      _searchController.clear();
      _priceController.text = item.averageCost > 0 ? item.averageCost.toStringAsFixed(2) : '';
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalPrice = qty * price;
    });
  }

  @override
  Widget build(BuildContext context) {
    filteredItems = items.where((item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_menu, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'recipes.new_ingredient'.tr(), 
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_selectedItem == null) ...[
            // SEARCH FIELD
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'recipes.search_product'.tr(),
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            
            // LIST OF PRODUCTS
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'recipes.product_not_found'.tr(),
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                              subtitle: Text('${'recipes.in_stock'.tr()}: ${item.currentQuantity} ${item.unit}', style: const TextStyle(color: AppColors.textSecondary)),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              onTap: () => _selectItem(item),
                            );
                          },
                        ),
            ),
          ] else ...[
            // SELECTED ITEM DETAILS
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('recipes.selected'.tr(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_selectedItem!.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('${'recipes.in_stock'.tr()}: ${_selectedItem!.currentQuantity} ${_selectedItem!.unit}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => setState(() => _selectedItem = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Quantity Input
                    TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'recipes.usage_amount'.tr(),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.scale_outlined, color: AppColors.textSecondary),
                        suffixText: _selectedItem!.unit,
                        suffixStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price Input
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: '${'recipes.price_per_unit'.tr()} (1 ${_selectedItem!.unit})',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textSecondary),
                        suffixText: 'recipes.currency'.tr(),
                        suffixStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('recipes.total_sum'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
                          Text(
                            '${_totalPrice > 0 ? (_totalPrice == _totalPrice.toInt() ? _totalPrice.toInt() : _totalPrice.toStringAsFixed(2)) : 0} ${'recipes.currency'.tr()}',
                            style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () async {
                          final qty = double.tryParse(_quantityController.text) ?? 0;
                          final price = double.tryParse(_priceController.text) ?? 0;
                          
                          if (qty > 0) {
                            setState(() => _isSaving = true);
                            try {
                              final provider = context.read<RecipesProvider>();
                              await provider.addRecipeItem(
                                recipeId: widget.recipeId,
                                productId: _selectedItem!.id,
                                productName: _selectedItem!.name,
                                quantity: qty,
                                unit: _selectedItem!.unit,
                                productPrice: price,
                              );
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('recipes.ingredient_added_success'.tr()),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  )
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${'recipes.error_occurred'.tr()}: $e'),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  )
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('recipes.enter_valid_amount'.tr()),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              )
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('recipes.add'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
