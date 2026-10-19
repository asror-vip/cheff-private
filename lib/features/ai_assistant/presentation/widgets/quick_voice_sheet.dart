import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class QuickVoiceSheet extends StatelessWidget {
  final Function(String command) onSelectCommand;

  const QuickVoiceSheet({
    super.key,
    required this.onSelectCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                'ai_assistant.quick_commands'.tr(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCommandTile(
                    context,
                    icon: Icons.soup_kitchen,
                    iconColor: Colors.deepOrange,
                    title: 'ai_assistant.command_produce_sample'.tr(),
                    subtitle: 'ai_assistant.sample_produce_desc'.tr(),
                  ),
                  _buildCommandTile(
                    context,
                    icon: Icons.inventory_2,
                    iconColor: Colors.blueAccent,
                    title: 'ai_assistant.command_stock_sample'.tr(),
                    subtitle: 'ai_assistant.sample_stock_desc'.tr(),
                  ),
                  _buildCommandTile(
                    context,
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.deepOrangeAccent,
                    title: 'ai_assistant.command_low_stock'.tr(),
                    subtitle: 'ai_assistant.sample_low_stock_desc'.tr(),
                  ),
                  _buildCommandTile(
                    context,
                    icon: Icons.point_of_sale,
                    iconColor: Colors.green,
                    title: 'ai_assistant.command_sales_sample'.tr(),
                    subtitle: 'ai_assistant.sample_sales_desc'.tr(),
                  ),
                  _buildCommandTile(
                    context,
                    icon: Icons.insights,
                    iconColor: Colors.purpleAccent,
                    title: 'ai_assistant.command_finance_sample'.tr(),
                    subtitle: 'ai_assistant.sample_finance_desc'.tr(),
                  ),
                  _buildCommandTile(
                    context,
                    icon: Icons.monetization_on,
                    iconColor: Colors.amber,
                    title: 'ai_assistant.command_expense_sample'.tr(),
                    subtitle: 'ai_assistant.sample_expense_desc'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelectCommand(title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
