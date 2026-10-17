import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_musical_game/features/game/presentation/screens/game_screen.dart';

/// Checks Note Identification places each note on the correct line or
/// space of a treble stave (positions in half-spaces down from the top
/// line F5 = 0).
void main() {
  int pos(String n) => StaffPainter.staffPosition(n);

  test('lines of the treble stave: E4 bottom, G4 second, B4 middle', () {
    expect(pos('E'), 8);
    expect(pos('G'), 6);
    expect(pos('B'), 4);
  });

  test('spaces: F4 first space, A4 second space', () {
    expect(pos('F'), 7);
    expect(pos('A'), 5);
  });

  test('Middle C on the ledger line, D just below the stave', () {
    expect(pos('C'), 10);
    expect(pos('D'), 9);
  });

  test('sharps sit on the same line or space as their natural note', () {
    expect(pos('C#'), pos('C'));
    expect(pos('F#'), pos('F'));
  });

  test('notes rise in order C, D, E, F, G, A, B', () {
    final order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'].map(pos).toList();
    for (int i = 1; i < order.length; i++) {
      expect(order[i], order[i - 1] - 1);
    }
  });
}
