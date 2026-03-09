import 'package:flutter/material.dart';
import '../../utils/contants.dart';

// ─── Notification type enum ─────────────────────────────

enum NotificationType { friendRequest, systemUpdate, achievement }

// ─── Data model ─────────────────────────────────────────

class NotificationData {
  final String id;
  final NotificationType type;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationData({
    required this.id,
    required this.type,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

// ─── Reusable NotificationItem ──────────────────────────

class NotificationItem extends StatelessWidget {
  final NotificationData data;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onIgnore;

  const NotificationItem({
    super.key,
    required this.data,
    required this.onTap,
    this.onAccept,
    this.onIgnore,
  });

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.friendRequest => Icons.person_add,
      NotificationType.systemUpdate => Icons.info_outline,
      NotificationType.achievement => Icons.emoji_events,
    };
  }

  Color _iconBgForType(NotificationType type) {
    return switch (type) {
      NotificationType.friendRequest => const Color(0xFF3B82F6),
      NotificationType.systemUpdate => const Color(0xFF8B5CF6),
      NotificationType.achievement => AppColors.accent,
    };
  }

  String _timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.isRead ? AppColors.bg : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: data.isRead
              ? Border.all(color: AppColors.white.withValues(alpha: 0.06))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / Icon
            _buildLeading(),
            const SizedBox(width: 12),

            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.message,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight:
                          data.isRead ? FontWeight.normal : FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(data.timestamp),
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  // Friend-request action buttons
                  if (data.type == NotificationType.friendRequest &&
                      !data.isRead) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ActionChip(
                          label: 'Accept',
                          isPrimary: true,
                          onTap: onAccept,
                        ),
                        const SizedBox(width: 8),
                        _ActionChip(
                          label: 'Ignore',
                          isPrimary: false,
                          onTap: onIgnore,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Unread dot
            if (!data.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (data.userAvatar != null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.input,
        backgroundImage: NetworkImage(data.userAvatar!),
      );
    }
    final bg = _iconBgForType(data.type);
    return CircleAvatar(
      radius: 22,
      backgroundColor: bg.withValues(alpha: 0.15),
      child: Icon(_iconForType(data.type), color: bg, size: 22),
    );
  }
}

// ─── Small action chip for friend requests ──────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.white.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? AppColors.bg : AppColors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
