import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/pos_provider.dart';
import '../../../../features/tables/presentation/pages/tables_page.dart';
import '../../../../features/tables/domain/entities/table_entity.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().fetchRecipes();
    });
  }

  TableEntity? _selectedTable;

  void _openTables() async {
    final table = await Navigator.push<TableEntity>(
      context,
      MaterialPageRoute(builder: (context) => const TablesPage()),
    );
    if (table != null) {
      setState(() {
        _selectedTable = table;
      });
      // In a real app, here you would load the cart/order associated with table.currentOrderId
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedTable == null ? 'pos.title'.tr() : '${'pos.title'.tr()} - ${_selectedTable!.name}', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_restaurant),
            tooltip: 'Stollar',
            onPressed: _openTables,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PosProvider>().fetchRecipes(background: true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top: Menu Grid
          Expanded(
            flex: 5,
            child: Consumer<PosProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.recipes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.recipes.isEmpty) {
                  return Center(child: Text('pos.dishes_not_found'.tr()));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: provider.recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = provider.recipes[index];
                    final price = (recipe['selling_price'] ?? 0).toDouble();
                    
                    return InkWell(
                      onTap: () => provider.addToCart(recipe),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withAlpha(50)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fastfood, size: 32, color: Colors.orangeAccent),
                            const SizedBox(height: 8),
                            Text(
                              recipe['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(locale: 'uz', symbol: 'common.currency_sum'.tr()).format(price),
                              style: const TextStyle(color: Colors.green, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Bottom: Cart
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.surface,
              child: Consumer<PosProvider>(
                builder: (context, provider, child) {
                  final cartItems = provider.cart.values.toList();
                  
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.deepOrange.withValues(alpha: 0.1),
                        width: double.infinity,
                        child: Text(
                          'pos.order'.tr(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: cartItems.isEmpty
                            ? Center(child: Text('pos.empty_cart'.tr(), style: const TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = cartItems[index];
                                  return ListTile(
                                    title: Text(item['name'], style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(NumberFormat.currency(locale: 'uz', symbol: 'common.currency_sum'.tr()).format(item['price'])),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () => provider.removeFromCart(item['recipe_id']),
                                        ),
                                        Text('${item['quantity']}'),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                          onPressed: () => provider.addToCart({'id': item['recipe_id'], 'name': item['name'], 'selling_price': item['price']}),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Checkout bottom panel
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('pos.total'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(
                                  NumberFormat.currency(locale: 'uz', symbol: 'common.currency_sum'.tr()).format(provider.totalAmount),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                        side: const BorderSide(color: Colors.orange),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: provider.cart.isEmpty ? null : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Aralash to\'lov / Chekni bo\'lish oynasi ochiladi')),
                                        );
                                      },
                                      icon: const Icon(Icons.splitscreen),
                                      label: const Text("Bo'lish"),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: provider.cart.isEmpty || provider.isLoading
                                          ? null
                                          : () async {
                                              final success = await provider.checkout();
                                              if (!context.mounted) return;
                                              if (success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('pos.payment_success'.tr()), backgroundColor: Colors.green),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(provider.error ?? 'common.error'.tr()), backgroundColor: Colors.red),
                                                );
                                              }
                                            },
                                      child: provider.isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text('pos.pay'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
