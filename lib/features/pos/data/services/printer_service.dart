import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    try {
      return await _printer.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      final isConnected = await _printer.isConnected;
      if (isConnected == true) {
        await _printer.disconnect();
      }
      return await _printer.connect(device) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    return await _printer.disconnect() ?? false;
  }

  Future<bool> get isConnected async {
    return await _printer.isConnected ?? false;
  }

  Future<void> printReceipt({
    required String restaurantName,
    required String cashierName,
    required String orderName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required Map<String, double> payments,
  }) async {
    if (!(await isConnected)) {
      throw Exception('Printerga ulanmagan!');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // final currency = 'uzs';
    final formatter = NumberFormat.currency(locale: 'uz', symbol: '', decimalDigits: 0);

    // Header
    bytes += generator.text(restaurantName, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.emptyLines(1);

    bytes += generator.text('Kassir: $cashierName', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}', styles: const PosStyles(align: PosAlign.left));
    if (orderName.isNotEmpty) {
       bytes += generator.text('Buyurtma/Stol: $orderName', styles: const PosStyles(align: PosAlign.left));
    }

    bytes += generator.hr();

    // Items
    for (var item in items) {
      final name = item['name'].toString();
      final qty = item['quantity'].toString();
      final price = (item['price'] as num).toDouble();
      final total = (item['quantity'] as num) * price;

      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.left));
      bytes += generator.row([
        PosColumn(text: '$qty x ${formatter.format(price)}', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: formatter.format(total), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(text: 'JAMI:', width: 6, styles: const PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2)),
      PosColumn(text: formatter.format(totalAmount), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);

    bytes += generator.emptyLines(1);

    // Payments
    if (payments.isNotEmpty) {
      bytes += generator.text('Tolov usuli:', styles: const PosStyles(align: PosAlign.center, bold: true));
      payments.forEach((method, amount) {
        String methodStr = method;
        if (method == 'cash') methodStr = 'Naqd';
        if (method == 'card') methodStr = 'Karta';
        if (method == 'transfer') methodStr = 'Ot\'kazma';

        bytes += generator.row([
          PosColumn(text: methodStr, width: 6, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: formatter.format(amount), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      });
    }

    bytes += generator.emptyLines(1);
    bytes += generator.text('Xaridingiz uchun rahmat!', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(2);

    // Print!
    _printer.writeBytes(Uint8List.fromList(bytes));
  }
}
