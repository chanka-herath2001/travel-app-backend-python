import 'package:flutter/material.dart';
import '../../services/objectives_service.dart';
import '../../utils/contants.dart';

class ObjectivesScreen extends StatefulWidget {
  const ObjectivesScreen({super.key});

  @override
  State<ObjectivesScreen> createState() => _ObjectivesScreenState();
}

class _ObjectivesScreenState extends State<ObjectivesScreen>
    with SingleTickerProviderStateMixin {
  final _service = ObjectivesService();
  late TabController _tabController;

  List<Map<String, dynamic>> _allBadges = [];
  List<String> _earnedIds = [];
  Map<String, dynamic> _userStats = {};
  int _visitCount = 0;
  int _bucketCount = 0;
  int _reviewCount = 0;
  bool _isLoading = true;

  final List<String> _tabs = ['All', 'Exploration', 'Activity', 'Streaks'];

  static const _explorationIds = [
    'first_steps', 'city_explorer', 'weekend_nomad', 'out_of_bounds',
    'neighbourhood_watch', 'mr_worldwide', 'same_city_new_eyes',
    'fast_and_curious', 'long_haul', 'the_sequel', 'trilogy', 'marathon_day'
  ];
  static const _activityIds = [
    'bucket_lister', 'watchlist_energy', 'check_it_off',
    'im_lovin_it', 'saved_and_sound', 'new_look'
  ];
  static const _streakIds = [
    'no_days_off', 'habit_forming', 'locked_in',
    'second_nature', 'early_bird', 'night_owl'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _service.getAllBadges(),
      _service.getEarnedBadgeIds(),
      _service.getUserStats(),
      _service.getVisitCount(),
      _service.getBucketListCount(),
      _service.getReviewCount(),
    ]);

    final allBadges   = results[0] as List<Map<String, dynamic>>;
    final earnedIds   = results[1] as List<String>;
    final userStats   = results[2] as Map<String, dynamic>;
    final visitCount  = results[3] as int;
    final bucketCount = results[4] as int;
    final reviewCount = results[5] as int;

    // Check and award newly completed badges
    final newlyEarned = await _service.checkAndAwardBadges(
      allBadges: allBadges,
      earnedIds: earnedIds,
      visitCount: visitCount,
      bucketCount: bucketCount,
      reviewCount: reviewCount,
    );

    List<String> updatedEarnedIds = earnedIds;
    Map<String, dynamic> updatedStats = userStats;

    if (newlyEarned.isNotEmpty) {
      updatedEarnedIds = await _service.getEarnedBadgeIds();
      updatedStats     = await _service.getUserStats();

      if (mounted) {
        for (final badgeId in newlyEarned) {
          final badge = allBadges.firstWhere(
            (b) => b['id'] == badgeId,
            orElse: () => {},
          );
          if (badge.isNotEmpty) _showBadgeEarnedToast(badge);
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    }

    if (mounted) {
      setState(() {
        _allBadges   = allBadges;
        _earnedIds   = updatedEarnedIds;
        _userStats   = updatedStats;
        _visitCount  = visitCount;
        _bucketCount = bucketCount;
        _reviewCount = reviewCount;
        _isLoading   = false;
      });
    }
  }

  void _showBadgeEarnedToast(Map<String, dynamic> badge) {
    final emoji = (badge['icon_url']   as String?) ?? '🏅';
    final name  = (badge['name']       as String?) ?? 'Badge';
    final xp    = (badge['xp_reward']  ?? 0) as int;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
        ),
        content: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 Badge Unlocked!',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$xp XP',
                style: const TextStyle(
                  color: AppColors.bg,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _badgesForTab(String tab) {
    List<Map<String, dynamic>> list;
    switch (tab) {
      case 'Exploration':
        list = _allBadges
            .where((b) => _explorationIds.contains(b['id']))
            .toList();
        break;
      case 'Activity':
        list = _allBadges
            .where((b) => _activityIds.contains(b['id']))
            .toList();
        break;
      case 'Streaks':
        list = _allBadges
            .where((b) => _streakIds.contains(b['id']))
            .toList();
        break;
      default:
        list = List.from(_allBadges);
    }

    // Sort: earned → in-progress (highest %) → locked
    list.sort((a, b) {
      final aEarned = _earnedIds.contains(a['id']);
      final bEarned = _earnedIds.contains(b['id']);
      if (aEarned && !bEarned) return -1;
      if (!aEarned && bEarned) return 1;

      final aP = _service.getBadgeProgress(
        badge: a,
        visitCount: _visitCount,
        bucketCount: _bucketCount,
        reviewCount: _reviewCount,
        earnedIds: _earnedIds,
      );
      final bP = _service.getBadgeProgress(
        badge: b,
        visitCount: _visitCount,
        bucketCount: _bucketCount,
        reviewCount: _reviewCount,
        earnedIds: _earnedIds,
      );
      // Put manual (-1.0) at the bottom
      if (aP == -1.0 && bP != -1.0) return 1;
      if (aP != -1.0 && bP == -1.0) return -1;
      return bP.compareTo(aP);
    });

    return list;
  }

  int get _totalXP        => (_userStats['xp_total'] ?? 0) as int;
  int get _level          => (_userStats['level']    ?? 1) as int;
  int get _xpForNextLevel => ObjectivesService.xpForLevel(_level);
  double get _levelProgress =>
      ((_totalXP % _xpForNextLevel) / _xpForNextLevel).clamp(0.0, 1.0);

  String _getLevelTitle(int level) {
    if (level >= 30) return '🌟 Legendary Explorer';
    if (level >= 20) return '💎 Master Traveller';
    if (level >= 15) return '🔥 Elite Adventurer';
    if (level >= 10) return '⚡ Seasoned Explorer';
    if (level >= 5)  return '🗺️ Adventurer';
    if (level >= 3)  return '🎒 Wanderer';
    return '🚶 Newcomer';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(child: _buildLevelCard()),
              SliverToBoxAdapter(child: _buildStatsRow()),
              SliverToBoxAdapter(child: _buildTabBar()),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((tab) => _buildBadgeList(_badgesForTab(tab)))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Level Card ────────────────────────────────────────────────────────────

  Widget _buildLevelCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.card, AppColors.accent.withOpacity(0.15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Level circle
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.45),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_level',
                      style: const TextStyle(
                        color: AppColors.bg,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_userStats['username'] as String?) ?? 'Explorer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getLevelTitle(_level),
                        style: TextStyle(
                          color: AppColors.accent.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total XP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_totalXP',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total XP',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level $_level',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                Text(
                  '${_totalXP % _xpForNextLevel} / $_xpForNextLevel XP',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
                Text('Level ${_level + 1}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _levelProgress,
                backgroundColor: AppColors.input,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _statCard('🗺️', '$_visitCount', 'Visits'),
          const SizedBox(width: 10),
          _statCard('📋', '$_bucketCount', 'Saved'),
          const SizedBox(width: 10),
          _statCard('🏅', '${_earnedIds.length}', 'Badges'),
          const SizedBox(width: 10),
          _statCard('✍️', '$_reviewCount', 'Reviews'),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.bg,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: _tabs
            .map((t) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(t),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Badge List ────────────────────────────────────────────────────────────

  Widget _buildBadgeList(List<Map<String, dynamic>> badges) {
    if (badges.isEmpty) {
      return const Center(
        child: Text(
          'No badges here yet',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: badges.length,
      itemBuilder: (context, i) => _buildBadgeCard(badges[i]),
    );
  }

  // ── Badge Card ────────────────────────────────────────────────────────────

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final id       = badge['id'] as String;
    final isEarned = _earnedIds.contains(id);
    final progress = _service.getBadgeProgress(
      badge: badge,
      visitCount: _visitCount,
      bucketCount: _bucketCount,
      reviewCount: _reviewCount,
      earnedIds: _earnedIds,
    );
    final progressLabel = _service.getProgressLabel(
      badge: badge,
      visitCount: _visitCount,
      bucketCount: _bucketCount,
      reviewCount: _reviewCount,
    );

    final xpReward = (badge['xp_reward']    ?? 0)   as int;
    final emoji    = (badge['icon_url']      as String?) ?? '🏅';
    final name     = (badge['name']          as String?) ?? '';
    final desc     = (badge['description']   as String?) ?? '';

    // true = trackable with a progress bar, false = manual/locked
    final isTrackable = progress != -1.0;

    Color progressBarColor() {
      if (progress >= 0.75) return AppColors.accent;
      if (progress >= 0.4)  return Colors.amber;
      return Colors.white30;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned
            ? AppColors.accent.withOpacity(0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned
              ? AppColors.accent.withOpacity(0.45)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Emoji bubble ─────────────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isEarned
                  ? AppColors.accent.withOpacity(0.2)
                  : isTrackable
                      ? AppColors.input.withOpacity(0.6)
                      : AppColors.input.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 24,
                  color: isEarned
                      ? null
                      : isTrackable
                          ? null
                          : Colors.white24,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Name + XP chip ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isEarned
                              ? AppColors.accent
                              : isTrackable
                                  ? Colors.white
                                  : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? AppColors.accent
                            : AppColors.input,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+$xpReward XP',
                        style: TextStyle(
                          color: isEarned ? AppColors.bg : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ── Description ────────────────────────────────────────────
                Text(
                  desc,
                  style: TextStyle(
                    color: isTrackable
                        ? Colors.white54
                        : Colors.white24,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                // ── State indicator ────────────────────────────────────────

                if (isEarned)
                  // ✅ Completed
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.accent, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'Completed!',
                        style: TextStyle(
                          color: AppColors.accent.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )

                else if (!isTrackable)
                  // 🔒 Manual / locked
                  Row(
                    children: const [
                      Icon(Icons.lock_outline,
                          color: Colors.white24, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Keep exploring to unlock',
                        style: TextStyle(
                            color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  )

                else ...[
                  // 📊 Progress bar (shows even at 0%)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progressLabel,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: AppColors.accent.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.input,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          progressBarColor()),
                      minHeight: 7,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}