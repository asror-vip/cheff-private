import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order.dart';
import '../providers/purchases_provider.dart';
import 'package:provider/provider.dart';
import '../../data/services/ai_scanner_service.dart';
import 'create_request_page.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AiScannerService _aiScanner = AiScannerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Default to "Накладные"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchasesProvider>();
      if (provider.orders.isEmpty) {
        provider.fetchPurchases();
      }
    });
  }

  Future<void> _scanInvoice({String? existingPurchaseId}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1024,
    ); // Or camera
    
    if (pickedFile == null) return;
    if (!mounted) return;
    
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                "purchases.ai_reading".tr(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final file = File(pickedFile.path);
      List<Map<String, dynamic>> items = await _aiScanner.scanInvoice(file);
      
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (items.isEmpty) {
        throw Exception("purchases.ai_empty".tr());
      }
      
      // Show confirmation dialog
      _showConfirmationDialog(items, file, existingPurchaseId: existingPurchaseId);
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${"purchases.error".tr()}: $e'), backgroundColor: AppColors.error, duration: const Duration(seconds: 10)),
      );
    }
  }

  void _showEditItemDialog(BuildContext context, Map<String, dynamic> item, VoidCallback onSave) {
    final nameController = TextEditingController(text: item['name']?.toString() ?? '');
    final qtyController = TextEditingController(text: item['quantity']?.toString() ?? '1');
    final priceController = TextEditingController(text: item['price']?.toString() ?? '0');
    final unitController = TextEditingController(text: item['unit']?.toString() ?? 'kg');

    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('common.edit'.tr(), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'purchases.product_name_hint'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'purchases.quantity'.tr(),
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: unitController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Birlik',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Narx (${'common.currency_sum'.tr()})',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 1.0;
                final price = double.tryParse(priceController.text) ?? 0.0;
                item['name'] = nameController.text.trim();
                item['quantity'] = qty;
                item['price'] = price;
                item['unit'] = unitController.text.trim();
                onSave();
                Navigator.pop(dlgContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('common.save'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(List<Map<String, dynamic>> items, File file, {String? existingPurchaseId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            double currentTotal = 0;
            for (var item in items) {
              currentTotal += ((item['quantity'] ?? 0) as num).toDouble() * ((item['price'] ?? 0) as num).toDouble();
            }

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('purchases.ai_confirm'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                        tooltip: 'Qo\'shish',
                        onPressed: () {
                          final newItem = {'name': '', 'quantity': 1.0, 'unit': 'kg', 'price': 0.0};
                          _showEditItemDialog(modalCtx, newItem, () {
                            if ((newItem['name'] as String).isNotEmpty) {
                              setModalState(() {
                                items.add(newItem);
                              });
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${"purchases.total_sum".tr()}: ${currentTotal.toStringAsFixed(0)} ${'common.currency_sum'.tr()}', style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: items.isEmpty
                          ? Center(child: Text('purchases.no_items_in_invoice'.tr(), style: const TextStyle(color: Colors.black54)))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (itemCtx, index) {
                                final item = items[index];
                                final q = ((item['quantity'] ?? 0) as num).toDouble();
                                final p = ((item['price'] ?? 0) as num).toDouble();
                                final rowSum = q * p;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('${index + 1}. ', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['name'].toString(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                            Text('$q ${item['unit']} x $p ${'common.currency_sum'.tr()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text(rowSum.toStringAsFixed(0), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                        onPressed: () {
                                          _showEditItemDialog(modalCtx, item, () {
                                            setModalState(() {});
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        onPressed: () {
                                          setModalState(() {
                                            items.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('purchases.cancel'.tr(), style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: items.isEmpty ? null : () async {
                            try {
                              Navigator.pop(modalCtx);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogCtx) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                              );
                              await context.read<PurchasesProvider>().saveAIPurchase(items, imageFile: file, existingPurchaseId: existingPurchaseId);
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('purchases.saved_successfully'.tr()), backgroundColor: AppColors.success),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${"purchases.save_error".tr()}: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('purchases.confirm'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _createNewRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRequestPage()),
    );
  }

  Future<Map<String, dynamic>> _fetchDetailsAndImage(BuildContext context, String purchaseId) async {
    final provider = context.read<PurchasesProvider>();
    final items = await provider.getPurchaseDetails(purchaseId);
    final imageUrl = await provider.getPurchaseDocumentUrl(purchaseId);
    return {
      'items': items,
      'imageUrl': imageUrl,
    };
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
        title: Text('purchases.title'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
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
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'purchases.tab_requests'.tr()),
                  Tab(text: 'purchases.tab_invoices'.tr()),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(),
                _buildInvoicesList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final isInvoiceTab = _tabController.animation!.value.round() == 1;
          return isInvoiceTab
              ? FloatingActionButton.extended(
                  onPressed: _scanInvoice,
                  backgroundColor: Colors.blueAccent,
                  icon: const Icon(Icons.document_scanner, color: Colors.white),
                  label: Text('purchases.ai_scanner'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : FloatingActionButton.extended(
                  onPressed: _createNewRequest,
                  backgroundColor: AppColors.success,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('purchases.new_request'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
        },
      ),
    );
  }

  Widget _buildRequestsList() {
    return Consumer<PurchasesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
        }

        final requestsList = provider.orders.where((o) => o.status == OrderStatus.active).toList();

        if (requestsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  "purchases.no_requests".tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "purchases.add_request_hint".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requestsList.length,
          itemBuilder: (context, index) {
            final order = requestsList[index];
            
            return InkWell(
              onTap: () => _showPurchaseDetails(context, order),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id.substring(0, 8)} • ${order.date}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.supplierName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${order.totalAmount.toInt()} ${"purchases.currency".tr()}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'purchases.status_expected'.tr(),
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoicesList() {
    return Consumer<PurchasesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
        }

        final invoicesList = provider.orders.where((o) => o.status == OrderStatus.delivered).toList();

        if (invoicesList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  "purchases.no_invoices".tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "purchases.add_invoice_hint".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoicesList.length,
          itemBuilder: (context, index) {
            final order = invoicesList[index];
            
            return InkWell(
              onTap: () => _showPurchaseDetails(context, order),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id.substring(0, 8)} • ${order.date}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.supplierName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${order.totalAmount.toInt()} ${"purchases.currency".tr()}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'purchases.status_delivered'.tr(),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPurchaseDetails(BuildContext context, PurchaseOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${"purchases.invoice".tr()} #${order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (order.status == OrderStatus.active)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _fetchDetailsAndImage(context, order.id).then((data) {
                                final items = (data['items'] as List).map((i) {
                                  return {
                                    'name': i['products']?['name'] ?? '',
                                    'quantity': i['quantity'] ?? 0,
                                    'unit': i['unit'] ?? 'kg',
                                  };
                                }).toList();
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CreateRequestPage(initialOrder: order, initialItems: items)),
                                );
                              });
                            },
                          ),
                        if (order.status == OrderStatus.active)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: Text('purchases.confirm_delete_title'.tr(), style: const TextStyle(color: Colors.white)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                if (context.mounted) {
                                  context.read<PurchasesProvider>().deleteRequest(order.id);
                                }
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _fetchDetailsAndImage(context, order.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('purchases.data_load_error'.tr(), style: const TextStyle(color: AppColors.error)),
                          );
                        }
                        final data = snapshot.data ?? {};
                        final items = data['items'] as List<Map<String, dynamic>>? ?? [];
                        final imageUrl = data['imageUrl'] as String?;
                        
                        if (items.isEmpty && imageUrl == null) {
                          return Center(
                            child: Text('purchases.no_items_in_invoice'.tr(), style: const TextStyle(color: Colors.grey)),
                          );
                        }
                        return ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (imageUrl != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFBF7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'purchases.items_list'.tr(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(color: Colors.black38, thickness: 1),
                                  ...items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final productName = item['products']?['name'] ?? 'purchases.unknown_product'.tr();
                                    final quantity = item['quantity'];
                                    final unit = item['unit'];
                                    final unitPrice = item['unit_price'];
                                    final totalPrice = item['total_price'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${index + 1}. ', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(productName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                                Text('$quantity $unit x ${unitPrice.toInt()} ${'common.currency_sum'.tr()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Text('${totalPrice.toInt()} ${'common.currency_sum'.tr()}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (order.status == OrderStatus.active)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _scanInvoice(existingPurchaseId: order.id);
                        },
                        icon: const Icon(Icons.document_scanner, color: Colors.white),
                        label: Text('purchases.scan_invoice'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

