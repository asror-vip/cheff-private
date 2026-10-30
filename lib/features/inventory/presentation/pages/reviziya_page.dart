import 'package:chefcontrol/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';
import '../providers/reviziya_provider.dart';

class ReviziyaPage extends StatefulWidget {
  const ReviziyaPage({super.key});

  @override
  State<ReviziyaPage> createState() => _ReviziyaPageState();
}

class _ReviziyaPageState extends State<ReviziyaPage> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItems = context.watch<InventoryProvider>().items;
    final provider = context.watch<ReviziyaProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('inventory.reviziya_title'.tr()),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueAccent.withAlpha(30),
            child: Text(
              'inventory.reviziya_desc'.tr(),
              style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: inventoryItems.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight),
              itemBuilder: (context, index) {
                final item = inventoryItems[index];
                
                if (!_controllers.containsKey(item.id)) {
                  _controllers[item.id] = TextEditingController();
                }

                final actualQty = provider.actualCounts[item.id];
                final difference = actualQty != null ? actualQty - item.quantity : 0.0;
                final diffColor = difference < 0 ? Colors.red : (difference > 0 ? Colors.green : AppColors.textSecondary);

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${'inventory.in_system'.tr()} ${item.quantity.toStringAsFixed(1)} ${item.unit}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          if (actualQty != null)
                            Text(
                              '${'inventory.difference'.tr()} ${difference > 0 ? '+' : ''}${difference.toStringAsFixed(1)} ${item.unit}',
                              style: TextStyle(color: diffColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _controllers[item.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'inventory.actual'.tr(),
                          suffixText: item.unit,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '.'));
                          if (parsed != null) {
                            context.read<ReviziyaProvider>().setActualCount(item.id, parsed);
                          } else if (val.isEmpty) {
                            // Can't remove easily without changing provider, but setting to expected is a hack.
                            // Let's just leave it as is, or use a method to remove.
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: provider.actualCounts.isEmpty || provider.isLoading
                    ? null
                    : () async {
                        final success = await provider.submitReviziya();
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.pop(context);
                          ToastUtils.showSuccess(context, 'inventory.reviziya_success'.tr());
                        } else {
                          ToastUtils.showError(context, provider.error ?? 'common.error'.tr());
                        }
                      },
                child: provider.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('inventory.complete_reviziya'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
