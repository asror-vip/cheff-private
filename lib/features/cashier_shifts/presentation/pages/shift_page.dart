import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../providers/cashier_shifts_provider.dart';

class ShiftPage extends StatefulWidget {
  const ShiftPage({super.key});

  @override
  State<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierShiftsProvider>().checkActiveShift();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kassa Smenasi', style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CashierShiftsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final shift = provider.activeShift;

          if (shift == null) {
            // Smena ochiq emas - Ochish kerak
            return _buildOpenShift(provider);
          } else {
            // Smena ochiq - Yopish kerak
            return _buildCloseShift(provider);
          }
        },
      ),
    );
  }

  Widget _buildOpenShift(CashierShiftsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_open, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text(
            'Smenani ochish',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Kassadagi boshlang\'ich naqd pulni (razmenka) kiriting:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: 'so\'m',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(_amountController.text) ?? 0.0;
              final success = await provider.openShift(val);
              if (success && mounted) {
                ToastUtils.showSuccess(context, 'Smena muvaffaqiyatli ochildi');
                _amountController.clear();
              } else if (mounted && provider.error != null) {
                ToastUtils.showError(context, provider.error!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Smenani boshlash', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseShift(CashierShiftsProvider provider) {
    final shift = provider.activeShift!;
    final expectedCash = shift.expectedCash;
    final expectedCard = shift.expectedCard;

    final formatter = NumberFormat.currency(locale: 'uz', symbol: 'so\'m', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock, size: 60, color: Colors.orangeAccent),
          const SizedBox(height: 16),
          const Text(
            'Smenani yopish (Z-Otchyot)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildInfoRow('Boshlang\'ich qoldiq (Razmenka):', formatter.format(shift.initialCash)),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow('Kutilayotgan KARTA tushumi:', formatter.format(expectedCard), color: Colors.blueAccent),
                const SizedBox(height: 8),
                _buildInfoRow('Kutilayotgan NAQD tushum:', formatter.format(expectedCash), color: Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Kassadagi HAQIQIY NAQD pulni kiriting:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'Kassadagi naqd pul...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
            ),
            onChanged: (val) => setState(() {}),
          ),
          
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Izoh (Ixtiyoriy, masalan kamomad bo\'lsa)',
            ),
          ),

          const SizedBox(height: 32),
          
          Builder(
            builder: (context) {
              final actual = double.tryParse(_amountController.text) ?? 0.0;
              final diff = actual - expectedCash;
              Color diffColor = diff == 0 ? AppColors.success : (diff < 0 ? AppColors.error : AppColors.warning);
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: diffColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(diff == 0 ? 'Hammasi to\'g\'ri' : (diff < 0 ? 'Kamomad (-)' : 'Ortiqcha (+)'), style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formatter.format(diff), style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final actual = double.tryParse(_amountController.text) ?? 0.0;
              final success = await provider.closeShift(
                expectedCash: expectedCash,
                expectedCard: expectedCard,
                actualCash: actual,
                note: _noteController.text,
              );
              if (success && mounted) {
                ToastUtils.showSuccess(context, 'Smena yopildi (Z-otchyot saqlandi)');
                _amountController.clear();
                _noteController.clear();
              } else if (mounted && provider.error != null) {
                ToastUtils.showError(context, provider.error!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Z-Otchyot va Smenani Yopish', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color color = AppColors.textPrimary}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
