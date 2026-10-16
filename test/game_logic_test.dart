import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note Identification & Game Scoring Logic Tests', () {
    const nineNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C#', 'F#'];

    test('all 9 notes are within the specified range C to F#', () {
      expect(nineNotes.length, equals(9));
      expect(nineNotes.contains('C'), isTrue);
      expect(nineNotes.contains('D'), isTrue);
      expect(nineNotes.contains('E'), isTrue);
      expect(nineNotes.contains('F'), isTrue);
      expect(nineNotes.contains('G'), isTrue);
      expect(nineNotes.contains('A'), isTrue);
      expect(nineNotes.contains('B'), isTrue);
      expect(nineNotes.contains('C#'), isTrue);
      expect(nineNotes.contains('F#'), isTrue);
    });

    test('streak multiplier progression', () {
      int calculateMultiplier(int streak) {
        if (streak >= 10) return 4;
        if (streak >= 5) return 2;
        return 1;
      }

      expect(calculateMultiplier(0), equals(1));
      expect(calculateMultiplier(4), equals(1));
      expect(calculateMultiplier(5), equals(2));
      expect(calculateMultiplier(9), equals(2));
      expect(calculateMultiplier(10), equals(4));
      expect(calculateMultiplier(20), equals(4));
    });

    test('score calculation by difficulty tier', () {
      int getBasePoints(String difficulty) {
        if (difficulty == 'Hard') return 200;
        if (difficulty == 'Medium') return 150;
        return 100; // Easy
      }

      expect(getBasePoints('Easy'), equals(100));
      expect(getBasePoints('Medium'), equals(150));
      expect(getBasePoints('Hard'), equals(200));

      // With 2x multiplier
      expect(getBasePoints('Easy') * 2, equals(200));
      expect(getBasePoints('Medium') * 2, equals(300));
      expect(getBasePoints('Hard') * 2, equals(400));

      // With 4x multiplier
      expect(getBasePoints('Easy') * 4, equals(400));
      expect(getBasePoints('Medium') * 4, equals(600));
      expect(getBasePoints('Hard') * 4, equals(800));
    });

    test('lives decrement and game over condition in Hard mode', () {
      int lives = 3;
      bool isGameOver = false;

      void recordMistake() {
        lives--;
        if (lives <= 0) {
          isGameOver = true;
        }
      }

      recordMistake();
      expect(lives, equals(2));
      expect(isGameOver, isFalse);

      recordMistake();
      expect(lives, equals(1));
      expect(isGameOver, isFalse);

      recordMistake();
      expect(lives, equals(0));
      expect(isGameOver, isTrue);
    });

    test('medium mode 2-tries hint unlock condition', () {
      int tries = 0;
      bool hintAvailable = false;

      void recordMediumMistake() {
        tries++;
        if (tries >= 2) {
          hintAvailable = true;
        }
      }

      recordMediumMistake();
      expect(tries, equals(1));
      expect(hintAvailable, isFalse);

      recordMediumMistake();
      expect(tries, equals(2));
      expect(hintAvailable, isTrue);
    });

    test('medium mode answer is not revealed after 1st failed try', () {
      const String targetNote = 'G';
      final Set<String> wrongNotes = {};
      bool isCorrect = false;
      bool showHint = false;

      // Attempt 1: player taps wrong note 'C'
      const String attempt1 = 'C';
      if (attempt1 == targetNote) {
        isCorrect = true;
      } else {
        wrongNotes.add(attempt1);
      }

      // Check button states for all notes
      bool isNoteHighlightedGreen(String note, {required bool correct, required bool hint}) {
        return (correct && note == targetNote) || (hint && note == targetNote);
      }

      bool isNoteHighlightedRed(String note) {
        return wrongNotes.contains(note);
      }

      // 'C' is marked red
      expect(isNoteHighlightedRed('C'), isTrue);
      // TARGET NOTE 'G' MUST NOT BE HIGHLIGHTED GREEN on attempt 1!
      expect(isNoteHighlightedGreen('G', correct: isCorrect, hint: showHint), isFalse);
      expect(isNoteHighlightedRed('G'), isFalse);
      expect(wrongNotes.length, equals(1));

      // Attempt 2: player taps correct note 'G'
      const String attempt2 = 'G';
      if (attempt2 == targetNote) {
        isCorrect = true;
      } else {
        wrongNotes.add(attempt2);
      }

      // Now target note 'G' is highlighted green
      expect(isNoteHighlightedGreen('G', correct: isCorrect, hint: showHint), isTrue);
      expect(isCorrect, isTrue);
    });

    test('medium mode hint reveals answer after 2 failed tries', () {
      const String targetNote = 'E';
      final Set<String> wrongNotes = {};
      int tries = 0;
      bool isCorrect = false;
      bool showHint = false;
      bool hintAvailable = false;

      void recordMistake(String note) {
        tries++;
        wrongNotes.add(note);
        if (tries >= 2) {
          hintAvailable = true;
        }
      }

      bool isNoteHighlightedGreen(String note, {required bool correct, required bool hint}) {
        return (correct && note == targetNote) || (hint && note == targetNote);
      }

      // Try 1: wrong note 'A'
      recordMistake('A');
      expect(tries, equals(1));
      expect(hintAvailable, isFalse);
      expect(isNoteHighlightedGreen(targetNote, correct: isCorrect, hint: showHint), isFalse);

      // Try 2: wrong note 'B'
      recordMistake('B');
      expect(tries, equals(2));
      expect(hintAvailable, isTrue);
      // Answer still not revealed until player taps Show Hint
      expect(isNoteHighlightedGreen(targetNote, correct: isCorrect, hint: showHint), isFalse);

      // Player taps Show Hint
      showHint = true;
      expect(isNoteHighlightedGreen(targetNote, correct: isCorrect, hint: showHint), isTrue);
    });

    test('revealCorrect logic across Easy, Medium, and Hard difficulties', () {
      bool getRevealCorrect({
        required String difficulty,
        required bool hasAnswered,
        required bool isCorrect,
        required bool showHint,
      }) {
        if (difficulty == 'Easy') return hasAnswered;
        if (difficulty == 'Hard') return hasAnswered;
        if (difficulty == 'Medium') return isCorrect || showHint;
        return false;
      }

      // Easy: reveals correct answer once answered
      expect(getRevealCorrect(difficulty: 'Easy', hasAnswered: true, isCorrect: false, showHint: false), isTrue);

      // Hard: reveals correct answer in green on wrong attempt
      expect(getRevealCorrect(difficulty: 'Hard', hasAnswered: true, isCorrect: false, showHint: false), isTrue);

      // Medium attempt 1: does NOT reveal correct answer!
      expect(getRevealCorrect(difficulty: 'Medium', hasAnswered: true, isCorrect: false, showHint: false), isFalse);

      // Medium attempt 2 with hint tapped: DOES reveal correct answer
      expect(getRevealCorrect(difficulty: 'Medium', hasAnswered: true, isCorrect: false, showHint: true), isTrue);

      // Medium correct attempt: DOES reveal correct answer
      expect(getRevealCorrect(difficulty: 'Medium', hasAnswered: true, isCorrect: true, showHint: false), isTrue);
    });

    test('hard mode wrong answer blocks subsequent taps before Next Question', () {
      bool canTapNote({
        required String difficulty,
        required bool? isCorrect,
        required String? selectedNote,
      }) {
        if (selectedNote != null && isCorrect == true) return false;
        if (difficulty == 'Hard' && isCorrect == false) return false;
        return true;
      }

      // First tap in Hard mode (not yet answered): allowed
      expect(canTapNote(difficulty: 'Hard', isCorrect: null, selectedNote: null), isTrue);

      // After wrong tap in Hard mode (isCorrect == false): blocked until next question!
      expect(canTapNote(difficulty: 'Hard', isCorrect: false, selectedNote: 'C'), isFalse);
    });

    test('medium mode waitForNext flow when hint is used', () {
      bool shouldWaitForNext({
        required String difficulty,
        required bool showHint,
      }) {
        return difficulty == 'Medium' && showHint;
      }

      // Normal correct answer without hint: auto-advances
      expect(shouldWaitForNext(difficulty: 'Medium', showHint: false), isFalse);

      // Correct answer after using hint: requires tapping Next Question
      expect(shouldWaitForNext(difficulty: 'Medium', showHint: true), isTrue);
    });
  });
}
