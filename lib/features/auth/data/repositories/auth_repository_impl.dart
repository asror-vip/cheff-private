import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return res;
    } catch (e) {
      debugPrint('Error signInWithEmail: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? restaurantName,
  }) async {
    try {
      final Map<String, dynamic> metadata = {};
      if (fullName != null && fullName.trim().isNotEmpty) {
        metadata['full_name'] = fullName.trim();
      }
      if (restaurantName != null && restaurantName.trim().isNotEmpty) {
        metadata['restaurant_name'] = restaurantName.trim();
      }

      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: metadata.isNotEmpty ? metadata : null,
      );
      return res;
    } catch (e) {
      debugPrint('Error signUpWithEmail: $e');
      rethrow;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.chefcontrol://login-callback',
      );
      return res;
    } catch (e) {
      debugPrint('Error signInWithGoogle: $e');
      rethrow;
    }
  }

  @override
  Future<bool> signInWithApple() async {
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.chefcontrol://login-callback',
      );
      return res;
    } catch (e) {
      debugPrint('Error signInWithApple: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : 'io.supabase.chefcontrol://login-callback',
      );
    } catch (e) {
      debugPrint('Error sendPasswordReset: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signOut: $e');
      rethrow;
    }
  }
}
