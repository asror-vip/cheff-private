import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_provider.dart';
import '../../../recipes/presentation/providers/recipes_provider.dart';

class WaiterOrderPage extends StatefulWidget {
  const WaiterOrderPage({super.key});

  @override
  State<WaiterOrderPage> createState() => _WaiterOrderPageState();
}

class _WaiterOrderPageState extends State<WaiterOrderPage> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipesProvider>().fetchRecipes(background: true);
    });
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Consumer<RecipesProvider>(
              builder: (context, provider, child) {
                final recipes = provider.recipes;
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      width: double.infinity,
                      child: Text('Menyu', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: recipes.isEmpty 
                        ? Center(child: Text('Menyuda taomlar yo\'q', style: const TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.all(8),
                            itemCount: recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = recipes[index];
                              return Card(
                                color: AppColors.surface,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Text(recipe.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                  subtitle: Text('${recipe.sellingPrice} so\'m', style: const TextStyle(color: AppColors.textSecondary)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                                    onPressed: () {
                                      context.read<OrdersProvider>().addDraftItem(
                                        recipeId: recipe.id,
                                        name: recipe.name,
                                        price: recipe.sellingPrice,
                                        station: recipe.category.toLowerCase().contains('ichimlik') ? 'bar' : 'hot_kitchen',
                                      );
                                      ToastUtils.showSuccess(context, '${recipe.name} savatga qo\'shildi');
                                    },
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
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, child) {
        final order = provider.currentOrder;
        
        if (provider.isLoading || order == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final draftItems = order.items.where((i) => i.status == OrderItemStatus.draft).toList();
        final sentItems = order.items.where((i) => i.status != OrderItemStatus.draft && i.status != OrderItemStatus.cancelled).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                provider.exitOrder();
                Navigator.pop(context);
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.tableName ?? 'Stol', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Chek #${order.id.substring(0, 4).toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: AppColors.warning),
                tooltip: 'Hisob so\'rash (Pre-chek)',
                onPressed: () {
                   ToastUtils.showSuccess(context, 'Pre-chek chiqarishga yuborildi');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Yuborilgan Taomlar (Oshxonada/Tayyor)
              if (sentItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: const Text('Buyurtma qilingan taomlar', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sentItems.length,
                    itemBuilder: (context, index) {
                      return _buildSentItemCard(sentItems[index]);
                    },
                  ),
                ),
              ],
              
              // Savatdagi Taomlar (Yuborilmagan - Draft)
              if (draftItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: const Text('Savat (Oshxonaga yuborilmagan)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: draftItems.length,
                    itemBuilder: (context, index) {
                      return _buildDraftItemCard(draftItems[index], provider);
                    },
                  ),
                ),
              ],

              if (sentItems.isEmpty && draftItems.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Buyurtma bo\'sh. Pastdagi tugma orqali taom qo\'shing.', 
                      style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                
              // Pastki panel (Jami summa va yuborish)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jami summa:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            Text('${order.subtotal} so\'m', style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: draftItems.isEmpty ? null : () async {
                          final success = await provider.sendDraftsToKitchen();
                          if (success && context.mounted) {
                            ToastUtils.showSuccess(context, 'Oshxonaga yuborildi!');
                          } else if (context.mounted) {
                            ToastUtils.showError(context, provider.error ?? 'Xatolik');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Yuborish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showMenuBottomSheet(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            label: const Text('Menyu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildSentItemCard(OrderItemEntity item) {
    Color statusColor;
    String statusText;
    switch (item.status) {
      case OrderItemStatus.sent:
        statusColor = Colors.blue;
        statusText = 'Oshxonada';
        break;
      case OrderItemStatus.cooking:
        statusColor = Colors.orange;
        statusText = 'Pishirilmoqda';
        break;
      case OrderItemStatus.ready:
        statusColor = Colors.green;
        statusText = 'Tayyor';
        break;
      case OrderItemStatus.served:
        statusColor = Colors.grey;
        statusText = 'Tortildi';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Noma`lum';
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('${item.quantity} x ${item.price} so\'m', style: const TextStyle(color: AppColors.textSecondary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDraftItemCard(OrderItemEntity item, OrdersProvider provider) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 1), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${item.price} so\'m', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.redAccent),
                    onPressed: () => provider.updateDraftItemQuantity(item.id, -1),
                  ),
                  Text('${item.quantity}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => provider.updateDraftItemQuantity(item.id, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
