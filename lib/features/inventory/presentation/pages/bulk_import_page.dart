import 'package:chefcontrol/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';
import 'package:provider/provider.dart';

class BulkImportPage extends StatefulWidget {
  const BulkImportPage({super.key});

  @override
  State<BulkImportPage> createState() => _BulkImportPageState();
}

List<Map<String, dynamic>> _parseExcelInIsolate(String path) {
  final bytes = File(path).readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  List<Map<String, dynamic>> parsedRows = [];

  if (excel.tables.isNotEmpty) {
    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];
    
    if (table != null && table.rows.isNotEmpty) {
      int nameIdx = -1, catIdx = -1, qtyIdx = -1, unitIdx = -1;
      final headerRow = table.rows[0];
      int colCount = headerRow.length;
      
      // AI/Heuristic Approach: analyze the first 15 rows of data
      List<int> stringColumns = [];
      List<int> numericColumns = [];
      int maxRows = table.rows.length < 15 ? table.rows.length : 15;
      
      for (int c = 0; c < colCount; c++) {
        int strScore = 0;
        int numScore = 0;
        int unitScore = 0;
        
        for (int r = 1; r < maxRows; r++) {
          if (c >= table.rows[r].length) continue;
          final val = table.rows[r][c]?.value?.toString().trim() ?? '';
          if (val.isEmpty || val == 'null') continue;
          
          if (double.tryParse(val.replaceAll(',', '.')) != null) {
            numScore++;
          } else {
            strScore++;
            String vLower = val.toLowerCase();
            if (['кг', 'шт', 'л', 'г', 'гр', 'порц', 'упак', 'kg', 'litr', 'dona'].contains(vLower)) {
              unitScore += 5;
            }
          }
        }
        
        if (unitScore >= 3 || (unitScore > 0 && unitScore >= strScore)) {
          unitIdx = c;
        } else if (strScore > numScore) {
          stringColumns.add(c);
        } else if (numScore > 0 && numScore >= strScore) {
          numericColumns.add(c);
        }
      }
      
      // Determine Category vs Name from String columns
      // Logic: Categories repeat (low unique count), Names don't (high unique count)
      if (stringColumns.isNotEmpty) {
        if (stringColumns.length == 1) {
          nameIdx = stringColumns[0];
        } else {
          int minUniques = 9999;
          int maxUniques = -1;
          for (int c in stringColumns) {
            Set<String> uniques = {};
            for (int r = 1; r < maxRows; r++) {
               if (c < table.rows[r].length) {
                 final val = table.rows[r][c]?.value?.toString().trim() ?? '';
                 if (val.isNotEmpty) uniques.add(val);
               }
            }
            if (uniques.length <= minUniques && uniques.isNotEmpty) {
               minUniques = uniques.length;
               catIdx = c;
            }
            if (uniques.length > maxUniques) {
               maxUniques = uniques.length;
               nameIdx = c;
            }
          }
          if (catIdx == nameIdx) {
             catIdx = stringColumns[0];
             nameIdx = stringColumns[1];
          }
        }
      }
      
      // Determine Quantity from Numeric columns
      // Logic: If a column has huge numbers (like > 1000), it's probably Price, not Quantity.
      if (numericColumns.isNotEmpty) {
        for (int c in numericColumns) {
           bool isHugeNumber = false;
           for (int r = 1; r < maxRows; r++) {
              if (c < table.rows[r].length) {
                 final valStr = table.rows[r][c]?.value?.toString().replaceAll(',', '.') ?? '0';
                 final val = double.tryParse(valStr) ?? 0.0;
                 if (val > 2000) { // If value is over 2000, it's definitely a price (e.g. 15000 UZS)
                    isHugeNumber = true;
                    break;
                 }
              }
           }
           if (!isHugeNumber) {
              qtyIdx = c;
              break;
           }
        }
      }
      
      // Fallbacks if heuristic fails
      if (nameIdx == -1) nameIdx = 0;
      if (catIdx == -1) catIdx = 1;
      if (qtyIdx == -1) qtyIdx = 2;
      if (unitIdx == -1) unitIdx = 3;

      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;
        
        final nameVal = nameIdx < row.length ? row[nameIdx]?.value?.toString() : null;
        if (nameVal == null || nameVal.trim().isEmpty || nameVal == 'null') continue;
        
        final rawQty = qtyIdx < row.length ? (row[qtyIdx]?.value?.toString() ?? '0') : '0';
        
        parsedRows.add({
          'name': nameVal.trim(),
          'category': catIdx < row.length ? (row[catIdx]?.value?.toString() ?? 'Kategoriyasiz') : 'Kategoriyasiz',
          'quantity': double.tryParse(rawQty.replaceAll(',', '.')) ?? 0.0,
          'unit': unitIdx < row.length ? (row[unitIdx]?.value?.toString() ?? 'dona') : 'dona',
        });
      }
    }
  }
  return parsedRows;
}

class _BulkImportPageState extends State<BulkImportPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _isEditing = false;
  bool _isLoading = false;

  Future<void> _pickAndParseExcel() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        setState(() => _isLoading = true);

        // Move heavy parsing to a separate isolate
        final parsedRows = await compute(_parseExcelInIsolate, result.first.path!);

        setState(() {
          _rows = parsedRows;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError(context, '${'common.error'.tr()}: $e');
      }
    }
  }

  void _addNewRow() {
    setState(() {
      _rows.add({
        'name': '',
        'category': 'Kategoriyasiz',
        'quantity': 0.0,
        'unit': 'dona',
      });
    });
  }

  Future<void> _saveToDatabase() async {
    // Filter valid rows
    final validRows = _rows.where((r) => r['name'].toString().trim().isNotEmpty).toList();
    if (validRows.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final provider = context.read<InventoryProvider>();
      
      final productsToInsert = validRows.map((r) => {
        'name': r['name'],
        'category': r['category'],
        'unit': r['unit'],
        'minimumStock': 5.0,
        'initialStock': r['quantity'],
        'costPrice': 0.0,
      }).toList();
      
      await provider.addProductsBulk(productsToInsert);
      
      if (mounted) {
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '${'common.error'.tr()}: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('inventory.excel_import_title'.tr(), style: const TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, color: AppColors.success),
            tooltip: 'inventory.upload_excel'.tr(),
            onPressed: _pickAndParseExcel,
          ),
          TextButton(
            onPressed: _rows.isEmpty || _isLoading ? null : _saveToDatabase,
            child: Text('common.save'.tr(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              if (_rows.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.table_view, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'inventory.table_empty_hint'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _pickAndParseExcel,
                          icon: const Icon(Icons.file_upload),
                          label: Text('inventory.excel_upload'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 800,
                      child: Column(
                        children: [
                          Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('inventory.col_name'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('inventory.col_category'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('inventory.col_quantity'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('inventory.col_unit'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                SizedBox(width: 50, child: Text('inventory.col_action'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _rows.length,
                              itemBuilder: (context, idx) {
                                final row = _rows[idx];
                                return Container(
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3, 
                                        child: _isEditing 
                                          ? TextFormField(
                                              initialValue: row['name'],
                                              style: const TextStyle(color: AppColors.textPrimary),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                                              onChanged: (v) => row['name'] = v,
                                            )
                                          : Text(row['name'], style: const TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2, 
                                        child: _isEditing 
                                          ? TextFormField(
                                              initialValue: row['category'],
                                              style: const TextStyle(color: AppColors.textPrimary),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                                              onChanged: (v) => row['category'] = v,
                                            )
                                          : Text(row['category'], style: const TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2, 
                                        child: _isEditing 
                                          ? TextFormField(
                                              initialValue: row['quantity'].toString(),
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(color: AppColors.textPrimary),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                                              onChanged: (v) => row['quantity'] = double.tryParse(v) ?? 0.0,
                                            )
                                          : Text(row['quantity'].toString(), style: const TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2, 
                                        child: _isEditing 
                                          ? TextFormField(
                                              initialValue: row['unit'],
                                              style: const TextStyle(color: AppColors.textPrimary),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                                              onChanged: (v) => row['unit'] = v,
                                            )
                                          : Text(row['unit'], style: const TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 50,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: AppColors.error),
                                          onPressed: () {
                                            setState(() {
                                              _rows.removeAt(idx);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      floatingActionButton: _isEditing ? FloatingActionButton(
        onPressed: _addNewRow,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}
