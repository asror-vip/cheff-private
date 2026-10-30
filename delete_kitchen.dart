import 'dart:io';

void main() {
  final files = [
    'lib/features/kitchen/domain/entities/kitchen_order.dart',
    'lib/features/kitchen/presentation/providers/kitchen_provider.dart',
    'lib/features/kitchen/presentation/pages/kitchen_page.dart'
  ];
  
  for (var f in files) {
    final file = File('D:/Desktop/bot/mobile/' + f);
    if (file.existsSync()) {
      file.deleteSync();
      print('Deleted ' + f);
    }
  }
}
