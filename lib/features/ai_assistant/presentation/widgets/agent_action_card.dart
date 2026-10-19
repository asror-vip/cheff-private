import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/ai_agent_action_entity.dart';
import '../../../../core/theme/app_colors.dart';

class AgentActionCard extends StatelessWidget {
  final AgentActionEntity action;

  const AgentActionCard({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    Color themeColor;
    IconData actionIcon;

    switch (action.type) {
      case AgentActionType.produce:
        themeColor = Colors.deepOrange;
        actionIcon = Icons.soup_kitchen;
        break;
      case AgentActionType.expense:
        themeColor = Colors.amber;
        actionIcon = Icons.monetization_on;
        break;
      case AgentActionType.waste:
        themeColor = Colors.redAccent;
        actionIcon = Icons.delete_sweep;
        break;
      case AgentActionType.stockQuery:
        themeColor = Colors.blueAccent;
        actionIcon = Icons.inventory_2;
        break;
      case AgentActionType.salesQuery:
        themeColor = Colors.green;
        actionIcon = Icons.point_of_sale;
        break;
      case AgentActionType.lowStockQuery:
        themeColor = Colors.deepOrangeAccent;
        actionIcon = Icons.warning_amber_rounded;
        break;
      case AgentActionType.financeQuery:
        themeColor = Colors.purpleAccent;
        actionIcon = Icons.insights;
        break;
      case AgentActionType.none:
        themeColor = Colors.teal;
        actionIcon = Icons.bolt;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: action.isSuccess
              ? themeColor.withValues(alpha: 0.4)
              : Colors.redAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(actionIcon, size: 18, color: themeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (action.isSuccess ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action.isSuccess ? Icons.check_circle : Icons.error_outline,
                      size: 12,
                      color: action.isSuccess ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      action.isSuccess
                          ? 'ai_assistant.action_success'.tr()
                          : 'ai_assistant.action_failed'.tr(),
                      style: TextStyle(
                        color: action.isSuccess ? AppColors.success : AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.details,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (action.impactedItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),
            Text(
              'ai_assistant.ingredients_deducted'.tr(),
              style: TextStyle(
                color: themeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...action.impactedItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.remove, size: 12, color: themeColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.history, size: 12, color: Colors.blueAccent),
              const SizedBox(width: 4),
              Text(
                'ai_assistant.audit_recorded'.tr(),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
