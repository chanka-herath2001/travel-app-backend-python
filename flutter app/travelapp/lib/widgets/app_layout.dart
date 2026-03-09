import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'top_nav_bar.dart';

/// Page definition used by [AppLayout] to render screen content.
class AppPage {
  final String title;
  final Widget body;

  const AppPage({required this.title, required this.body});
}

/// A responsive layout shell that wraps pages with a [TopNavBar]
/// and an [AppBottomNavBar].
///
/// - On narrow screens (< 768 dp) the bottom nav bar is shown.
/// - On wider screens the bottom nav is hidden.
class AppLayout extends StatefulWidget {
  /// Ordered list of pages that map 1-to-1 with bottom nav items.
  final List<AppPage> pages;

  /// Initial tab index (defaults to 0).
  final int initialIndex;

  /// Override nav item configs (icons / labels).
  final List<NavItemConfig> navItems;

  // ── Top-bar gamification props ──
  final int level;
  final double xpProgress;
  final int coins;

  /// User avatar URL for the top bar.
  final String? avatarUrl;

  /// Profile avatar tap callback (navigates to profile).
  final VoidCallback? onProfileTap;

  /// Show a notification dot on the Chat bottom-nav item.
  final bool showChatBadge;

  const AppLayout({
    super.key,
    required this.pages,
    this.initialIndex = 0,
    this.navItems = defaultNavItems,
    this.level = 1,
    this.xpProgress = 0,
    this.coins = 0,
    this.avatarUrl,
    this.onProfileTap,
    this.showChatBadge = false,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: TopNavBar(
        level: widget.level,
        xpProgress: widget.xpProgress,
        coins: widget.coins,
        avatarUrl: widget.avatarUrl,
        onProfileTap: widget.onProfileTap,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: widget.pages.map((p) => p.body).toList(),
      ),
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              currentIndex: _currentIndex,
              items: widget.navItems,
              showChatBadge: widget.showChatBadge,
              onTap: (index) => setState(() => _currentIndex = index),
            )
          : null,
      backgroundColor: const Color(0xFF0D3B6E),
    );
  }
}
