import 'package:flutter/material.dart';
import '../../utils/contants.dart';
import '../../widgets/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationData> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _buildSampleNotifications();
  }

  // ── Helpers ──

  List<NotificationData> get _newNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationData> get _earlierNotifications =>
      _notifications.where((n) => n.isRead).toList();

  int get unreadCount => _newNotifications.length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _toggleRead(NotificationData n) {
    setState(() => n.isRead = !n.isRead);
  }

  void _acceptFriend(NotificationData n) {
    setState(() => n.isRead = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend request accepted'),
        backgroundColor: AppColors.card,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _ignoreFriend(NotificationData n) {
    setState(() => _notifications.remove(n));
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _notifications.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (_newNotifications.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'New',
                    count: _newNotifications.length,
                  ),
                  const SizedBox(height: 8),
                  ..._newNotifications.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NotificationItem(
                          data: n,
                          onTap: () => _toggleRead(n),
                          onAccept: n.type == NotificationType.friendRequest
                              ? () => _acceptFriend(n)
                              : null,
                          onIgnore: n.type == NotificationType.friendRequest
                              ? () => _ignoreFriend(n)
                              : null,
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_earlierNotifications.isNotEmpty) ...[
                  const _SectionHeader(title: 'Earlier'),
                  const SizedBox(height: 8),
                  ..._earlierNotifications.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NotificationItem(
                          data: n,
                          onTap: () => _toggleRead(n),
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: AppColors.bg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Empty State ────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You don't have any notifications right now.",
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sample data (replace with real API later) ──────────

List<NotificationData> _buildSampleNotifications() {
  final now = DateTime.now();
  return [
    NotificationData(
      id: '1',
      type: NotificationType.friendRequest,
      userAvatar: null,
      message: 'Sarah Miller sent you a friend request.',
      timestamp: now.subtract(const Duration(minutes: 12)),
    ),
    NotificationData(
      id: '2',
      type: NotificationType.achievement,
      message: 'You earned the "City Explorer" badge! 🏅',
      timestamp: now.subtract(const Duration(hours: 1)),
    ),
    NotificationData(
      id: '3',
      type: NotificationType.systemUpdate,
      message: 'New places have been added near your location.',
      timestamp: now.subtract(const Duration(hours: 3)),
    ),
    NotificationData(
      id: '4',
      type: NotificationType.friendRequest,
      userAvatar: null,
      message: 'James Lee wants to connect with you.',
      timestamp: now.subtract(const Duration(hours: 5)),
    ),
    NotificationData(
      id: '5',
      type: NotificationType.achievement,
      message: 'You reached Level 5 — Trailblazer! 🎉',
      timestamp: now.subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationData(
      id: '6',
      type: NotificationType.systemUpdate,
      message: 'Your weekly travel summary is ready.',
      timestamp: now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationData(
      id: '7',
      type: NotificationType.friendRequest,
      message: 'Emma Wilson accepted your friend request.',
      timestamp: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}
