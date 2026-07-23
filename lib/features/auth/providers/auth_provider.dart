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
    final user = await _authRepository.signInWithEmailAndPassword(email.trim(), password.trim());
    state = const AsyncData(null);
    return user != null;
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    final user = await _authRepository.signUpWithEmailAndPassword(email.trim(), password.trim());
    state = const AsyncData(null);
    return user != null;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await _authRepository.signOut();
    state = const AsyncData(null);
  }
}
