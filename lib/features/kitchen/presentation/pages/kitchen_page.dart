import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../domain/entities/kitchen_item_entity.dart';
import '../providers/kitchen_provider.dart';

class KitchenPage extends StatelessWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('kitchen.title'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Station Switcher
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            tooltip: 'Stansiyani o\'zgartirish',
            onSelected: (station) {
              context.read<KitchenProvider>().setStation(station);
              ToastUtils.showSuccess(context, 'Stansiya o\'zgartirildi: $station');
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'hot_kitchen', child: Text('Issiq Sex')),
              const PopupMenuItem(value: 'cold_kitchen', child: Text('Sovuq Sex / Salatlar')),
              const PopupMenuItem(value: 'bar', child: Text('Bar')),
            ],
          ),
        ],
      ),
      body: Consumer<KitchenProvider>(
        builder: (context, provider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              if (isMobile) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildColumn(
                        context,
                        title: 'Yuborilgan (Kutmoqda)',
                        items: provider.pendingItems,
                        color: Colors.redAccent,
                        actionLabel: 'kitchen.start_cooking'.tr(),
                        onAction: (item) => provider.updateItemStatus(item.id, OrderItemStatus.cooking),
                        actionColor: Colors.blueAccent,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 16),
                      _buildColumn(
                        context,
                        title: 'kitchen.cooking'.tr(),
                        items: provider.cookingItems,
                        color: Colors.blueAccent,
                        actionLabel: 'kitchen.mark_ready'.tr(),
                        onAction: (item) => provider.updateItemStatus(item.id, OrderItemStatus.ready),
                        actionColor: Colors.green,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 16),
                      _buildColumn(
                        context,
                        title: 'kitchen.ready'.tr(),
                        items: provider.readyItems,
                        color: Colors.green,
                        actionLabel: 'kitchen.finish'.tr(),
                        onAction: (item) {
                          // KDS dagi Tayyor ekranidan yo'qotish (xodim tortdi yoki oldi)
                           provider.updateItemStatus(item.id, OrderItemStatus.served);
                        },
                        actionColor: Colors.grey,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColumn(
                      context,
                      title: 'Yuborilgan (Kutmoqda)',
                      items: provider.pendingItems,
                      color: Colors.redAccent,
                      actionLabel: 'kitchen.start_cooking'.tr(),
                      onAction: (item) => provider.updateItemStatus(item.id, OrderItemStatus.cooking),
                      actionColor: Colors.blueAccent,
                      isMobile: isMobile,
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 1, thickness: 1),
                  Expanded(
                    child: _buildColumn(
                      context,
                      title: 'kitchen.cooking'.tr(),
                      items: provider.cookingItems,
                      color: Colors.blueAccent,
                      actionLabel: 'kitchen.mark_ready'.tr(),
                      onAction: (item) => provider.updateItemStatus(item.id, OrderItemStatus.ready),
                      actionColor: Colors.green,
                      isMobile: isMobile,
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 1, thickness: 1),
                  Expanded(
                    child: _buildColumn(
                      context,
                      title: 'kitchen.ready'.tr(),
                      items: provider.readyItems,
                      color: Colors.green,
                      actionLabel: 'kitchen.finish'.tr(), // Bu joyda oshpaz tayyorligini tasdiqlaganidan keyin ofitsiant olib ketgani
                      onAction: (item) {
                         provider.updateItemStatus(item.id, OrderItemStatus.served);
                      },
                      actionColor: Colors.grey,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required String title,
    required List<KitchenItemEntity> items,
    required Color color,
    required String actionLabel,
    required Function(KitchenItemEntity) onAction,
    required Color actionColor,
    required bool isMobile,
  }) {
    final columnContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: AppColors.surface,
          child: Text(
            '$title (${items.length})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'kitchen.empty'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: isMobile ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, items[index], color, actionLabel, () => onAction(items[index]), actionColor);
            },
          ),
      ],
    );

    if (isMobile) {
      return columnContent;
    } else {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: AppColors.surface,
            child: Text(
              '$title (${items.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                        'kitchen.empty'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(context, items[index], color, actionLabel, () => onAction(items[index]), actionColor);
                      },
                    ),
            ),
          ],
        );
    }
  }

  Widget _buildOrderCard(BuildContext context, KitchenItemEntity item, Color headerColor, String actionLabel, VoidCallback onAction, Color actionColor) {
    final minutesElapsed = DateTime.now().difference(item.createdAt).inMinutes;
    String timeStr = '${minutesElapsed}m';
    if (minutesElapsed == 0) timeStr = 'hozir';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: headerColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tableName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Chek #${item.orderNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (item.status == OrderItemStatus.sent) // Faqat yangilarda Rad etish bor
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppColors.error, size: 20),
                        tooltip: 'Rad etish (Stop-List)',
                        onPressed: () {
                           context.read<KitchenProvider>().rejectItem(item.id, 'Mahsulot tugagan');
                           ToastUtils.showError(context, 'Taom rad etildi');
                        },
                      ),
                    const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: minutesElapsed > 15 ? Colors.redAccent : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                if (item.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.comment,
                          style: const TextStyle(color: Colors.orange, fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ]
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 0),
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
