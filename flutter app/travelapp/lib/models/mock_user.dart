import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? avatarUrl;
  final String bio;
  final String location;
  final int friendsCount;
  final int placesCount;
  final int level;
  final String levelBadge;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    this.email = '',
    this.avatarUrl,
    this.bio = '',
    this.location = '',
    this.friendsCount = 0,
    this.placesCount = 0,
    this.level = 1,
    this.levelBadge = 'Explorer',
  });

  UserProfile copyWith({
    String? fullName,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    String? location,
    int? friendsCount,
    int? placesCount,
    int? level,
    String? levelBadge,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      friendsCount: friendsCount ?? this.friendsCount,
      placesCount: placesCount ?? this.placesCount,
      level: level ?? this.level,
      levelBadge: levelBadge ?? this.levelBadge,
    );
  }

  /// Build a [UserProfile] from the `profiles` + `users` rows.
  factory UserProfile.fromSupabase({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> userRow,
  }) {
    return UserProfile(
      id: userRow['id'] as String,
      fullName: (profile['display_name'] ?? userRow['username'] ?? '') as String,
      username: (userRow['username'] ?? '') as String,
      email: (userRow['email'] ?? '') as String,
      avatarUrl: userRow['avatar_url'] as String?,
      bio: (profile['bio'] ?? '') as String,
      location: (profile['location'] ?? '') as String,
      friendsCount: (profile['friends_count'] ?? 0) as int,
      placesCount: (profile['places_count'] ?? 0) as int,
      level: (profile['level'] ?? 1) as int,
      levelBadge: (profile['level_badge'] ?? 'Explorer') as String,
    );
  }

  /// Fetch the current logged-in user's profile from Supabase.
  static Future<UserProfile?> fetchCurrent() async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final profileFuture = supabase
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    final userRowFuture = supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    final results = await Future.wait([profileFuture, userRowFuture]);
    final profile = results[0] as Map<String, dynamic>? ?? {'id': authUser.id};
    final userRow = results[1] as Map<String, dynamic>? ?? {
      'id': authUser.id,
      'email': authUser.email ?? '',
      'username': authUser.userMetadata?['username'] ?? '',
    };

    return UserProfile.fromSupabase(profile: profile, userRow: userRow);
  }

  /// Persist editable fields back to Supabase.
  Future<void> save() async {
    final supabase = Supabase.instance.client;

    await Future.wait([
      supabase.from('profiles').upsert({
        'id': id,
        'display_name': fullName,
        'bio': bio,
        'location': location,
      }),
      supabase.from('users').upsert({
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
      }),
    ]);
  }
}
