import 'package:chefcontrol/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/audit/audit_service.dart';
import '../providers/staff_provider.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedEmployeeQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().fetchStaffData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'staff.title'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'staff.invite_qr'.tr(),
            icon: const Icon(Icons.qr_code_2, color: Colors.blueAccent),
            onPressed: () => _showInviteQrModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 3-Tab Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'staff.tab_employees'.tr()),
                  Tab(text: 'staff.tab_shifts'.tr()),
                  Tab(text: 'staff.tab_audit'.tr()),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeesTab(),
                _buildScheduleTab(),
                _buildAuditTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _showAddStaffModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // TAB 1: Employees list with ID and Department Assignment
  Widget _buildEmployeesTab() {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        final session = SessionManager();
        final employees = session.employees;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Invite QR Banner
            InkWell(
              onTap: () => _showInviteQrModal(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.2),
                      Colors.purpleAccent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'staff.invite_title'.tr(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'staff.invite_desc'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.blueAccent),
                  ],
                ),
              ),
            ),

            // Employee Cards
            ...employees.map((emp) {
              final isAssigned = emp.assignedDepartment != Department.none;
              String deptLabel = 'staff.dept_none'.tr();
              Color deptColor = Colors.grey;

              switch (emp.assignedDepartment) {
                case Department.warehouse:
                  deptLabel = 'staff.dept_warehouse'.tr();
                  deptColor = Colors.blueAccent;
                  break;
                case Department.pos:
                  deptLabel = 'staff.dept_pos'.tr();
                  deptColor = Colors.deepPurpleAccent;
                  break;
                case Department.purchases:
                  deptLabel = 'staff.dept_purchases'.tr();
                  deptColor = Colors.green;
                  break;
                case Department.kitchen:
                  deptLabel = 'staff.dept_kitchen'.tr();
                  deptColor = Colors.deepOrange;
                  break;
                case Department.finance:
                  deptLabel = 'dashboard.menu_finance'.tr();
                  deptColor = Colors.amber;
                  break;
                case Department.none:
                  deptLabel = 'staff.dept_none'.tr();
                  deptColor = Colors.orangeAccent;
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAssigned ? deptColor.withValues(alpha: 0.3) : Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: deptColor.withValues(alpha: 0.15),
                          child: Text(
                            emp.id.replaceFirst('EMP-', ''),
                            style: TextStyle(
                              color: deptColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      emp.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      emp.id,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emp.roleName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 130),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: deptColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deptLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: deptColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _selectedEmployeeQuery = emp.id;
                            _searchController.text = emp.id;
                            _tabController.animateTo(2);
                          },
                          icon: const Icon(Icons.history, size: 16, color: Colors.blueAccent),
                          label: Text(
                            'staff.tab_audit'.tr(),
                            style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                          ),
                        ),
                        IconButton(
                          tooltip: 'staff.invite_qr'.tr(),
                          icon: const Icon(Icons.qr_code_2, size: 20, color: Colors.blueAccent),
                          onPressed: () => _showInviteQrModal(context, emp),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAssignDepartmentModal(context, session, emp),
                          icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                          label: Text('staff.assign_dept'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                            foregroundColor: Colors.blueAccent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // TAB 2: Schedule / Shifts
  Widget _buildScheduleTab() {
    return Consumer<StaffProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
        }

        final shifts = provider.todayShifts;
        if (shifts.isEmpty) {
          return Center(child: Text('staff.no_active_shifts'.tr(), style: const TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: shifts.length,
          itemBuilder: (context, index) {
            final shift = shifts[index];
            final name = shift.staff?.name ?? 'staff.unknown'.tr();
            final role = shift.staff?.role ?? 'staff.employee'.tr();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: shift.status == 'active' ? AppColors.success : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      shift.status == 'active' ? 'staff.on_shift'.tr() : 'staff.day_off'.tr(),
                      style: TextStyle(
                        color: shift.status == 'active' ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // TAB 3: Employee Activity / Audit Log with ID Search
  Widget _buildAuditTab() {
    return ListenableBuilder(
      listenable: AuditService(),
      builder: (context, _) {
        final auditService = AuditService();
        final session = SessionManager();
        final events = auditService.getTodayEvents(query: _selectedEmployeeQuery);
        final employees = session.employees;

        return Column(
          children: [
            // Search Bar by Employee ID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'staff.search_by_id'.tr(),
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedEmployeeQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedEmployeeQuery = val;
                  });
                },
              ),
            ),

            // Quick Filter Chips by Employee ID
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('common.all'.tr()),
                    selected: _selectedEmployeeQuery.isEmpty,
                    onSelected: (selected) {
                      setState(() {
                        _selectedEmployeeQuery = '';
                        _searchController.clear();
                      });
                    },
                    selectedColor: Colors.blueAccent,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: _selectedEmployeeQuery.isEmpty ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...employees.map((emp) {
                    final isSelected = _selectedEmployeeQuery.toLowerCase() == emp.id.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${emp.id} (${emp.name.split(" ").first})'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedEmployeeQuery = selected ? emp.id : '';
                            _searchController.text = selected ? emp.id : '';
                          });
                        },
                        selectedColor: Colors.blueAccent,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Timeline List of Activities
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_toggle_off, size: 54, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'staff.no_activity_today'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final item = events[index];
                        final timeStr =
                            '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

                        Color deptColor = Colors.blueAccent;
                        IconData deptIcon = Icons.inventory_2;
                        switch (item.department) {
                          case 'warehouse':
                            deptColor = Colors.blueAccent;
                            deptIcon = Icons.inventory_2;
                            break;
                          case 'pos':
                            deptColor = Colors.deepPurpleAccent;
                            deptIcon = Icons.point_of_sale;
                            break;
                          case 'purchases':
                            deptColor = Colors.green;
                            deptIcon = Icons.shopping_cart;
                            break;
                          case 'kitchen':
                            deptColor = Colors.deepOrange;
                            deptIcon = Icons.soup_kitchen;
                            break;
                          default:
                            deptColor = Colors.teal;
                            deptIcon = Icons.bolt;
                            break;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: deptColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(deptIcon, color: deptColor, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.action,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.employeeId,
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.details,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.employeeName,
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // Modal: Assign Department to Employee
  void _showAssignDepartmentModal(BuildContext context, SessionManager session, EmployeeProfile emp) {
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
                  'staff.select_dept'.tr(),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${emp.name} (${emp.id})',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildDepartmentOption(context, session, emp, Department.warehouse, 'staff.dept_warehouse'.tr(), Icons.inventory_2, Colors.blueAccent),
                _buildDepartmentOption(context, session, emp, Department.pos, 'staff.dept_pos'.tr(), Icons.point_of_sale, Colors.deepPurpleAccent),
                _buildDepartmentOption(context, session, emp, Department.purchases, 'staff.dept_purchases'.tr(), Icons.shopping_cart, Colors.green),
                _buildDepartmentOption(context, session, emp, Department.kitchen, 'staff.dept_kitchen'.tr(), Icons.soup_kitchen, Colors.deepOrange),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.redAccent),
                  title: Text(
                    'staff.dept_unassign'.tr(),
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                  onTap: () {
                    session.assignDepartment(emp.id, Department.none);
                    AuditService().logAction(
                      department: 'staff',
                      action: 'Bo`lim bekor qilindi',
                      details: '${emp.name} (${emp.id}) ning bo`limi bekor qilindi.',
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepartmentOption(
    BuildContext context,
    SessionManager session,
    EmployeeProfile emp,
    Department dept,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = emp.assignedDepartment == dept;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blueAccent) : null,
      onTap: () {
        session.assignDepartment(emp.id, dept);
        AuditService().logAction(
          department: 'staff',
          action: 'Bo`lim biriktirildi',
          details: '${emp.name} (${emp.id}) ga $label bo`limi biriktirildi.',
        );
        Navigator.pop(context);
      },
    );
  }

  // Modal: Show Invite QR Code and Link
  void _showInviteQrModal(BuildContext context, [EmployeeProfile? targetEmp]) {
    final session = SessionManager();
    final emp = targetEmp ??
        session.employees.firstWhere(
          (e) => e.status == 'waiting',
          orElse: () => session.employees.last,
        );
    final inviteLink = session.getInviteLink(emp.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'staff.invite_title'.tr(),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'staff.invite_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Visual QR Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: inviteLink,
                        size: 160,
                        version: QrVersions.auto,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.bossProfile.restaurantName,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${emp.name} • ${emp.id}',
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          inviteLink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteLink));
                          ToastUtils.showSuccess(context, 'staff.link_copied'.tr());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      Navigator.pop(context);
                      ToastUtils.showSuccess(context, 'staff.link_copied'.tr());
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text('staff.copy_link'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddStaffModal() {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'staff.add_employee'.tr(),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'staff.name'.tr(),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newEmp = SessionManager().registerNewEmployee(name: name);
                      AuditService().logAction(
                        department: 'staff',
                        action: 'Yangi xodim qo`shildi',
                        details: '${newEmp.name} (${newEmp.id}) ro`yxatdan o`tkazildi.',
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('common.save'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
