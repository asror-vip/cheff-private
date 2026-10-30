import 'dart:io';

void main() {
  final files = [
    'lib/features/purchases/presentation/pages/purchases_page.dart',
    'lib/features/recipes/presentation/pages/recipe_detail_page.dart'
  ];
  
  for (var f in files) {
    final file = File('D:/Desktop/bot/mobile/' + f);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*AppColors\.success.*?\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showSuccess(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*AppColors\.error.*?\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.redAccent.*?\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.orange.*?\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content:\s*Text\((.*?)\)\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );

      if (!content.contains('ToastUtils')) {
        content = "import '../../../../core/utils/toast_utils.dart';\n" + content;
      }
      
      file.writeAsStringSync(content);
    }
  }
}
