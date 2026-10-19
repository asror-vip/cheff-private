import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? restaurantName,
  });

  Future<bool> signInWithGoogle();

  Future<bool> signInWithApple();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
