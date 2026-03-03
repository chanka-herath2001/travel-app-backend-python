import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Email/Password Login
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Email/Password Signup
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    // Create profile row
    if (response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'display_name': username,
      });
      
      await _supabase.from('users').upsert({
        'id': response.user!.id,
        'username': username,
        'email': email,
      });
    }

    return response;
  }

  // Google Sign In
  Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = 'YOUR_WEB_CLIENT_ID';
    
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) throw Exception('No ID Token found.');

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // Upsert profile after Google login
    if (response.user != null) {
      final user = response.user!;
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': user.userMetadata?['full_name'] ?? googleUser.displayName ?? 'User',
      });

      await _supabase.from('users').upsert({
        'id': user.id,
        'username': googleUser.email.split('@')[0],
        'email': user.email ?? googleUser.email,
        'avatar_url': googleUser.photoUrl,
      });
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}