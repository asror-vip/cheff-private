import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';
import 'package:provider/provider.dart';
import 'bulk_import_page.dart';
import 'reviziya_page.dart';
import '../../../../core/utils/search_utils.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _highlightedItemId;

  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventoryProvider>();
      provider.fetchInventory(background: provider.items.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('inventory.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () async {
              final items = context.read<InventoryProvider>().items;
              final selectedId = await showSearch<String?>(
                context: context, 
                delegate: InventorySearchDelegate(items)
              );
              
              if (!context.mounted) return;
              if (selectedId != null) {
                final inventoryProvider = context.read<InventoryProvider>();
                setState(() {
                  _selectedCategoryIndex = 0; // Switch to 'All' to ensure item is visible
                  _highlightedItemId = selectedId;
                });
                
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (!mounted) return;
                  final allItems = inventoryProvider.items;
                  final index = allItems.indexWhere((e) => e.id == selectedId);
                  if (index != -1 && _scrollController.hasClients) {
                    // Maximum scroll extent protection
                    final maxScroll = _scrollController.position.maxScrollExtent;
                    final targetOffset = index * 60.0;
                    _scrollController.animateTo(
                      targetOffset > maxScroll ? maxScroll : targetOffset,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() { _highlightedItemId = null; });
                  }
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rtl, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReviziyaPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Pill TabBar matching Screen #7
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'inventory.tab_balances'.tr()),
                  Tab(text: 'inventory.tab_inventory'.tr()),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBalances(),
                _buildInventoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showAddOptionsModal,
            child: const Center(
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: Text('inventory.add_manual'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemModal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: AppColors.success),
                title: Text('inventory.upload_excel'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  final inventoryProvider = context.read<InventoryProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BulkImportPage()),
                  ).then((_) {
                    if (mounted) inventoryProvider.fetchInventory();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddItemModal() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final categoryController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('inventory.add_product'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'inventory.product_name'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'inventory.category'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'inventory.quantity'.tr(),
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'inventory.unit'.tr(),
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
                      if (nameController.text.isEmpty || categoryController.text.isEmpty || unitController.text.isEmpty) {
                        return;
                      }
                      
                      final qty = double.tryParse(quantityController.text) ?? 0.0;
                      
                      await context.read<InventoryProvider>().addProduct(
                        name: nameController.text,
                        category: categoryController.text,
                        unit: unitController.text,
                        minimumStock: 5.0, // Default minimum stock for now
                        initialStock: qty,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
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
          ),
        );
      },
    );
  }

  void _showEditItemModal(dynamic item) {
    final nameController = TextEditingController(text: item.name);
    final unitController = TextEditingController(text: item.unit);
    final categoryController = TextEditingController(text: item.category);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('inventory.edit_product'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'inventory.product_name'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'inventory.category'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'inventory.unit'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || categoryController.text.isEmpty || unitController.text.isEmpty) {
                        return;
                      }
                      
                      await context.read<InventoryProvider>().updateProduct(
                        id: item.id,
                        name: nameController.text,
                        category: categoryController.text,
                        unit: unitController.text,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
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
          ),
        );
      },
    );
  }

  void _deleteItem(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
        content: Text("${item.name} ${'inventory.delete_confirm'.tr()}", style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<InventoryProvider>().deleteProduct(item.id);
            },
            child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalances() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.items.isEmpty) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
        }

        final itemsList = provider.items;
        
        final String allCategoryLabel = 'common.all'.tr();
        final Set<String> uniqueCategories = {allCategoryLabel};
        for (var item in itemsList) {
          uniqueCategories.add(item.category);
        }
        final categories = uniqueCategories.toList();

        // Ensure selected index is valid
        int selectedIndex = _selectedCategoryIndex;
        if (selectedIndex >= categories.length) {
          selectedIndex = 0;
        }

        final selectedCategory = categories[selectedIndex];

        final filteredItems = itemsList.where((item) {
          final matchesCategory = selectedCategory == allCategoryLabel || item.category == selectedCategory;
          final matchesSearch = _searchQuery.isEmpty ||
              item.name.toLowerCase().contains(_searchQuery) ||
              item.category.toLowerCase().contains(_searchQuery);
          return matchesCategory && matchesSearch;
        }).toList();

        final totalCount = itemsList.length;
        final totalSum = itemsList.fold(0.0, (sum, i) => sum + i.totalValue);

        return Column(
          children: [
            // Top Summary Metric Cards matching Screen #7
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('inventory.total_positions'.tr().isEmpty ? 'Всего позиций' : 'inventory.total_positions'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 6),
                          Text('$totalCount', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('inventory.total_sum'.tr().isEmpty ? 'На сумму' : 'inventory.total_sum'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 6),
                          Text(
                            totalSum > 0 
                                ? NumberFormat.currency(locale: 'uz', symbol: 'сум', decimalDigits: 0).format(totalSum)
                                : '0 сум',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inline Search Bar matching Screen #7
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'inventory.search_hint'.tr().isEmpty ? 'Поиск продуктов...' : 'inventory.search_hint'.tr(),
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            // Categories chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),

            // Items List matching Screen #7
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'common.no_data'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isHighlighted = item.id == _highlightedItemId;
                        final isCritical = item.quantity <= 2;
                        final isLow = item.isLowStock || item.quantity <= 5;
                        
                        final statusColor = isCritical 
                            ? AppColors.error 
                            : (isLow ? AppColors.warning : AppColors.success);
                        final statusText = isCritical
                            ? 'Критический'
                            : (isLow ? 'Низкий' : 'Норма');

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isHighlighted 
                                ? AppColors.primary.withValues(alpha: 0.2) 
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHighlighted 
                                  ? AppColors.primary 
                                  : Colors.white.withValues(alpha: 0.07),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Rounded Box Icon
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.catWarehouse.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.catWarehouse.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: AppColors.catWarehouse,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} ${item.unit} • ${item.category}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
                                    color: AppColors.surface,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditItemModal(item);
                                      } else if (value == 'delete') {
                                        _deleteItem(item);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('common.edit'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
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
    );
  }

  Widget _buildInventoryTab() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final totalCount = provider.items.length;
        final lowStockCount = provider.items.where((i) => i.isLowStock).length;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.checklist_rtl, color: Colors.blueAccent, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'inventory.reviziya_title'.tr(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'inventory.reviziya_desc'.tr(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$totalCount',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'inventory.col_name'.tr(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white10),
                      Column(
                        children: [
                          Text(
                            '$lowStockCount',
                            style: TextStyle(
                              color: lowStockCount > 0 ? Colors.redAccent : Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'inventory.low_stock'.tr(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        'inventory.tab_inventory'.tr(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReviziyaPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InventorySearchDelegate extends SearchDelegate<String?> {
  final List<dynamic> items;
  static final List<String> _searchHistory = [];

  InventorySearchDelegate(this.items);

  @override
  String get searchFieldLabel => 'inventory.search_hint'.tr();

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
    if (query.trim().isNotEmpty) {
      _searchHistory.remove(query.trim());
      _searchHistory.add(query.trim());
      if (_searchHistory.length > 10) {
        _searchHistory.removeAt(0); // keep only last 10
      }
    }
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: AppColors.background,
        child: _searchHistory.isEmpty
            ? Center(child: Text('common.search_history_empty'.tr(), style: const TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                itemCount: _searchHistory.length,
                itemBuilder: (context, index) {
                  final historyItem = _searchHistory.reversed.toList()[index];
                  return ListTile(
                    leading: const Icon(Icons.history, color: AppColors.textSecondary),
                    title: Text(historyItem, style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      query = historyItem;
                    },
                  );
                },
              ),
      );
    }
    return _buildList();
  }

  Widget _buildList() {
    final normalizedQuery = SearchUtils.normalize(query);
    
    final filteredItems = items.where((item) {
      final normalizedName = SearchUtils.normalize(item.name);
      final normalizedCategory = SearchUtils.normalize(item.category);
      return normalizedName.contains(normalizedQuery) || normalizedCategory.contains(normalizedQuery);
    }).toList();

    return Container(
      color: AppColors.background,
      child: filteredItems.isEmpty
          ? Center(child: Text('common.not_found'.tr(), style: const TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return ListTile(
                  title: Text(item.name, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(item.category, style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: Text('${item.quantity} ${item.unit}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  onTap: () {
                    close(context, item.id);
                  },
                );
              },
            ),
    );
  }
}
