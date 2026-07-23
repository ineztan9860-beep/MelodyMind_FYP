import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserProfile {
  final String uid;
  final String name;
  final int level;
  final int xp;
  final int totalScore;
  final int streak;
  final int correctAnswers;
  final int totalAnswers;
  final int gamesPlayed;
  final String profileImageUrl;
  final bool isGuest;
  /// Account creation date (used to gate weekly/monthly report downloads).
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.level,
    required this.xp,
    required this.totalScore,
    required this.streak,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.gamesPlayed,
    required this.profileImageUrl,
    required this.isGuest,
    required this.createdAt,
  });

  /// Accuracy percentage (0–100). Returns 0 if no games played.
  double get accuracy {
    if (totalAnswers == 0) return 0.0;
    return (correctAnswers / totalAnswers) * 100.0;
  }

  /// XP progress within current level (0.0 – 1.0)
  double get levelProgress => (xp % 1000) / 1000.0;

  /// XP needed to reach next level
  int get xpToNextLevel => 1000 - (xp % 1000);

  /// Days since account was created
  int get daysSinceCreated =>
      DateTime.now().difference(createdAt).inDays;

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    final createdAtMs = map['createdAtMs'] as int?;
    return UserProfile(
      uid: uid,
      name: map['name'] ?? 'Guest',
      level: map['level'] ?? 0,
      xp: map['xp'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      streak: map['streak'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalAnswers: map['totalAnswers'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      profileImageUrl: map['profileImageUrl'] ?? '',
      isGuest: map['isGuest'] ?? false,
      createdAt: createdAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : DateTime.now(),
    );
  }
}

// Stateful notifier used by most screens (streams live updates)
class UserProfileNotifier
    extends StateNotifier<AsyncValue<UserProfile?>> {
  final Ref ref;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.value?.uid != next.value?.uid) {
        _loadProfile();
      }
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final repo = ref.read(userRepositoryProvider);

      var profileData = await repo.getUserProfile(user.uid);
      if (profileData == null) {
        await repo.createUserProfile(
          user.uid,
          user.email ?? '',
          isGuest: user.isAnonymous,
        );
        profileData = await repo.getUserProfile(user.uid);
      }

      // Parallelise: update login streak while we already have data
      await repo.updateLoginStreak(user.uid);
      // Re-fetch once after streak update to get latest streak count
      profileData = await repo.getUserProfile(user.uid);

      if (profileData != null) {
        state = AsyncValue.data(UserProfile.fromMap(profileData, user.uid));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Force a fresh load from Firestore (call after any mutation).
  Future<void> refreshProfile() => _loadProfile();

  Future<void> resetProgress() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(userRepositoryProvider).resetProgress(user.uid);
      await _loadProfile();
    }
  }

  Future<void> updateName(String newName) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(userRepositoryProvider).updateName(user.uid, newName);
      await _loadProfile();
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref
          .read(userRepositoryProvider)
          .updateProfileImage(user.uid, imageUrl);
      await _loadProfile();
    }
  }

  /// Called at the end of every game to persist stats.
  Future<void> saveGameResult({
    required int scoreGained,
    required int xpGained,
    required int correctAnswers,
    required int totalAnswers,
    required bool incrementStreak,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(userRepositoryProvider).updateGameStats(
            uid: user.uid,
            scoreGained: scoreGained,
            xpGained: xpGained,
            correctAnswers: correctAnswers,
            totalAnswers: totalAnswers,
            incrementStreak: incrementStreak,
          );
      await _loadProfile();
    }
  }

  /// Add direct XP (e.g., from invites or bonuses)
  Future<void> addXP(int xpToAdd) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(userRepositoryProvider).addXP(user.uid, xpToAdd);
      await _loadProfile();
    }
  }
}

final userProfileNotifierProvider = StateNotifierProvider<
    UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier(ref);
});
