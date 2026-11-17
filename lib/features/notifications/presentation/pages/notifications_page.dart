import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/audit/audit_service.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../purchases/presentation/pages/purchases_page.dart';
import '../../../staff/presentation/pages/staff_page.dart';

enum NotificationType {
  urgent,
  warning,
  purchase,
  inventory,
  staff,
  success,
  info,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;
  final Widget? targetPage;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.targetPage,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0: All, 1: Unread
  late List<NotificationItem> _notifications;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    final now = DateTime.now();

    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Karimova N. • Xarid bo`limi',
        message: 'Yangi xarid arizasi yaratildi: Sut va qaymoq mahsulotlari',
        time: now.subtract(const Duration(minutes: 25)),
        type: NotificationType.purchase,
        isRead: false,
        targetPage: const PurchasesPage(),
      ),
      NotificationItem(
        id: '2',
        title: 'Ombor ogohlantirishi',
        message: 'Qaymoq 33% qoldig`i me`yordan past: 2.0 l (Me`yor: 10 l)',
        time: now.subtract(const Duration(hours: 1, minutes: 10)),
        type: NotificationType.warning,
        isRead: false,
        targetPage: const InventoryPage(),
      ),
      NotificationItem(
        id: '3',
        title: 'Ibragimov R. • Oshxona',
        message: 'Kechki smena vazifasi bajarildi: Go`sht mahsulotlari marinovkasi',
        time: now.subtract(const Duration(hours: 2, minutes: 30)),
        type: NotificationType.success,
        isRead: true,
        targetPage: const StaffPage(),
      ),
      NotificationItem(
        id: '4',
        title: 'Muddati o`tgan vazifa',
        message: 'Ertalabki chek-list (Texnologik jurnallarni to`ldirish) o`z vaqtida bajarilmadi',
        time: now.subtract(const Duration(hours: 4, minutes: 15)),
        type: NotificationType.urgent,
        isRead: false,
        targetPage: const StaffPage(),
      ),
      NotificationItem(
        id: '5',
        title: 'Yangi nakladnoy qabul qilindi',
        message: '№030125 - SANPACK ta`minotchisidan mahsulotlar omborga kirim qilindi',
        time: now.subtract(const Duration(hours: 5)),
        type: NotificationType.purchase,
        isRead: true,
        targetPage: const PurchasesPage(),
      ),
      NotificationItem(
        id: '6',
        title: 'Smena yakunlandi',
        message: 'Kunduzgi smena yopildi. Jami tushum: 4 320 000 so`m',
        time: now.subtract(const Duration(hours: 7, minutes: 40)),
        type: NotificationType.info,
        isRead: true,
        targetPage: const StaffPage(),
      ),
    ];

    // Also enrich from live AuditService entries if available
    final auditEntries = AuditService().entries;
    for (int i = 0; i < auditEntries.length && i < 4; i++) {
      final entry = auditEntries[i];
      _notifications.insert(
        0,
        NotificationItem(
          id: 'audit_${entry.id}',
          title: '${entry.employeeName} • ${entry.department}',
          message: '${entry.action}: ${entry.details}',
          time: entry.timestamp,
          type: NotificationType.info,
          isRead: false,
        ),
      );
    }

    _initialized = true;
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });
    ToastUtils.showSuccess(context, 'Barcha bildirishnomalar o`qilgan deb belgilandi');
  }

  void _onNotificationTap(NotificationItem item) {
    setState(() {
      item.isRead = true;
    });

    if (item.targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.targetPage!),
      );
    }
  }

  Color _getBadgeColor(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return const Color(0xFFEF4444);
      case NotificationType.warning:
        return const Color(0xFFFF7A00);
      case NotificationType.purchase:
        return const Color(0xFF246BFD);
      case NotificationType.inventory:
        return const Color(0xFF0EA5E9);
      case NotificationType.staff:
        return const Color(0xFF06B6D4);
      case NotificationType.success:
        return const Color(0xFF10B981);
      case NotificationType.info:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getBadgeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return Icons.error_outline_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.purchase:
        return Icons.shopping_bag_outlined;
      case NotificationType.inventory:
        return Icons.inventory_2_outlined;
      case NotificationType.staff:
        return Icons.badge_outlined;
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.info:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('dd.MM HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initNotifications();
    }

    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final displayedList = _selectedTab == 0
        ? _notifications
        : _notifications.where((n) => !n.isRead).toList();

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'dashboard.notifications'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: Text(
                'common.mark_all_read'.tr(),
                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segmented Pill Control matching Screen 15 Mockup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'common.all'.tr(),
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSegmentButton(
                      title: unreadCount > 0
                          ? '${'common.unread'.tr()} ($unreadCount)'
                          : 'common.unread'.tr(),
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification Cards List
          Expanded(
            child: displayedList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      await AuditService().fetchEvents();
                      setState(() {
                        _initNotifications();
                      });
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: displayedList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = displayedList[index];
                        final color = _getBadgeColor(item.type);
                        final icon = _getBadgeIcon(item.type);

                        return Container(
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? AppColors.surface
                                : AppColors.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isRead
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _onNotificationTap(item),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Colored Circular Icon Container
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(icon, color: color, size: 22),
                                    ),
                                    const SizedBox(width: 14),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: item.isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTime(item.time),
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item.message,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Unread Blue Dot
                                    if (!item.isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 38,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'dashboard.no_notifications'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hozircha yangi bildirishnomalar mavjud emas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
