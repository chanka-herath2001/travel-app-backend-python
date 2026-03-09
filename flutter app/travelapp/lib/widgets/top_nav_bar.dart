import 'package:flutter/material.dart';
import '../utils/contants.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  /// Gamification props — connect to global state later.
  final int level;
  final double xpProgress; // 0.0 – 1.0
  final int coins;

  /// Identity
  final String? avatarUrl;
  final VoidCallback? onProfileTap;

  const TopNavBar({
    super.key,
    this.level = 1,
    this.xpProgress = 0,
    this.coins = 0,
    this.avatarUrl,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final hPad = isWide ? 24.0 : 14.0;

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                // ── Left: Gamification cluster ──
                _LevelBadge(level: level),
                const SizedBox(width: 10),
                _XpBar(progress: xpProgress, width: isWide ? 100 : 64),

                const Spacer(),

                // ── Right: Currency & Identity ──
                _CoinDisplay(coins: coins),
                SizedBox(width: isWide ? 16 : 10),
                _ProfileAvatar(
                  avatarUrl: avatarUrl,
                  onTap: onProfileTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Level Badge ────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, color: AppColors.accent, size: 16),
          const SizedBox(width: 4),
          Text(
            'Lvl $level',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── XP Progress Bar ────────────────────────────────────

class _XpBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double width;
  const _XpBar({required this.progress, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'XP',
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.45),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: width,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF8AE234)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Coin Display ───────────────────────────────────────

class _CoinDisplay extends StatelessWidget {
  final int coins;
  const _CoinDisplay({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 5),
          Text(
            coins >= 1000 ? '${(coins / 1000).toStringAsFixed(1)}k' : '$coins',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Avatar ─────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback? onTap;

  const _ProfileAvatar({this.avatarUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.card,
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? const Icon(Icons.person, color: AppColors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
