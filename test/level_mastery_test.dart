import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Level Details Unlock and Mastery Tier Tests', () {
    bool isMasteryUnlocked({
      required int gamesPlayed,
      required double accuracy,
      required int level,
    }) {
      return gamesPlayed >= 5 && accuracy >= 60.0 && level >= 5;
    }

    test('mastery unlocked when all 3 criteria are satisfied', () {
      expect(
        isMasteryUnlocked(gamesPlayed: 5, accuracy: 60.0, level: 5),
        isTrue,
      );
      expect(
        isMasteryUnlocked(gamesPlayed: 10, accuracy: 85.0, level: 7),
        isTrue,
      );
    });

    test('mastery locked when games played is less than 5', () {
      expect(
        isMasteryUnlocked(gamesPlayed: 4, accuracy: 90.0, level: 6),
        isFalse,
      );
    });

    test('mastery locked when accuracy is below 60%', () {
      expect(
        isMasteryUnlocked(gamesPlayed: 6, accuracy: 59.9, level: 5),
        isFalse,
      );
    });

    test('mastery locked when level is below 5', () {
      expect(
        isMasteryUnlocked(gamesPlayed: 10, accuracy: 95.0, level: 4),
        isFalse,
      );
    });
  });
}
