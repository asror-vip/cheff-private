import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'reports.title'.tr(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onPressed: () {},
            )
          ],
        ),
        body: Column(
          children: [
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
                    Tab(text: 'reports.tab_standard'.tr()),
                    Tab(text: 'reports.tab_my_reports'.tr()),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Standard Reports
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildReportItem(context, Icons.bar_chart, 'reports.rep_sales'.tr(), Colors.blue, () => _openReportAction(context, 'reports.rep_sales'.tr())),
                      _buildReportItem(context, Icons.restaurant_menu, 'reports.rep_foodcost'.tr(), Colors.orange, () => _openReportAction(context, 'reports.rep_foodcost'.tr())),
                      _buildReportItem(context, Icons.shopping_cart, 'reports.rep_purchases'.tr(), Colors.green, () => _openReportAction(context, 'reports.rep_purchases'.tr())),
                      _buildReportItem(context, Icons.delete_outline, 'reports.rep_waste'.tr(), Colors.red, () => _openReportAction(context, 'reports.rep_waste'.tr())),
                      _buildReportItem(context, Icons.inventory_2, 'reports.rep_warehouse'.tr(), Colors.blueAccent, () => _openReportAction(context, 'reports.rep_warehouse'.tr())),
                      _buildReportItem(context, Icons.people, 'reports.rep_staff'.tr(), Colors.cyan, () => _openReportAction(context, 'reports.rep_staff'.tr())),
                      _buildReportItem(context, Icons.monetization_on, 'reports.rep_pnl'.tr(), Colors.amber, () => _openReportAction(context, 'reports.rep_pnl'.tr())),
                      _buildReportItem(context, Icons.fastfood, 'reports.rep_dishes_flow'.tr(), Colors.blue, () => _openReportAction(context, 'reports.rep_dishes_flow'.tr())),
                      _buildReportItem(context, Icons.sync_alt, 'reports.rep_money_flow'.tr(), Colors.green, () => _openReportAction(context, 'reports.rep_money_flow'.tr())),
                      _buildReportItem(context, Icons.download, 'reports.rep_export'.tr(), Colors.greenAccent, () => _openReportAction(context, 'reports.rep_export'.tr())),
                    ],
                  ),
                  // Tab 2: My Reports
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'common.no_data'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReportAction(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart, color: AppColors.success),
                title: Text('reports.export_excel'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.file_download, color: AppColors.textSecondary),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final excel = Excel.createExcel();
                    final sheet = excel['Sheet1'];
                    sheet.appendRow([TextCellValue('Hisobot:'), TextCellValue(title)]);
                    sheet.appendRow([TextCellValue('Sana:'), TextCellValue(DateTime.now().toString())]);
                    sheet.appendRow([TextCellValue('')]);
                    sheet.appendRow([TextCellValue('№'), TextCellValue('Nomi'), TextCellValue('Qiymati')]);
                    sheet.appendRow([IntCellValue(1), TextCellValue('Kirim'), IntCellValue(5000)]);
                    sheet.appendRow([IntCellValue(2), TextCellValue('Chiqim'), IntCellValue(2000)]);
                    
                    final fileBytes = excel.save();
                    if (fileBytes != null) {
                      final directory = await getTemporaryDirectory();
                      final file = File('${directory.path}/Hisobot_${DateTime.now().millisecondsSinceEpoch}.xlsx');
                      await file.writeAsBytes(fileBytes);
                      await Share.shareXFiles([XFile(file.path)], text: title);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                title: Text('reports.export_pdf'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.file_download, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('reports.export_success'.tr(args: [title])),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
