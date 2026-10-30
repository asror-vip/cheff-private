import 'dart:io';

void main() {
  final files = [
    'lib/features/orders/domain/entities/order_entity.dart',
    'lib/features/orders/data/repositories/orders_repository.dart',
    'lib/features/orders/presentation/providers/orders_provider.dart',
    'lib/features/orders/presentation/pages/waiter_order_page.dart',
    'lib/features/tables/data/repositories/tables_repository.dart',
    'lib/features/tables/domain/entities/table_entity.dart'
  ];
  
  for (var f in files) {
    final file = File('D:/Desktop/bot/mobile/' + f);
    if (file.existsSync()) {
      file.deleteSync();
      print('Deleted ' + f);
    }
  }
}
