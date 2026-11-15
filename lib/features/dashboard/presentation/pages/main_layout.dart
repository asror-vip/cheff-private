import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../pos/presentation/pages/pos_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../search/presentation/pages/global_search_page.dart';
import 'home_page.dart';

import '../../../../core/session/session_manager.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 2) return; // Do nothing if FAB slot is tapped
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    final pages = [
      HomePage(key: ValueKey('home_${currentLocale.toString()}')),
      GlobalSearchPage(key: ValueKey('search_${currentLocale.toString()}')),
      const SizedBox(), // Placeholder for FAB
      AiAssistantPage(
        key: ValueKey('ai_${currentLocale.toString()}'),
        onBack: () => _onTabTapped(0),
      ),
      SettingsPage(
        key: ValueKey('settings_${currentLocale.toString()}'),
        onBack: () => _onTabTapped(0),
      ),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabTapped(0);
        }
      },
      child: ListenableBuilder(
        listenable: SessionManager(),
        builder: (context, _) {
        final session = SessionManager();
        final canAccessPos = session.currentRole == AppRole.owner
            ? !session.isDepartmentDelegated(Department.pos)
            : session.activeDepartment == Department.pos;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          floatingActionButton: canAccessPos
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PosPage()),
                    );
                  },
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 28),
                )
              : null,
          floatingActionButtonLocation: canAccessPos ? FloatingActionButtonLocation.centerDocked : null,
          bottomNavigationBar: (session.currentRole == AppRole.staff && session.activeDepartment == Department.none)
              ? null
              : BottomAppBar(
                  color: AppColors.surface,
                  shape: canAccessPos ? const CircularNotchedRectangle() : null,
                  notchMargin: 8.0,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        Expanded(child: _buildNavItem(icon: Icons.home_filled, label: 'dashboard.nav_home'.tr(), index: 0)),
                        Expanded(child: _buildNavItem(icon: Icons.search, label: 'dashboard.nav_search'.tr(), index: 1)),
                        if (canAccessPos) const SizedBox(width: 48),
                        Expanded(child: _buildNavItem(icon: Icons.chat_bubble_outline, label: 'dashboard.nav_chat'.tr(), index: 3)),
                        Expanded(child: _buildNavItem(icon: Icons.person_outline, label: 'dashboard.nav_profile'.tr(), index: 4)),
                      ],
                    ),
                  ),
                ),
        );
      },
    ),
  );
}

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.deepOrange : AppColors.textSecondary;
    
    return InkResponse(
      onTap: () => _onTabTapped(index),
      radius: 32,
      splashColor: Colors.deepOrange.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
