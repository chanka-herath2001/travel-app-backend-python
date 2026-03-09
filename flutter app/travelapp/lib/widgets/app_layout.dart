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
/// - On wider screens the bottom nav is hidden (navigation can live
///   in the top bar or a side rail — extend as needed).
class AppLayout extends StatefulWidget {
  /// Ordered list of pages that map 1-to-1 with bottom nav items.
  final List<AppPage> pages;

  /// Initial tab index (defaults to 0).
  final int initialIndex;

  /// Override nav item configs (icons / labels).
  final List<NavItemConfig> navItems;

  /// Notification badge count shown on the top bar.
  final int notificationCount;

  /// User avatar URL for the top bar.
  final String? avatarUrl;

  /// Top-bar callbacks.
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  /// Optional logo widget for the top bar.
  final Widget? logo;

  const AppLayout({
    super.key,
    required this.pages,
    this.initialIndex = 0,
    this.navItems = defaultNavItems,
    this.notificationCount = 0,
    this.avatarUrl,
    this.onNotificationTap,
    this.onProfileTap,
    this.logo,
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
    final page = widget.pages[_currentIndex];

    return Scaffold(
      appBar: TopNavBar(
        title: page.title,
        notificationCount: widget.notificationCount,
        avatarUrl: widget.avatarUrl,
        onNotificationTap: widget.onNotificationTap,
        onProfileTap: widget.onProfileTap,
        logo: widget.logo,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: widget.pages.map((p) => p.body).toList(),
      ),
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              currentIndex: _currentIndex,
              items: widget.navItems,
              onTap: (index) => setState(() => _currentIndex = index),
            )
          : null,
      backgroundColor: const Color(0xFF0D3B6E),
    );
  }
}
