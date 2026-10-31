import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';

class CreateZagatovkaSheet extends StatefulWidget {
  const CreateZagatovkaSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const CreateZagatovkaSheet(),
    );
  }

  @override
  State<CreateZagatovkaSheet> createState() => _CreateZagatovkaSheetState();
}

class _CreateZagatovkaSheetState extends State<CreateZagatovkaSheet> {
  String? _selectedZagatovkaId;
  final TextEditingController _qtyController = TextEditingController();
  final Map<String, double> _ingredients = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = context.watch<InventoryProvider>();
    final allProducts = invProvider.items;

    // Filtrovka qilish (Zagatovkalar va Xomashyolar)
    final zagatovkas = allProducts.where((p) => p.product.isSemiFinished).toList();
    final rawMaterials = allProducts.where((p) => !p.product.isSemiFinished).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Zagatovka tayyorlash', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedZagatovkaId,
            dropdownColor: AppColors.surfaceLight,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Zagatovka turini tanlang',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
            ),
            items: zagatovkas.map((z) => DropdownMenuItem(value: z.product.id, child: Text('${z.product.name} (${z.product.unit})'))).toList(),
            onChanged: (val) => setState(() => _selectedZagatovkaId = val),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Tayyorlangan miqdor',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Ishlatilgan xomashyolar:', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ..._ingredients.entries.map((e) {
             final rm = rawMaterials.firstWhere((p) => p.product.id == e.key).product;
             return ListTile(
               title: Text(rm.name, style: const TextStyle(color: AppColors.textPrimary)),
               subtitle: Text('${e.value} ${rm.unit}', style: const TextStyle(color: AppColors.textSecondary)),
               trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _ingredients.remove(e.key))),
             );
          }),

          TextButton.icon(
            onPressed: () {
               showDialog(context: context, builder: (ctx) {
                  String? selId;
                  final qCtrl = TextEditingController();
                  return AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Xomashyo kiritish', style: TextStyle(color: AppColors.textPrimary)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          dropdownColor: AppColors.surfaceLight,
                          style: const TextStyle(color: AppColors.textPrimary),
                          items: rawMaterials.map((p) => DropdownMenuItem(value: p.product.id, child: Text(p.product.name))).toList(),
                          onChanged: (val) => selId = val,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: qCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Ishlatilgan miqdor'),
                        )
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
                      ElevatedButton(
                        onPressed: () {
                           if (selId != null && qCtrl.text.isNotEmpty) {
                              setState(() => _ingredients[selId!] = double.parse(qCtrl.text));
                              Navigator.pop(ctx);
                           }
                        },
                        child: const Text('Qo`shish')
                      )
                    ],
                  );
               });
            },
            icon: const Icon(Icons.add),
            label: const Text('Xomashyo kiritish'),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                 if (_selectedZagatovkaId == null || _qtyController.text.isEmpty || _ingredients.isEmpty) {
                   ToastUtils.showError(context, 'Hamma maydonlarni to`ldiring');
                   return;
                 }
                 ToastUtils.showSuccess(context, 'Zagatovka muvaffaqiyatli saqlandi! (UI demo)');
                 Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Saqlash va Ombordan yechish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}
