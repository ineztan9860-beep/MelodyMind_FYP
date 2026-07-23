import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/auth/providers/auth_provider.dart';
import 'package:interactive_musical_game/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeAuthRepository implements AuthRepository {
  bool signedInAnonymously = false;
  bool signedOut = false;

  @override
  Stream<User?> get authStateChange => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<User?> signInAnonymously() async {
    signedInAnonymously = true;
    return null; // return null user for fake/failure scenario testing
  }

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    return null;
  }

  @override
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    return null;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  group('AuthController Tests', () {
    test('initial state is AsyncData(null)', () {
      final fakeRepo = FakeAuthRepository();
      final controller = AuthController(fakeRepo);

      expect(controller.state, equals(const AsyncData<void>(null)));
    });

    test('signInAnonymously sets state and calls repository', () async {
      final fakeRepo = FakeAuthRepository();
      final controller = AuthController(fakeRepo);

      final result = await controller.signInAnonymously();

      expect(result, isFalse);
      expect(fakeRepo.signedInAnonymously, isTrue);
      expect(controller.state, equals(const AsyncData<void>(null)));
    });

    test('signOut sets state and calls repository', () async {
      final fakeRepo = FakeAuthRepository();
      final controller = AuthController(fakeRepo);

      await controller.signOut();

      expect(fakeRepo.signedOut, isTrue);
      expect(controller.state, equals(const AsyncData<void>(null)));
    });
  });
}
