import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const LanguageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('settings.select_language'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, 'settings.lang_uz_latin'.tr(), const Locale('uz')),
          _buildOption(context, 'settings.lang_uz_cyrl'.tr(), const Locale('uz', 'Cyrl')),
          _buildOption(context, 'settings.lang_ru'.tr(), const Locale('ru')),
          _buildOption(context, 'settings.lang_en'.tr(), const Locale('en')),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, Locale locale) {
    final isSelected = context.locale == locale;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blueAccent) : null,
      onTap: () async {
        await context.setLocale(locale);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }
}
