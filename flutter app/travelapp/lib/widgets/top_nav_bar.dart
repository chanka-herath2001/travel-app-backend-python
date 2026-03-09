import 'package:flutter/material.dart';
import '../utils/contants.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int notificationCount;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Widget? logo;
  final List<Widget>? extraActions;

  const TopNavBar({
    super.key,
    required this.title,
    this.notificationCount = 0,
    this.avatarUrl,
    this.onNotificationTap,
    this.onProfileTap,
    this.logo,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return AppBar(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: isWide ? 180 : 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: logo ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.travel_explore, color: AppColors.accent, size: 28),
                if (isWide) ...[
                  const SizedBox(width: 8),
                  Text(
                    'MY Map',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        if (extraActions != null) ...extraActions!,
        _NotificationBell(
          count: notificationCount,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 4),
        _ProfileAvatar(
          avatarUrl: avatarUrl,
          onTap: onProfileTap,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationBell({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        child: const Icon(Icons.notifications_outlined, color: AppColors.white),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback? onTap;

  const _ProfileAvatar({this.avatarUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.card,
        backgroundImage:
            avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? const Icon(Icons.person, color: AppColors.white, size: 20)
            : null,
      ),
    );
  }
}
