import 'dart:io';

void main() {
  final file = File('lib/features/inventory/domain/entities/inventory_item.dart');
  var content = file.readAsStringSync();
  if (!content.contains('isSemiFinished')) {
    content = content.replaceFirst('final bool isNew;', 'final bool isNew;\n  final bool isSemiFinished;');
    content = content.replaceFirst('this.isNew = false,', 'this.isNew = false,\n    this.isSemiFinished = false,');
    file.writeAsStringSync(content);
  }
}