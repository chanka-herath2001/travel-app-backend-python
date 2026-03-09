import 'package:flutter/material.dart';
import '../utils/contants.dart';

/// Configuration for a single bottom navigation item.
/// Change icons, labels, or add new items via this config.
class NavItemConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Default navigation items — modify this list to change tabs globally.
const List<NavItemConfig> defaultNavItems = [
  NavItemConfig(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  NavItemConfig(
    icon: Icons.search_outlined,
    activeIcon: Icons.search,
    label: 'Search',
  ),
  NavItemConfig(
    icon: Icons.map_outlined,
    activeIcon: Icons.map,
    label: 'Map',
  ),
  NavItemConfig(
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    label: 'Activity',
  ),
  NavItemConfig(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
];

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemConfig> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultNavItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              return _NavItem(
                config: item,
                isActive: isActive,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavItemConfig config;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.config,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? config.activeIcon : config.icon,
                color: isActive ? AppColors.accent : AppColors.white.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.label,
              style: TextStyle(
                color: isActive ? AppColors.accent : AppColors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
