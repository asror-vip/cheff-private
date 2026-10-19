import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/audit/audit_service.dart';

class SystemStatusSheet extends StatelessWidget {
  const SystemStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SystemStatusSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final auditCount = AuditService().entries.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.system_status'.tr(),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              Icons.cloud_done,
              Colors.green,
              'settings.cloud_database'.tr(),
              'settings.db_connected'.tr(),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              Icons.security,
              Colors.blueAccent,
              'staff.tab_audit'.tr(),
              'settings.audit_records_saved'.tr(args: [auditCount.toString()]),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              Icons.phone_android,
              Colors.amber,
              'settings.app_version_title'.tr(),
              'settings.version_prod'.tr(),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              Icons.lock_outline,
              Colors.tealAccent,
              'settings.restaurant_id'.tr(),
              session.bossProfile.restaurantId,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, Color color, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
