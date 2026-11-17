import 'package:chefcontrol/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../providers/sales_provider.dart';
import 'package:provider/provider.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  DateTimeRange? _dateRange;

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateRange) {
      if (!mounted) return;
      setState(() {
        _dateRange = picked;
      });
      context.read<SalesProvider>().fetchSalesByRange(picked.start, picked.end);
    }
  }

  Future<void> _exportToExcel(dynamic summary) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([TextCellValue('Savdo Hisoboti')]);
      sheet.appendRow([TextCellValue('Jami tushum:'), IntCellValue(summary.totalRevenue.toInt())]);
      sheet.appendRow([TextCellValue('Cheklar soni:'), IntCellValue(summary.totalReceipts)]);
      sheet.appendRow([TextCellValue('O\'rtacha chek:'), IntCellValue(summary.averageReceipt.toInt())]);
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([TextCellValue('Top Taomlar')]);
      for (var dish in summary.topDishes) {
        sheet.appendRow([TextCellValue(dish.name), IntCellValue(dish.portions), IntCellValue(dish.sum.toInt())]);
      }
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/Savdo_${DateTime.now().millisecondsSinceEpoch}.xlsx');
        await file.writeAsBytes(fileBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Savdo Hisoboti'));
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Xato: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSalesByRange(_dateRange!.start, _dateRange!.end);
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
        title: Text('sales.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary), tooltip: 'common.refresh'.tr(), onPressed: () => context.read<SalesProvider>().fetchTodaySales(),
          )
        ],
      ),
      body: _buildSalesContent(),
    );
  }

  Widget _buildSalesContent() {
    return Consumer<SalesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
        }

        final summary = provider.summary;
        if (summary == null) {
          return Center(child: Text("common.no_data".tr(), style: const TextStyle(color: AppColors.textSecondary)));
        }

        final bool isPositive = summary.percentageChange >= 0;
        final String sign = isPositive ? '+' : '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
        // Date Range Picker
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateRange == null 
                    ? '' 
                    : '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM yyyy').format(_dateRange!.end)}', 
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)
                ),
                const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        
        // Main Revenue Card matching Screen #8
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sales.revenue'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      NumberFormat.currency(locale: 'ru', symbol: 'common.currency_sum'.tr(), decimalDigits: 0).format(summary.totalRevenue),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                             color: isPositive ? AppColors.success : AppColors.error, 
                             size: 13),
                        const SizedBox(width: 3),
                        Text('$sign${summary.percentageChange.toStringAsFixed(1)}%', 
                             style: TextStyle(color: isPositive ? AppColors.success : AppColors.error, 
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('sales.receipts'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${summary.totalReceipts}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.white10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('sales.avg_receipt'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(locale: 'ru', symbol: 'common.currency_sum'.tr(), decimalDigits: 0).format(summary.averageReceipt), 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // Gradient Bar Chart matching Screen #8
        Container(
          height: 190,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sales.revenue_by_time'.tr().isEmpty ? 'Выручка по дням' : 'sales.revenue_by_time'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < 7; i++)
                      Builder(
                        builder: (context) {
                          final double amount = (i < summary.dailyRevenues.length)
                              ? summary.dailyRevenues[i]
                              : 0.0;
                          final double maxRev = summary.dailyRevenues.fold(0.0, (m, v) => v > m ? v : m);
                          final double height = maxRev > 0
                              ? ((amount / maxRev) * 95).clamp(8.0, 95.0)
                              : 10.0;
                          return Container(
                            width: 24,
                            height: height,
                            decoration: BoxDecoration(
                              gradient: amount > 0 
                                  ? const LinearGradient(
                                      colors: [Color(0xFF246BFD), Color(0xFF00C6FF)],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )
                                  : null,
                              color: amount > 0 ? null : Colors.white.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('sales.day_mon'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('sales.day_tue'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('sales.day_wed'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('sales.day_thu'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('sales.day_fri'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('sales.day_sat'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('sales.day_sun'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Top Dishes
        Text(
          'sales.top_dishes'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...summary.topDishes.map((d) => _buildTopDish(d.name, d.portions, d.sum)),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _exportToExcel(summary),
            icon: const Icon(Icons.download_rounded, size: 20),
            label: Text('sales.download_report'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        )
      ],
    );
    });
  }


  Widget _buildTopDish(String name, int portions, double sum) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.catSales.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.catSales.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.catSales, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '$portions ${'sales.portions'.tr()}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${sum.toInt()} ${'common.currency_sum'.tr()}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


