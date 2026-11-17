import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/audit/audit_service.dart';
import '../../../../core/utils/toast_utils.dart';
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
      SessionManager().fetchEmployeesFromSupabase();
      AuditService().fetchEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<StaffProvider>().fetchStaffData(background: true),
      SessionManager().fetchEmployeesFromSupabase(),
      AuditService().fetchEvents(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ),
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
            tooltip: 'common.refresh'.tr(),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: () async {
              await _refreshAll();
              if (context.mounted) {
                ToastUtils.showSuccess(context, 'Ma`lumotlar yangilandi');
              }
            },
          ),
          IconButton(
            tooltip: 'staff.invite_qr'.tr(),
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.blueAccent),
            onPressed: () => _showInviteQrModal(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 3-Tab Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
        backgroundColor: AppColors.primary,
        onPressed: _showAddStaffModal,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
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

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => session.fetchEmployeesFromSupabase(),
          child: ListView(
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
                        AppColors.primary.withValues(alpha: 0.2),
                        Colors.purpleAccent.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code, color: AppColors.primary, size: 24),
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
                      const Icon(Icons.chevron_right, color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (employees.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 56,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Hozircha xodimlar mavjud emas',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Yangi xodim qo`shing yoki taklif havolasini yuboring',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _showAddStaffModal,
                          icon: const Icon(Icons.add_rounded),
                          label: Text('staff.add_employee'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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

                final isActive = emp.status == 'active';

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                constraints: const BoxConstraints(maxWidth: 130),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isActive ? 'Faol' : 'Kutilmoqda',
                                  style: TextStyle(
                                    color: isActive ? AppColors.success : Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // History / Audit
                              IconButton(
                                tooltip: 'staff.tab_audit'.tr(),
                                icon: const Icon(Icons.history_rounded, size: 20, color: Colors.blueAccent),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _selectedEmployeeQuery = emp.id;
                                  _searchController.text = emp.id;
                                  _tabController.animateTo(2);
                                },
                              ),
                              // QR Code
                              IconButton(
                                tooltip: 'staff.invite_qr'.tr(),
                                icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: Colors.purpleAccent),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                onPressed: () => _showInviteQrModal(context, emp),
                              ),
                              // Edit Employee
                              IconButton(
                                tooltip: 'common.edit'.tr(),
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.amber),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                onPressed: () => _showEditStaffModal(context, session, emp),
                              ),
                              // Delete Employee
                              IconButton(
                                tooltip: 'common.delete'.tr(),
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                onPressed: () => _confirmDeleteStaff(context, session, emp),
                              ),
                            ],
                          ),
                          // Assign Department button
                          ElevatedButton.icon(
                            onPressed: () => _showAssignDepartmentModal(context, session, emp),
                            icon: const Icon(Icons.assignment_ind_outlined, size: 15),
                            label: Text('staff.assign_dept'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
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
          ),
        );
      },
    );
  }

  // TAB 2: Schedule / Shifts with live actions
  Widget _buildScheduleTab() {
    return Consumer<StaffProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todayShifts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final shifts = provider.todayShifts;

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => provider.fetchStaffData(background: true),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Header with Start Shift action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bugungi smenalar (${shifts.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showStartShiftModal(context, provider),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Smena ochish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (shifts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            size: 56,
                            color: Colors.amber.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'staff.no_active_shifts'.tr(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Xodimlar bugungi ish smenasini boshlashi uchun yuqoridagi tugmani bosing',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showStartShiftModal(context, provider),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Smena boshlash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...shifts.map((shift) {
                  final name = shift.staff?.name ?? 'staff.unknown'.tr();
                  final role = shift.staff?.role ?? 'staff.employee'.tr();
                  final isActive = shift.status == 'active';
                  final startTimeStr =
                      '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? AppColors.success.withValues(alpha: 0.3) : Colors.white10,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: isActive ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                    '$role • Boshlandi: $startTimeStr',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'staff.on_shift'.tr() : 'Yakunlangan',
                                style: TextStyle(
                                  color: isActive ? AppColors.success : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final success = await provider.endShift(shift.id);
                                if (context.mounted) {
                                  if (success) {
                                    ToastUtils.showSuccess(context, 'Smena yakunlandi');
                                    AuditService().logAction(
                                      department: 'staff',
                                      action: 'Smena yakunlandi',
                                      details: '$name ning smenasi yakunlandi.',
                                    );
                                  } else {
                                    ToastUtils.showError(context, 'Smenani yakunlashda xatolik');
                                  }
                                }
                              },
                              icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.redAccent),
                              label: const Text('Smenani yakunlash', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
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

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => auditService.fetchEvents(),
          child: Column(
            children: [
              // Search Bar by Employee ID or Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'staff.search_by_id'.tr(),
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
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
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _selectedEmployeeQuery.isEmpty ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: _selectedEmployeeQuery.isEmpty ? FontWeight.bold : FontWeight.normal,
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
                          selectedColor: AppColors.primary,
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
                                    if (item.employeeId.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.employeeId,
                                          style: const TextStyle(
                                            color: AppColors.primary,
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
          ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildDepartmentOption(context, session, emp, Department.warehouse, 'staff.dept_warehouse'.tr(), Icons.inventory_2, Colors.blueAccent),
                _buildDepartmentOption(context, session, emp, Department.pos, 'staff.dept_pos'.tr(), Icons.point_of_sale, Colors.deepPurpleAccent),
                _buildDepartmentOption(context, session, emp, Department.purchases, 'staff.dept_purchases'.tr(), Icons.shopping_cart, Colors.green),
                _buildDepartmentOption(context, session, emp, Department.kitchen, 'staff.dept_kitchen'.tr(), Icons.soup_kitchen, Colors.deepOrange),
                _buildDepartmentOption(context, session, emp, Department.finance, 'dashboard.menu_finance'.tr(), Icons.account_balance_wallet, Colors.amber),
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
                    ToastUtils.showSuccess(context, 'Bo`lim bekor qilindi');
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
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        session.assignDepartment(emp.id, dept);
        AuditService().logAction(
          department: 'staff',
          action: 'Bo`lim biriktirildi',
          details: '${emp.name} (${emp.id}) ga $label bo`limi biriktirildi.',
        );
        Navigator.pop(context);
        ToastUtils.showSuccess(context, '$label bo`limi biriktirildi');
      },
    );
  }

  // Modal: Show Invite QR Code and Link (Safely handles empty employees)
  void _showInviteQrModal(BuildContext context, [EmployeeProfile? targetEmp]) {
    final session = SessionManager();
    final emp = targetEmp ??
        (session.employees.isNotEmpty
            ? session.employees.firstWhere(
                (e) => e.status == 'waiting',
                orElse: () => session.employees.first,
              )
            : null);

    final inviteLink = session.getInviteLink(emp?.id);

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
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      if (emp != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${emp.name} • ${emp.id}',
                          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
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
                          style: const TextStyle(color: AppColors.primary, fontSize: 12),
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  // Modal: Start shift for an employee
  void _showStartShiftModal(BuildContext context, StaffProvider provider) {
    final session = SessionManager();
    final employees = session.employees;

    if (employees.isEmpty) {
      ToastUtils.showInfo(context, 'Smena ochish uchun avval xodim qo`shing');
      _showAddStaffModal();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Smena ochish uchun xodimni tanlang',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...employees.map((emp) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        emp.id.replaceFirst('EMP-', ''),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(emp.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('${emp.id} • ${emp.roleName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 28),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await provider.startShift(
                        userId: emp.id,
                        userName: emp.name,
                        role: emp.roleName,
                      );
                      if (context.mounted) {
                        if (success) {
                          ToastUtils.showSuccess(context, '${emp.name} uchun smena ochildi');
                          AuditService().logAction(
                            department: 'staff',
                            action: 'Smena ochildi',
                            details: '${emp.name} (${emp.id}) ish smenasini boshladi.',
                          );
                        } else {
                          ToastUtils.showError(context, 'Smena ochishda xatolik yuz berdi');
                        }
                      }
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

  // Modal: Edit Staff details
  void _showEditStaffModal(BuildContext context, SessionManager session, EmployeeProfile emp) {
    final nameController = TextEditingController(text: emp.name);
    final roleController = TextEditingController(text: emp.roleName);
    Department selectedDept = emp.assignedDepartment;
    String selectedStatus = emp.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
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
                        const Icon(Icons.edit_outlined, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Xodim ma`lumotlarini tahrirlash',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Ism va familiya',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: roleController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Lavozim (Role)',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bo`lim:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildDeptChip('Ombor', Department.warehouse, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Kassa (POS)', Department.pos, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Xaridlar', Department.purchases, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Oshxona', Department.kitchen, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Moliya', Department.finance, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Biriktirilmagan', Department.none, selectedDept, (d) => setModalState(() => selectedDept = d)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Holati:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ChoiceChip(
                          label: Text(selectedStatus == 'active' ? 'Faol' : 'Kutilmoqda'),
                          selected: selectedStatus == 'active',
                          selectedColor: AppColors.success.withValues(alpha: 0.2),
                          onSelected: (val) {
                            setModalState(() {
                              selectedStatus = val ? 'active' : 'waiting';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          final newRole = roleController.text.trim();
                          if (newName.isEmpty) return;

                          await session.updateEmployee(
                            id: emp.id,
                            name: newName,
                            roleName: newRole.isEmpty ? emp.roleName : newRole,
                            department: selectedDept,
                            status: selectedStatus,
                          );

                          AuditService().logAction(
                            department: 'staff',
                            action: 'Xodim tahrirlandi',
                            details: '$newName (${emp.id}) ma`lumotlari yangilandi.',
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ToastUtils.showSuccess(context, 'Xodim ma`lumotlari saqlandi');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('common.save'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeptChip(String label, Department dept, Department current, ValueChanged<Department> onSelect) {
    final isSelected = dept == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(dept),
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Modal: Delete confirmation
  void _confirmDeleteStaff(BuildContext context, SessionManager session, EmployeeProfile emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Xodimni o`chirish',
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Haqiqatan ham "${emp.name}" (${emp.id}) ni tizimdan o`chirmoqchimisiz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await session.deleteEmployee(emp.id);
              AuditService().logAction(
                department: 'staff',
                action: 'Xodim o`chirildi',
                details: '${emp.name} (${emp.id}) tizimdan o`chirildi.',
              );
              if (context.mounted) {
                ToastUtils.showSuccess(context, 'Xodim tizimdan o`chirildi');
              }
            },
            child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Modal: Add staff with name, role and department
  void _showAddStaffModal() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    Department selectedDept = Department.none;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
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
                        const Icon(Icons.person_add_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'staff.add_employee'.tr(),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Ism va familiya',
                        hintText: 'Masalan: Alisher Usmonov',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: roleController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Lavozimi (ixtiyoriy)',
                        hintText: 'Oshpaz, Kassir, Ofitsiant...',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bo`lim biriktirish:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildDeptChip('Ombor', Department.warehouse, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Kassa (POS)', Department.pos, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Xaridlar', Department.purchases, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Oshxona', Department.kitchen, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Moliya', Department.finance, selectedDept, (d) => setModalState(() => selectedDept = d)),
                        _buildDeptChip('Keyinroq', Department.none, selectedDept, (d) => setModalState(() => selectedDept = d)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            final role = roleController.text.trim();
                            final newEmp = SessionManager().registerNewEmployee(
                              name: name,
                              roleName: role.isNotEmpty ? role : null,
                              department: selectedDept,
                            );

                            AuditService().logAction(
                              department: 'staff',
                              action: 'Yangi xodim qo`shildi',
                              details: '${newEmp.name} (${newEmp.id}) ro`yxatdan o`tkazildi.',
                            );

                            Navigator.pop(ctx);
                            ToastUtils.showSuccess(context, '${newEmp.name} muvaffaqiyatli qo`shildi');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('common.save'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
