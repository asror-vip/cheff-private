import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:badges/badges.dart' as badges;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../recipes/presentation/pages/recipes_page.dart';
import '../../../menu/presentation/pages/menu_foodcost_page.dart';
import '../../../purchases/presentation/pages/purchases_page.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../sales/presentation/pages/sales_page.dart';
import '../../../staff/presentation/pages/staff_page.dart';
import '../../../finance/presentation/pages/finance_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../production/presentation/pages/production_page.dart';
import '../../../cashier_shifts/presentation/pages/shift_page.dart';
import '../../../tables/presentation/pages/tables_page.dart';
import '../../../kitchen/presentation/pages/kitchen_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class _MenuItemConfig {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Department department;
  final Widget page;
  final bool adminOnly;

  const _MenuItemConfig({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.department,
    required this.page,
    this.adminOnly = false,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  List<_MenuItemConfig> _getAllMenuItems(BuildContext context) {
    return [
      _MenuItemConfig(
        title: 'dashboard.menu_ai'.tr(context: context),
        icon: Icons.smart_toy,
        iconColor: Colors.deepPurpleAccent,
        department: Department.none,
        page: const AiAssistantPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_ttk'.tr(context: context),
        icon: Icons.restaurant,
        iconColor: Colors.orangeAccent,
        department: Department.kitchen,
        page: const RecipesPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_foodcost'.tr(context: context),
        icon: Icons.menu_book,
        iconColor: Colors.deepOrange,
        department: Department.kitchen,
        page: const MenuFoodcostPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_purchases'.tr(context: context),
        icon: Icons.shopping_cart,
        iconColor: Colors.green,
        department: Department.purchases,
        page: const PurchasesPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_warehouse'.tr(context: context),
        icon: Icons.inventory_2,
        iconColor: Colors.blueAccent,
        department: Department.warehouse,
        page: const InventoryPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_sales'.tr(context: context),
        icon: Icons.bar_chart,
        iconColor: Colors.deepPurple,
        department: Department.pos,
        page: const SalesPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_staff'.tr(context: context),
        icon: Icons.people,
        iconColor: Colors.cyan,
        department: Department.none,
        page: const StaffPage(),
        adminOnly: true,
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_finance'.tr(context: context),
        icon: Icons.monetization_on,
        iconColor: Colors.amber,
        department: Department.finance,
        page: const FinancePage(),
        adminOnly: true,
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_reports'.tr(context: context),
        icon: Icons.description,
        iconColor: Colors.white70,
        department: Department.none,
        page: const ReportsPage(),
        adminOnly: true,
      ),
      _MenuItemConfig(
        title: 'production.title'.tr(context: context),
        icon: Icons.soup_kitchen,
        iconColor: Colors.deepOrange,
        department: Department.kitchen,
        page: const ProductionPage(),
      ),
      _MenuItemConfig(
        title: 'Kassa Smenasi',
        icon: Icons.lock_clock,
        iconColor: Colors.teal,
        department: Department.pos,
        page: const ShiftPage(),
      ),
      _MenuItemConfig(
        title: 'Stollar',
        icon: Icons.table_restaurant,
        iconColor: Colors.brown,
        department: Department.pos,
        page: const TablesPage(),
      ),
      _MenuItemConfig(
        title: 'kitchen.title'.tr(context: context),
        icon: Icons.kitchen,
        iconColor: Colors.redAccent,
        department: Department.kitchen,
        page: const KitchenPage(),
      ),
      _MenuItemConfig(
        title: 'dashboard.menu_settings'.tr(context: context),
        icon: Icons.settings,
        iconColor: Colors.grey,
        department: Department.none,
        page: const SettingsPage(),
        adminOnly: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        final session = SessionManager();
        final isOwner = session.currentRole == AppRole.owner;
        final currentEmp = session.currentEmployee;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.bossProfile.restaurantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isOwner
                      ? 'staff.role_owner'.tr()
                      : (currentEmp?.name ?? "staff.employee".tr()),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOwner ? Colors.blueAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              // Switch role test badge
              InkWell(
                onTap: () => _showAccountSwitcher(context, session),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOwner
                        ? Colors.blueAccent.withValues(alpha: 0.15)
                        : Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOwner ? Colors.blueAccent : Colors.orangeAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOwner ? Icons.admin_panel_settings : Icons.badge_outlined,
                        size: 14,
                        color: isOwner ? Colors.blueAccent : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOwner ? 'staff.owner_short'.tr(context: context) : (currentEmp?.id ?? 'EMP'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOwner ? Colors.blueAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: badges.Badge(
                  badgeContent: const Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppColors.error,
                    padding: EdgeInsets.all(4),
                  ),
                  child: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: _buildCustomDrawer(context, session),
          body: _buildBody(context, session),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SessionManager session) {
    if (session.currentRole == AppRole.staff) {
      if (session.activeDepartment == Department.none) {
        return _buildEmployeePendingView(context, session);
      } else {
        return _buildEmployeeAssignedView(context, session);
      }
    }
    return _buildBossView(context, session);
  }

  // Employee joined via QR/link without assigned department
  Widget _buildEmployeePendingView(BuildContext context, SessionManager session) {
    final boss = session.bossProfile;
    final emp = session.currentEmployee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Restaurant Name Card (Read-only)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.deepOrange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boss.restaurantName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'dashboard.app_subtitle'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Boss Profile Card (Strictly read-only, non-clickable)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 6),
                    Text(
                      'staff.boss_profile_title'.tr(),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Colors.blueAccent, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            boss.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'staff.role_owner'.tr(context: context),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Employee Assignment Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${"staff.your_id".tr()}: ${emp?.id ?? "EMP-103"}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'staff.waiting_approval'.tr(),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Siz tizimga muvaffaqiyatli kirdingiz. Hozircha sizga hech qanday bo\'lim biriktirilmagan. Rol va bo\'lim olish uchun menejerga murojaat qiling.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Employee assigned to a department
  Widget _buildEmployeeAssignedView(BuildContext context, SessionManager session) {
    final emp = session.currentEmployee;
    final assignedDept = session.activeDepartment;
    final allItems = _getAllMenuItems(context);

    final allowedItems = allItems.where((item) {
      if (item.adminOnly) return false;
      return item.department == assignedDept;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp?.name ?? 'staff.employee'.tr(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${emp?.roleName ?? ""}  ID: ${emp?.id ?? ""}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'staff.on_shift'.tr(),
                    style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Assigned module cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allowedItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final item = allowedItems[index];
              return _buildMenuCard(
                context: context,
                title: item.title,
                icon: item.icon,
                iconColor: item.iconColor,
                onTap: () => _navigate(context, item.page),
              );
            },
          ),
        ],
      ),
    );
  }

  // Boss Dashboard View
  Widget _buildBossView(BuildContext context, SessionManager session) {
    final allItems = _getAllMenuItems(context);

    // Filter out departments that are delegated to staff to prevent tampering
    final visibleItems = allItems.where((item) {
      if (item.department == Department.none) return true;
      return !session.isDepartmentDelegated(item.department);
    }).toList();

    final delegatedDepts = Department.values.where((d) => session.isDepartmentDelegated(d)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If any department is delegated, display clear separation notice
          if (delegatedDepts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'staff.delegated_to'.tr(context: context),
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'staff.delegated_warning'.tr(context: context),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: delegatedDepts.map((d) {
                      final emp = session.getEmployeeForDepartment(d);
                      String deptName = '';
                      switch (d) {
                        case Department.warehouse:
                          deptName = 'staff.dept_warehouse'.tr(context: context);
                          break;
                        case Department.pos:
                          deptName = 'staff.dept_pos'.tr(context: context);
                          break;
                        case Department.purchases:
                          deptName = 'staff.dept_purchases'.tr(context: context);
                          break;
                        case Department.kitchen:
                          deptName = 'staff.dept_kitchen'.tr(context: context);
                          break;
                        case Department.finance:
                          deptName = 'dashboard.menu_finance'.tr(context: context);
                          break;
                        case Department.none:
                          break;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          '$deptName: ${emp?.name ?? ""} (${emp?.id ?? ""})',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Grid of active menu cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final item = visibleItems[index];
              return _buildMenuCard(
                context: context,
                title: item.title,
                icon: item.icon,
                iconColor: item.iconColor,
                onTap: () => _navigate(context, item.page),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSwitcher(BuildContext context, SessionManager session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'staff.switch_account'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Boss option
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  title: Text(
                    session.bossProfile.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'staff.role_owner'.tr(),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: session.currentRole == AppRole.owner
                      ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                      : null,
                  onTap: () {
                    // Security check: Bossga o'tishda PIN kod yoki ogohlantirish talab qilinadi
                    if (session.currentRole != AppRole.owner) {
                       Navigator.pop(context); // close sheet
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('auth.switch_to_boss_pin_required'.tr())),
                       );
                    } else {
                       Navigator.pop(context);
                    }
                  },
                ),
                const Divider(color: Colors.white10),
                // Employees list
                ...session.employees.map((emp) {
                  final isCurrent = session.currentRole == AppRole.staff && session.currentEmployee?.id == emp.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                      child: Text(
                        emp.id.replaceFirst('EMP-', ''),
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      emp.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${emp.id}  ${emp.roleName}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.orangeAccent) : null,
                    onTap: () {
                      session.switchToEmployee(emp.id);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomDrawer(BuildContext context, SessionManager session) {
    final isOwner = session.currentRole == AppRole.owner;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.bossProfile.restaurantName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner
                      ? 'staff.role_owner'.tr()
                      : '${session.currentEmployee?.name ?? ""} (${session.currentEmployee?.id ?? ""})',
                  style: TextStyle(
                    color: isOwner ? Colors.blueAccent : Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(Icons.sync_alt, 'staff.switch_account'.tr(), Colors.tealAccent, () {
                  Navigator.pop(context);
                  _showAccountSwitcher(context, session);
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                if (isOwner || session.activeDepartment != Department.none)
                  _buildDrawerItem(Icons.smart_toy, 'dashboard.menu_ai'.tr(), Colors.deepPurpleAccent, () {
                    Navigator.pop(context);
                    _navigate(context, const AiAssistantPage());
                  }),
                if (isOwner || session.activeDepartment == Department.kitchen)
                  _buildDrawerItem(Icons.restaurant, 'dashboard.menu_ttk'.tr(), Colors.orangeAccent, () {
                    Navigator.pop(context);
                    _navigate(context, const RecipesPage());
                  }),
                if (isOwner || session.activeDepartment == Department.kitchen)
                  _buildDrawerItem(Icons.menu_book, 'dashboard.menu_foodcost'.tr(), Colors.deepOrange, () {
                    Navigator.pop(context);
                    _navigate(context, const MenuFoodcostPage());
                  }),
                if (isOwner && !session.isDepartmentDelegated(Department.purchases) ||
                    session.activeDepartment == Department.purchases)
                  _buildDrawerItem(Icons.shopping_cart, 'dashboard.menu_purchases'.tr(), Colors.green, () {
                    Navigator.pop(context);
                    _navigate(context, const PurchasesPage());
                  }),
                if (isOwner && !session.isDepartmentDelegated(Department.warehouse) ||
                    session.activeDepartment == Department.warehouse)
                  _buildDrawerItem(Icons.inventory_2, 'dashboard.menu_warehouse'.tr(), Colors.blueAccent, () {
                    Navigator.pop(context);
                    _navigate(context, const InventoryPage());
                  }),
                if (isOwner && !session.isDepartmentDelegated(Department.pos) ||
                    session.activeDepartment == Department.pos)
                  _buildDrawerItem(Icons.bar_chart, 'dashboard.menu_sales'.tr(), Colors.deepPurple, () {
                    Navigator.pop(context);
                    _navigate(context, const SalesPage());
                  }),
                if (isOwner)
                  _buildDrawerItem(Icons.people, 'dashboard.menu_staff'.tr(), Colors.cyan, () {
                    Navigator.pop(context);
                    _navigate(context, const StaffPage());
                  }),
                if (isOwner)
                  _buildDrawerItem(Icons.monetization_on, 'dashboard.menu_finance'.tr(), Colors.amber, () {
                    Navigator.pop(context);
                    _navigate(context, const FinancePage());
                  }),
                if (isOwner)
                  _buildDrawerItem(Icons.description, 'dashboard.menu_reports'.tr(), Colors.white70, () {
                    Navigator.pop(context);
                    _navigate(context, const ReportsPage());
                  }),
                if (isOwner || session.activeDepartment == Department.kitchen)
                  _buildDrawerItem(Icons.soup_kitchen, 'production.title'.tr(), Colors.deepOrange, () {
                    Navigator.pop(context);
                    _navigate(context, const ProductionPage());
                  }),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                _buildDrawerItem(Icons.settings, 'dashboard.menu_settings'.tr(), Colors.grey, () {
                  Navigator.pop(context);
                  _navigate(context, const SettingsPage());
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: onTap,
    );
  }
}
