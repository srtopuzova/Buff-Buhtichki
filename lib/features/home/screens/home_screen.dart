import 'package:flutter/material.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:medshelf/features/med_shelf/screens/med_shelf_screen.dart';
import 'package:medshelf/features/pharmacy/screens/pharmacy_screen.dart';
import 'package:medshelf/features/profile/screens/profile_screen.dart';
import 'package:medshelf/features/red_shelf/screens/red_shelf_screen.dart';

class HomeScreen extends StatefulWidget {
  final Widget? child;

  const HomeScreen({super.key, this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'MedShelf',
      icon: Icons.medication_rounded,
      activeIcon: Icons.medication_rounded,
      color: AppColors.medShelf,
    ),
    _TabItem(
      label: 'RedShelf',
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      color: AppColors.redShelf,
    ),
    _TabItem(
      label: 'Pharmacy',
      icon: Icons.local_pharmacy_outlined,
      activeIcon: Icons.local_pharmacy_rounded,
      color: AppColors.pharmacy,
    ),
    _TabItem(
      label: 'Advisor',
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services_rounded,
      color: AppColors.aiChat,
    ),
    _TabItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      color: AppColors.medShelf,
    ),
  ];

  final List<Widget> _screens = const [
    MedShelfScreen(),
    RedShelfScreen(),
    PharmacyScreen(),
    AiChatScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _MedShelfNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });
}

class _MedShelfNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _MedShelfNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? tab.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          size: 24,
                          color: isActive ? tab.color : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isActive ? tab.color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
