import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/finance_provider.dart';
import 'package:provider/provider.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().fetchFinance();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('finance.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'common.refresh'.tr(),
            onPressed: () => context.read<FinanceProvider>().fetchFinance(),
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'finance.income'.tr()),
                    Tab(text: 'finance.expenses'.tr()),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Consumer<FinanceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
                  }

                  final summary = provider.summary;
                  if (summary == null) {
                    return Center(child: Text('common.no_data'.tr(), style: const TextStyle(color: AppColors.textSecondary)));
                  }

                  final formatCurrency = NumberFormat.currency(locale: 'ru', symbol: 'common.currency_sum'.tr(), decimalDigits: 0);

                  return TabBarView(
                    children: [
                      // Income Tab
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildMetricCard('finance.revenue'.tr(), formatCurrency.format(summary.revenue), '${summary.revenueChange >= 0 ? '+' : ''}${summary.revenueChange}%', summary.revenueChange >= 0 ? AppColors.success : AppColors.error)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildMetricCard('finance.net_profit'.tr(), formatCurrency.format(summary.profit), '${summary.profitChange >= 0 ? '+' : ''}${summary.profitChange}%', summary.profit >= 0 ? AppColors.success : AppColors.error)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'finance.income_articles'.tr(),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (summary.revenue > 0)
                            _buildFinanceItem('finance.cat_revenue'.tr(), summary.revenue, true)
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('common.no_data'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                              ),
                            ),
                        ],
                      ),
                      // Expenses Tab
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildMetricCard('finance.expenses'.tr(), formatCurrency.format(summary.expenses), '${summary.expensesChange >= 0 ? '+' : ''}${summary.expensesChange}%', summary.expensesChange >= 0 ? AppColors.error : AppColors.success)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildMetricCard('finance.margin'.tr(), '${summary.margin.toStringAsFixed(1)}%', '${summary.marginChange >= 0 ? '+' : ''}${summary.marginChange}%', summary.margin >= 20 ? AppColors.success : AppColors.warning)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'finance.expense_structure'.tr(),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.blueAccent, width: 20),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: summary.expenseCategories.isEmpty
                                      ? Center(child: Text('common.no_data'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)))
                                      : Column(
                                          children: summary.expenseCategories.asMap().entries.map((entry) {
                                            const colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.teal, Colors.amber];
                                            final c = entry.value;
                                            final pct = summary.expenses > 0
                                                ? (c.amount / summary.expenses * 100).toStringAsFixed(1)
                                                : '0';
                                            return _buildLegendItem(
                                              colors[entry.key % colors.length],
                                              c.name,
                                              '$pct%',
                                            );
                                          }).toList(),
                                        ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'finance.expense_articles'.tr(),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...summary.expenseCategories.map((c) => _buildFinanceItem(c.name, c.amount, false)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _showAddTransactionModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTransactionModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('finance.new_transaction'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'finance.category_hint'.tr(),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'finance.amount_hint'.tr(),
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
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (title.isNotEmpty && amount > 0) {
                      await context.read<FinanceProvider>().addExpense(title, amount);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('finance.add'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          Text(percent, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String percent, Color percentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                percent.startsWith('+') ? Icons.arrow_upward : Icons.arrow_downward, 
                color: percentColor, 
                size: 14
              ),
              const SizedBox(width: 4),
              Text(percent, style: TextStyle(color: percentColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFinanceItem(String titleKey, double amount, bool isIncome) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titleKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isIncome ? '+' : '-'} ${amount.toInt()} ${'common.currency_sum'.tr()}',
            style: TextStyle(
              color: isIncome ? AppColors.success : AppColors.error,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
