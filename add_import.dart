import 'dart:io';

void main() {
  final files = [
    'lib/features/ai_assistant/presentation/widgets/telegram_chat_bubble.dart',
    'lib/features/inventory/presentation/pages/bulk_import_page.dart',
    'lib/features/inventory/presentation/pages/reviziya_page.dart',
    'lib/features/sales/presentation/pages/sales_page.dart',
    'lib/features/settings/presentation/widgets/profile_edit_sheet.dart',
    'lib/features/staff/presentation/pages/staff_page.dart',
    'lib/features/reports/presentation/pages/reports_page.dart'
  ];
  for (var f in files) {
    final file = File('D:/Desktop/bot/mobile/' + f);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      if (!content.contains('toast_utils.dart')) {
        content = "import 'package:chefcontrol/core/utils/toast_utils.dart';\n" + content;
        file.writeAsStringSync(content);
        print('Added to ' + f);
      }
    }
  }
}
