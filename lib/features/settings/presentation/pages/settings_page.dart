import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../providers/settings_provider.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/users_roles_sheet.dart';
import '../widgets/categories_sheet.dart';
import '../widgets/units_sheet.dart';
import '../widgets/system_status_sheet.dart';
import '../widgets/help_support_sheet.dart';
import '../widgets/language_dialog.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback? onOpenStaff;

  const SettingsPage({super.key, this.onOpenStaff});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        final session = SessionManager();
        final boss = session.bossProfile;
        final isOwner = session.currentRole == AppRole.owner;

        return ListenableBuilder(
          listenable: SettingsProvider(),
          builder: (context, _) {
            final settings = SettingsProvider();

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'dashboard.menu_settings'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Top Restaurant and Boss Profile Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                          child: const Icon(Icons.restaurant, color: Colors.blueAccent, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                boss.restaurantName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${boss.name} • ${isOwner ? "staff.role_owner".tr() : "staff.role_employee".tr()}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          tooltip: 'settings.edit_profile'.tr(),
                          onPressed: () => ProfileEditSheet.show(context),
                        ),
                      ],
                    ),
                  ),

                  // Section 1: Business and Operations
                  _buildSectionHeader('settings.profile'.tr()),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.storefront,
                      iconColor: Colors.deepOrange,
                      title: 'settings.profile'.tr(),
                      subtitle: boss.restaurantName,
                      onTap: () => ProfileEditSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.people_outline,
                      iconColor: Colors.cyan,
                      title: 'settings.users_roles'.tr(),
                      subtitle: 'settings.registered_staff_count'.tr(args: [session.employees.length.toString()]),
                      onTap: () => UsersRolesSheet.show(context, onOpenStaff: onOpenStaff),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.category_outlined,
                      iconColor: Colors.amber,
                      title: 'settings.categories'.tr(),
                      subtitle: 'settings.categories_count'.tr(args: [settings.categories.length.toString()]),
                      onTap: () => CategoriesSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.straighten,
                      iconColor: Colors.green,
                      title: 'settings.units'.tr(),
                      subtitle: 'settings.units_count'.tr(args: [settings.units.length.toString()]),
                      onTap: () => UnitsSheet.show(context),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Section 2: Preferences and System
                  _buildSectionHeader('settings.appearance'.tr()),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.language,
                      iconColor: Colors.purpleAccent,
                      title: 'settings.language'.tr(),
                      subtitle: context.locale.languageCode == 'ru'
                          ? 'settings.lang_ru'.tr()
                          : context.locale.languageCode == 'en'
                              ? 'settings.lang_en'.tr()
                              : context.locale.scriptCode == 'Cyrl'
                                  ? 'settings.lang_uz_cyrl'.tr()
                                  : 'settings.lang_uz_latin'.tr(),
                      onTap: () => LanguageDialog.show(context),
                    ),
                    _buildDivider(),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.blueAccent, size: 20),
                      ),
                      title: Text(
                        'settings.notifications'.tr(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: settings.notificationsEnabled,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: settings.toggleNotifications,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.cloud_done_outlined,
                      iconColor: Colors.tealAccent,
                      title: 'settings.system_status'.tr(),
                      subtitle: 'settings.db_connected'.tr(),
                      onTap: () => SystemStatusSheet.show(context),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Section 3: Support and About
                  _buildSectionHeader('settings.help_support'.tr()),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      iconColor: Colors.orangeAccent,
                      title: 'settings.help_support'.tr(),
                      subtitle: 'settings.support_telegram'.tr(),
                      onTap: () => HelpSupportSheet.show(context),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Logout Tile
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      ),
                      title: Text(
                        'auth.logout'.tr(),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: Text('auth.logout'.tr(), style: const TextStyle(color: Colors.white)),
                            content: Text('auth.logout_confirm'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white60)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await session.logout();
                                },
                                child: Text('auth.logout'.tr()),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App Version Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${"settings.app_version".tr()}: 1.0.0',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'settings.app_tagline'.tr(),
                          style: const TextStyle(color: Colors.white24, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white10, height: 1, indent: 56);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
