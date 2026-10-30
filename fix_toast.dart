import 'dart:io';

void main() {
  final dir = Directory('D:/Desktop/bot/mobile/lib');
  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var original = content;
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*AppColors\.success,?\s*behavior:\s*SnackBarBehavior\.floating,?\s*\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showSuccess(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*AppColors\.error,?\s*behavior:\s*SnackBarBehavior\.floating,?\s*\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*AppColors\.success,?\s*\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showSuccess(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.green,?\s*\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showSuccess(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*AppColors\.error,?\s*\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.red,?\s*\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );
      
      content = content.replaceAllMapped(
        RegExp(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content:\s*Text\((.*?)\)\),?\s*\);', dotAll: true),
        (match) => 'ToastUtils.showError(context, ${match[1]});'
      );

      if (original != content) {
        if (!content.contains('ToastUtils')) {
            content = "import 'package:chefcontrol/core/utils/toast_utils.dart';\n" + content; 
        }
        file.writeAsStringSync(content);
        print('Updated ${file.path}');
      }
    }
  }
}
