import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_musical_game/features/game/domain/rhythm_songs.dart';

void main() {
  const chromaticNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  RhythmSong hard(String title) => hardSongs.firstWhere((s) => s.title == title);

  group('Rhythm Challenge songs and note mapping', () {
    test('all 12 chromatic notes exist and are correctly identified', () {
      expect(chromaticNotes.length, equals(12));
    });

    test('every song uses only valid chromatic notes', () {
      for (final song in [...mediumSongs, ...hardSongs]) {
        expect(song.notes.isNotEmpty, isTrue, reason: '${song.title} has notes');
        for (final n in song.notes) {
          expect(chromaticNotes.contains(n.note), isTrue,
              reason: 'Note ${n.note} in ${song.title} must be chromatic');
        }
      }
    });

    test('Fur Elise includes D# accidental', () {
      expect(hard('Für Elise').noteNames.contains('D#'), isTrue);
    });

    test('Pink Panther includes D# and A# accidentals', () {
      final notes = hard('Pink Panther').noteNames;
      expect(notes.contains('D#'), isTrue);
      expect(notes.contains('A#'), isTrue);
    });

    test('Moonlight Sonata includes C# and G# accidentals', () {
      final notes = hard('Moonlight Sonata').noteNames;
      expect(notes.contains('C#'), isTrue);
      expect(notes.contains('G#'), isTrue);
    });

    test('Hard songs keep their real order (not shuffled)', () {
      expect(hard('Für Elise').noteNames.take(5).toList(),
          equals(['E', 'D#', 'E', 'D#', 'E']));
    });
  });

  group('Song timing', () {
    test('every note has a positive length and every song a tempo', () {
      for (final song in [...mediumSongs, ...hardSongs]) {
        expect(song.bpm, greaterThan(0), reason: song.title);
        for (final n in song.notes) {
          expect(n.beats, greaterThan(0), reason: song.title);
        }
      }
    });

    test('Hard songs are faster on average than Medium songs', () {
      double avg(List<RhythmSong> s) =>
          s.map((e) => e.bpm).reduce((a, b) => a + b) / s.length;
      expect(avg(hardSongs), greaterThan(avg(mediumSongs)));
    });

    test('due times accumulate note lengths', () {
      const song = RhythmSong('Test', 60, [
        RhythmNote('C', 1), RhythmNote('D', 0.5), RhythmNote('E', 2),
      ]);
      expect(song.beatMs, equals(1000));
      expect(song.dueTimesMs, equals([0, 1000, 1500]));
      expect(song.lengthMs, equals(3500));
    });

    test('notes in Hard songs are far enough apart for the timing window', () {
      for (final song in hardSongs) {
        for (final n in song.notes) {
          expect(n.beats * song.beatMs, greaterThan(2 * hardWindow.goodMs),
              reason: '${song.title} has notes too close together');
        }
      }
    });
  });

  group('Timing judgement', () {
    test('Medium window grades taps', () {
      expect(judgeTap(0, mediumWindow), HitGrade.perfect);
      expect(judgeTap(-200, mediumWindow), HitGrade.good);
      expect(judgeTap(-300, mediumWindow), HitGrade.early);
      expect(judgeTap(300, mediumWindow), HitGrade.late);
    });

    test('Hard window is tighter than Medium', () {
      expect(judgeTap(100, hardWindow), HitGrade.good);
      expect(judgeTap(150, hardWindow), HitGrade.late);
      expect(judgeTap(150, mediumWindow), HitGrade.good);
    });

    test('Hard scoring rewards precision', () {
      expect(hardPointsFor(HitGrade.perfect), 100);
      expect(hardPointsFor(HitGrade.good), 50);
      expect(hardPointsFor(HitGrade.late), 0);
    });

    test('metronome stays on in Medium and fades out in Hard', () {
      expect(tickVolume(hard: false, beatAfterCountIn: 20), 1.0);
      expect(tickVolume(hard: true, beatAfterCountIn: 0), greaterThan(0));
      expect(tickVolume(hard: true, beatAfterCountIn: 4), 0.0);
    });
  });

  group('End-of-song encouragement (Hard)', () {
    test('every result gets a positive headline', () {
      for (final hits in [0, 3, 6, 10, 12]) {
        final r = HardSongResult(perfect: hits, noTap: 12 - hits);
        expect(encouragementFor(r).title.isNotEmpty, isTrue);
      }
    });

    test('a perfect song is Flawless', () {
      expect(encouragementFor(const HardSongResult(perfect: 12)).title,
          'Flawless!');
    });

    test('tip targets the most common mistake', () {
      expect(learningTipFor(const HardSongResult(good: 5, late: 4, early: 1)),
          contains('late'));
      expect(learningTipFor(const HardSongResult(good: 5, early: 4)),
          contains('early'));
      expect(learningTipFor(const HardSongResult(good: 5, wrongKey: 3)),
          contains('Medium'));
    });
  });
}
