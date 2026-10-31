import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pos/data/services/printer_service.dart';
import '../../../../core/utils/toast_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsSheet extends StatefulWidget {
  const PrinterSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PrinterSettingsSheet(),
    );
  }

  @override
  State<PrinterSettingsSheet> createState() => _PrinterSettingsSheetState();
}

class _PrinterSettingsSheetState extends State<PrinterSettingsSheet> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    setState(() => _isLoading = true);
    try {
      _devices = await _printerService.getDevices();
      _isConnected = await _printerService.isConnected;

      final prefs = await SharedPreferences.getInstance();
      final savedMac = prefs.getString('saved_printer_mac');
      if (savedMac != null && _devices.isNotEmpty) {
         try {
           _selectedDevice = _devices.firstWhere((d) => d.address == savedMac);
         } catch (_) {}
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    final success = await _printerService.connect(device);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_printer_mac', device.address ?? '');
      if (mounted) ToastUtils.showSuccess(context, 'Printerga ulandi: ${device.name}');
    } else {
      if (mounted) ToastUtils.showError(context, 'Printerga ulanib bolmadi');
    }
    await _initPrinter();
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _printerService.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_printer_mac');
    if (mounted) ToastUtils.showSuccess(context, 'Printerdan uzildi');
    await _initPrinter();
  }

  Future<void> _testPrint() async {
    try {
       await _printerService.printReceipt(
         restaurantName: 'ChefControl Test',
         cashierName: 'Test Kassir',
         orderName: 'Test Stol',
         items: [
           {'name': 'Test Taom 1', 'quantity': 1, 'price': 15000},
           {'name': 'Test Taom 2', 'quantity': 2, 'price': 10000},
         ],
         totalAmount: 35000,
         payments: {'cash': 35000},
       );
    } catch (e) {
       ToastUtils.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Printer sozlamalari',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
          else if (_devices.isEmpty)
             const Center(
               child: Padding(
                 padding: EdgeInsets.all(20.0),
                 child: Text('Ushbu qurilmada boglangan Bluetooth printerlar topilmadi. Telefon sozlamalaridan printerni ulang.', textAlign: TextAlign.center)
               )
             )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.withOpacity(0.1) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isConnected ? Colors.green : Colors.white10),
              ),
              child: Row(
                children: [
                   Icon(Icons.print, color: _isConnected ? Colors.green : Colors.grey),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text('Holati: ${_isConnected ? 'Ulandi' : 'Uzilgan'}', style: TextStyle(color: _isConnected ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                          if (_selectedDevice != null)
                             Text(_selectedDevice!.name ?? 'Nomalum', style: const TextStyle(color: AppColors.textPrimary)),
                       ],
                     ),
                   ),
                   if (_isConnected)
                     TextButton(
                       onPressed: _disconnect,
                       child: const Text('Uzish', style: TextStyle(color: Colors.red)),
                     ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Mavjud printerlar:', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final isSelected = _selectedDevice?.address == device.address;
                  return ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(device.name ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(device.address ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: isSelected && _isConnected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _connect(device),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLight),
                            child: const Text('Ulanish'),
                          ),
                  );
                },
              ),
            ),
            if (_isConnected) ...[
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton.icon(
                   onPressed: _testPrint,
                   icon: const Icon(Icons.receipt_long),
                   label: const Text('Test Chek Chiqarish'),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.blueAccent,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 12)
                   ),
                 ),
               ),
            ]
          ]
        ],
      ),
    );
  }
}