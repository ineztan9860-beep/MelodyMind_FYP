import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChange;
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

String _friendlyAuthError(dynamic e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncData(null));

  Future<bool> signInAnonymously() async {
    state = const AsyncLoading();
    final user = await _authRepository.signInAnonymously();
    state = const AsyncData(null);
    return user != null;
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.signInWithEmailAndPassword(email.trim(), password.trim());
      state = const AsyncData(null);
      return user != null;
    } catch (e) {
      state = const AsyncData(null);
      throw _friendlyAuthError(e);
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(email.trim(), password.trim());
      state = const AsyncData(null);
      return user != null;
    } catch (e) {
      state = const AsyncData(null);
      throw _friendlyAuthError(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email.trim());
    } catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await _authRepository.signOut();
    state = const AsyncData(null);
  }
}
