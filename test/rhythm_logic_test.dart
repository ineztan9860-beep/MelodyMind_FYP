import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rhythm Challenge Songs and Note Mapping Tests', () {
    final chromaticNotes = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];

    const hardSongSequences = [
      {
        'title': 'Für Elise',
        'notes': ['E', 'D#', 'E', 'D#', 'E', 'B', 'D', 'C', 'A', 'C', 'E', 'A', 'B'],
      },
      {
        'title': 'Pink Panther',
        'notes': ['D#', 'E', 'F#', 'G', 'D#', 'E', 'F#', 'G', 'C', 'B', 'A#', 'A'],
      },
      {
        'title': 'Canon in D',
        'notes': ['F#', 'E', 'D', 'C#', 'B', 'A', 'B', 'C#', 'D', 'C#', 'B', 'A'],
      },
      {
        'title': 'Greensleeves',
        'notes': ['A', 'C', 'D', 'E', 'F#', 'E', 'D', 'B', 'G', 'A', 'B', 'C'],
      },
      {
        'title': 'Mission Impossible',
        'notes': ['G', 'G', 'A#', 'C', 'G', 'G', 'F', 'F#', 'G', 'G', 'A#', 'C'],
      },
      {
        'title': 'Game of Thrones',
        'notes': ['G', 'C', 'D#', 'F', 'G', 'C', 'D#', 'F', 'D', 'A#', 'C', 'F#'],
      },
      {
        'title': 'Moonlight Sonata',
        'notes': ['G#', 'C#', 'E', 'G#', 'C#', 'E', 'A', 'C#', 'E', 'G#', 'C#'],
      },
    ];

    test('all 12 chromatic notes exist and are correctly identified', () {
      expect(chromaticNotes.length, equals(12));
      for (final note in ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']) {
        expect(chromaticNotes.contains(note), isTrue);
      }
    });

    test('hard mode songs all contain valid chromatic notes including accidentals', () {
      for (final song in hardSongSequences) {
        final title = song['title'] as String;
        final notes = song['notes'] as List<String>;
        expect(notes.isNotEmpty, isTrue, reason: '$title has notes');
        for (final note in notes) {
          expect(chromaticNotes.contains(note), isTrue,
              reason: 'Note $note in $title must be a valid chromatic note');
        }
      }
    });

    test('Fur Elise includes D# accidental', () {
      final furElise = hardSongSequences.firstWhere((s) => s['title'] == 'Für Elise');
      final notes = furElise['notes'] as List<String>;
      expect(notes.contains('D#'), isTrue);
    });

    test('Pink Panther includes D# and A# accidentals', () {
      final pinkPanther = hardSongSequences.firstWhere((s) => s['title'] == 'Pink Panther');
      final notes = pinkPanther['notes'] as List<String>;
      expect(notes.contains('D#'), isTrue);
      expect(notes.contains('A#'), isTrue);
    });

    test('Moonlight Sonata includes C# and G# accidentals', () {
      final moonlight = hardSongSequences.firstWhere((s) => s['title'] == 'Moonlight Sonata');
      final notes = moonlight['notes'] as List<String>;
      expect(notes.contains('C#'), isTrue);
      expect(notes.contains('G#'), isTrue);
    });
  });
}
