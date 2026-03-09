import 'package:flutter/material.dart';
import '../utils/contants.dart';

/// Configuration for a single bottom navigation item.
class NavItemConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  /// If true this item renders as the elevated "hero" center button.
  final bool isHero;

  const NavItemConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isHero = false,
  });
}

/// Default 5-item nav — Bucket List is the hero center button.
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
    icon: Icons.add,
    activeIcon: Icons.add,
    label: 'Bucket List',
    isHero: true,
  ),
  NavItemConfig(
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    label: 'Chat',
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
  /// Show a notification dot on the Chat tab.
  final bool showChatBadge;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultNavItems,
    this.showChatBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              if (item.isHero) {
                return _HeroButton(
                  config: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                );
              }

              return _NavItem(
                config: item,
                isActive: isActive,
                showBadge: item.label == 'Chat' && showChatBadge,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Regular nav item ───────────────────────────────────

class _NavItem extends StatelessWidget {
  final NavItemConfig config;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.config,
    required this.isActive,
    this.showBadge = false,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Badge(
                isLabelVisible: showBadge,
                backgroundColor: Colors.red,
                smallSize: 8,
                child: Icon(
                  isActive ? config.activeIcon : config.icon,
                  color: isActive
                      ? AppColors.accent
                      : AppColors.white.withValues(alpha: 0.55),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.label,
              style: TextStyle(
                color: isActive
                    ? AppColors.accent
                    : AppColors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero center button ─────────────────────────────────

class _HeroButton extends StatelessWidget {
  final NavItemConfig config;
  final bool isActive;
  final VoidCallback onTap;

  const _HeroButton({
    required this.config,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: AppColors.bg,
                size: 28,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              config.label,
              style: TextStyle(
                color: isActive
                    ? AppColors.accent
                    : AppColors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
