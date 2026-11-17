import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../providers/settings_provider.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/users_roles_sheet.dart';
import '../widgets/categories_sheet.dart';
import '../widgets/units_sheet.dart';
import '../widgets/system_status_sheet.dart';
import '../widgets/help_support_sheet.dart';
import '../widgets/language_dialog.dart';
import '../widgets/printer_settings_sheet.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback? onOpenStaff;
  final VoidCallback? onBack;

  const SettingsPage({super.key, this.onOpenStaff, this.onBack});

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
                surfaceTintColor: Colors.transparent,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else if (onBack != null) {
                      onBack!();
                    }
                  },
                ),
                title: Text(
                  'dashboard.nav_profile'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                    tooltip: 'dashboard.notifications'.tr(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Top Profile Summary Card matching Screen 14 Mockup
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Avatar with Camera Icon
                            Stack(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        const Color(0xFF00C6FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    boss.name.isNotEmpty ? boss.name : 'Zaruf Tuychiyev',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${boss.restaurantName} • ${isOwner ? "staff.role_owner".tr() : "staff.role_employee".tr()}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                              ),
                              tooltip: 'settings.edit_profile'.tr(),
                              onPressed: () => ProfileEditSheet.show(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Pro Subscription Badge matching Screen 14
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ChefControl Pro',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Barcha AI va hisobotlar faol',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Aktiv',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section 1: Business and Operations (Screen 13)
                  _buildSectionHeader('settings.profile'.tr()),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.storefront_rounded,
                      iconColor: const Color(0xFFFF7A00),
                      title: 'settings.profile'.tr(),
                      subtitle: boss.restaurantName,
                      onTap: () => ProfileEditSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.people_alt_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'settings.users_roles'.tr(),
                      subtitle: 'settings.registered_staff_count'.tr(args: [session.employees.length.toString()]),
                      onTap: () => UsersRolesSheet.show(context, onOpenStaff: onOpenStaff),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.category_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'settings.categories'.tr(),
                      subtitle: 'settings.categories_count'.tr(args: [settings.categories.length.toString()]),
                      onTap: () => CategoriesSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.straighten_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'settings.units'.tr(),
                      subtitle: 'settings.units_count'.tr(args: [settings.units.length.toString()]),
                      onTap: () => UnitsSheet.show(context),
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // Section 2: Preferences and System
                  _buildSectionHeader('settings.appearance'.tr()),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFF246BFD),
                      title: 'dashboard.notifications'.tr(),
                      subtitle: 'Tizim va ogohlantirishlar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF8B5CF6),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF246BFD).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF246BFD).withValues(alpha: 0.35)),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF246BFD), size: 20),
                      ),
                      title: Text(
                        'settings.notifications'.tr(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Push-bildirishnomalarni yoqish',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      value: settings.notificationsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: settings.toggleNotifications,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.cloud_done_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'settings.system_status'.tr(),
                      subtitle: 'settings.db_connected'.tr(),
                      onTap: () => SystemStatusSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.print_rounded,
                      iconColor: const Color(0xFF94A3B8),
                      title: 'Printer sozlamalari',
                      subtitle: 'Kassa chekini ulash',
                      onTap: () => PrinterSettingsSheet.show(context),
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // Section 3: Support and About
                  _buildSectionHeader('settings.help_support'.tr()),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.headset_mic_rounded,
                      iconColor: const Color(0xFFFF7A00),
                      title: 'settings.help_support'.tr(),
                      subtitle: 'settings.support_telegram'.tr(),
                      onTap: () => HelpSupportSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'settings.privacy_policy'.tr(),
                      onTap: () => _launchURL('https://chefcontrol.ai/privacy-policy'),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.gavel_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'settings.terms_of_use'.tr(),
                      onTap: () => _launchURL('https://chefcontrol.ai/terms-of-use'),
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // Danger Zone (Account Deletion & Logout)
                  _buildSectionHeader('auth.danger_zone'.tr()),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                            ),
                            child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                          ),
                          title: Text(
                            'settings.delete_account'.tr(),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 14),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: Text('settings.delete_account'.tr(), style: const TextStyle(color: Colors.redAccent)),
                                content: const Text(
                                  'Haqiqatan ham hisobingizni o`chirmoqchimisiz? Barcha ma`lumotlar o`chiriladi.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white70)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                    },
                                    child: Text('common.delete'.tr()),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                            ),
                            child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          ),
                          title: Text(
                            'auth.logout'.tr(),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 14),
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
                      ],
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 64);
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
      onTap: onTap,
    );
  }

  Future<void> _launchURL(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlStr');
    }
  }
}
