import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ObjectivesService {
  final _supabase = Supabase.instance.client;

  static int xpForLevel(int level) => level * 500;

  // ── User Stats ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};
    try {
      final user = await _supabase
          .from('users')
          .select('xp_total, level, username')
          .eq('id', userId)
          .single();
      return Map<String, dynamic>.from(user);
    } catch (_) {
      return {'xp_total': 0, 'level': 1, 'username': 'Explorer'};
    }
  }

  Future<List<String>> getEarnedBadgeIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final data = await _supabase
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId);
      return data.map<String>((b) => b['badge_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final data = await _supabase
          .from('badges')
          .select()
          .order('xp_reward');
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  // ── Counts ────────────────────────────────────────────────────────────────

  Future<int> getVisitCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final data = await _supabase
          .from('visits')
          .select('id')
          .eq('user_id', userId);
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getBucketListCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final data = await _supabase
          .from('bucket_list')
          .select('location_id')
          .eq('user_id', userId);
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getReviewCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final data = await _supabase
          .from('reviews')
          .select('id')
          .eq('user_id', userId);
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  // ── Progress (driven by database threshold + requirement_type) ────────────

  double getBadgeProgress({
  required Map<String, dynamic> badge,
  required int visitCount,
  required int bucketCount,
  required int reviewCount,
  required List<String> earnedIds,
}) {
  final id = badge['id'] as String;
  if (earnedIds.contains(id)) return 1.0;

  final threshold = (badge['threshold'] ?? 1) as int;
  final requirementType =
      (badge['requirement_type'] as String?) ?? 'visits';

  if (threshold <= 0) return 0.0;

  switch (requirementType) {
    case 'visits':
      // Always show progress, even if 0 visits
      return (visitCount / threshold).clamp(0.0, 1.0);
    case 'reviews':
      return (reviewCount / threshold).clamp(0.0, 1.0);
    case 'bucket_list':
      return (bucketCount / threshold).clamp(0.0, 1.0);
    case 'manual':
      // Can't auto-track, return -1 as sentinel to show locked
      return -1.0;
    default:
      return 0.0;
  }
}

  String getProgressLabel({
    required Map<String, dynamic> badge,
    required int visitCount,
    required int bucketCount,
    required int reviewCount,
  }) {
    final threshold = (badge['threshold'] ?? 1) as int;
    final requirementType =
        (badge['requirement_type'] as String?) ?? 'visits';

    switch (requirementType) {
      case 'visits':
        return '$visitCount / $threshold visits';
      case 'reviews':
        return '$reviewCount / $threshold reviews';
      case 'bucket_list':
        return '$bucketCount / $threshold saved';
      case 'manual':
        return 'Keep exploring to unlock';
      default:
        return 'Keep exploring to unlock';
    }
  }

  // ── Award Badge via Supabase function ─────────────────────────────────────

  Future<bool> awardBadge(String badgeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _supabase.rpc('award_badge', params: {
        'p_user_id': userId,
        'p_badge_id': badgeId,
      });
      debugPrint('Badge awarded: $badgeId');
      return true;
    } catch (e) {
      debugPrint('Award badge error: $e');
      return false;
    }
  }

  // ── Check and award all eligible badges ───────────────────────────────────

  Future<List<String>> checkAndAwardBadges({
    required List<Map<String, dynamic>> allBadges,
    required List<String> earnedIds,
    required int visitCount,
    required int bucketCount,
    required int reviewCount,
  }) async {
    final newlyEarned = <String>[];

    for (final badge in allBadges) {
      final id = badge['id'] as String;
      if (earnedIds.contains(id)) continue;

      final progress = getBadgeProgress(
        badge: badge,
        visitCount: visitCount,
        bucketCount: bucketCount,
        reviewCount: reviewCount,
        earnedIds: earnedIds,
      );

      // Award if progress is complete (1.0)
      if (progress >= 1.0) {
        final awarded = await awardBadge(id);
        if (awarded) newlyEarned.add(id);
      }
    }

    return newlyEarned;
  }
}