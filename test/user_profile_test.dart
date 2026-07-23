import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';

void main() {
  group('UserProfile Tests', () {
    test('accuracy calculation - normal cases', () {
      final profile = UserProfile(
        uid: 'test_uid',
        name: 'Jane Doe',
        level: 3,
        xp: 3450,
        totalScore: 500,
        streak: 5,
        correctAnswers: 8,
        totalAnswers: 10,
        gamesPlayed: 2,
        profileImageUrl: '',
        isGuest: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(profile.accuracy, equals(80.0));
    });

    test('accuracy calculation - zero answers edge case', () {
      final profile = UserProfile(
        uid: 'test_uid',
        name: 'Jane Doe',
        level: 1,
        xp: 100,
        totalScore: 0,
        streak: 0,
        correctAnswers: 0,
        totalAnswers: 0,
        gamesPlayed: 0,
        profileImageUrl: '',
        isGuest: true,
        createdAt: DateTime.now(),
      );

      expect(profile.accuracy, equals(0.0));
    });

    test('levelProgress and xpToNextLevel calculation', () {
      final profile = UserProfile(
        uid: 'test_uid',
        name: 'Jane Doe',
        level: 5,
        xp: 5750, // 5750 % 1000 = 750
        totalScore: 1200,
        streak: 3,
        correctAnswers: 20,
        totalAnswers: 25,
        gamesPlayed: 5,
        profileImageUrl: '',
        isGuest: false,
        createdAt: DateTime.now(),
      );

      expect(profile.levelProgress, equals(0.75));
      expect(profile.xpToNextLevel, equals(250));
    });

    test('daysSinceCreated calculation', () {
      final creationDate = DateTime.now().subtract(const Duration(days: 10));
      final profile = UserProfile(
        uid: 'test_uid',
        name: 'Jane Doe',
        level: 1,
        xp: 100,
        totalScore: 10,
        streak: 1,
        correctAnswers: 1,
        totalAnswers: 1,
        gamesPlayed: 1,
        profileImageUrl: '',
        isGuest: false,
        createdAt: creationDate,
      );

      expect(profile.daysSinceCreated, greaterThanOrEqualTo(10));
    });

    test('fromMap factories with default values', () {
      final map = <String, dynamic>{
        'name': 'Test Player',
        'level': 2,
        'xp': 1500,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      };

      final profile = UserProfile.fromMap(map, 'mapped_uid');

      expect(profile.uid, equals('mapped_uid'));
      expect(profile.name, equals('Test Player'));
      expect(profile.level, equals(2));
      expect(profile.xp, equals(1500));
      expect(profile.totalScore, equals(0)); // default
      expect(profile.streak, equals(0));      // default
      expect(profile.isGuest, equals(false));  // default
    });
  });
}
