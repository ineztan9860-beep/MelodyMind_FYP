/// Song data and timing rules for Rhythm Challenge.
///
/// Each note carries a length in beats (1 = one metronome tick,
/// 0.5 = half a tick, 2 = two ticks), so the game knows *when*
/// every note is due, not just which key comes next.
library;

class RhythmNote {
  final String note;
  final double beats;
  const RhythmNote(this.note, this.beats);
}

class RhythmSong {
  final String title;
  final int bpm;
  final List<RhythmNote> notes;
  const RhythmSong(this.title, this.bpm, this.notes);

  List<String> get noteNames => notes.map((n) => n.note).toList();

  /// Milliseconds per metronome beat at this song's tempo.
  double get beatMs => 60000 / bpm;

  /// When each note is due, in ms after the count-in ends.
  List<double> get dueTimesMs {
    final times = <double>[];
    double t = 0;
    for (final n in notes) {
      times.add(t);
      t += n.beats * beatMs;
    }
    return times;
  }

  /// Total song length in ms (end of the last note).
  double get lengthMs =>
      notes.fold<double>(0, (sum, n) => sum + n.beats) * beatMs;
}

/// Medium (Practice): familiar songs at a slow practice tempo.
const List<RhythmSong> mediumSongs = [
  RhythmSong('Twinkle Twinkle Little Star', 80, [
    RhythmNote('C', 1), RhythmNote('C', 1), RhythmNote('G', 1), RhythmNote('G', 1),
    RhythmNote('A', 1), RhythmNote('A', 1), RhythmNote('G', 2),
    RhythmNote('F', 1), RhythmNote('F', 1), RhythmNote('E', 1), RhythmNote('E', 1),
    RhythmNote('D', 1), RhythmNote('D', 1), RhythmNote('C', 2),
  ]),
  RhythmSong('Mary Had a Little Lamb', 80, [
    RhythmNote('E', 1), RhythmNote('D', 1), RhythmNote('C', 1), RhythmNote('D', 1),
    RhythmNote('E', 1), RhythmNote('E', 1), RhythmNote('E', 2),
    RhythmNote('D', 1), RhythmNote('D', 1), RhythmNote('D', 2),
    RhythmNote('E', 1), RhythmNote('G', 1), RhythmNote('G', 2),
  ]),
  RhythmSong('Ode to Joy', 80, [
    RhythmNote('E', 1), RhythmNote('E', 1), RhythmNote('F', 1), RhythmNote('G', 1),
    RhythmNote('G', 1), RhythmNote('F', 1), RhythmNote('E', 1), RhythmNote('D', 1),
    RhythmNote('C', 1), RhythmNote('C', 1), RhythmNote('D', 1), RhythmNote('E', 1),
    RhythmNote('E', 1.5), RhythmNote('D', 0.5), RhythmNote('D', 2),
  ]),
  RhythmSong('Jingle Bells', 90, [
    RhythmNote('E', 1), RhythmNote('E', 1), RhythmNote('E', 2),
    RhythmNote('E', 1), RhythmNote('E', 1), RhythmNote('E', 2),
    RhythmNote('E', 1), RhythmNote('G', 1), RhythmNote('C', 1.5), RhythmNote('D', 0.5),
    RhythmNote('E', 4),
  ]),
  RhythmSong('Row Row Row Your Boat', 80, [
    RhythmNote('C', 1.5), RhythmNote('C', 1.5), RhythmNote('C', 1), RhythmNote('D', 0.5),
    RhythmNote('E', 1.5), RhythmNote('E', 1), RhythmNote('D', 0.5), RhythmNote('E', 1),
    RhythmNote('F', 0.5), RhythmNote('G', 3),
  ]),
  RhythmSong('Happy Birthday', 80, [
    RhythmNote('C', 0.75), RhythmNote('C', 0.25), RhythmNote('D', 1), RhythmNote('C', 1),
    RhythmNote('F', 1), RhythmNote('E', 2),
    RhythmNote('C', 0.75), RhythmNote('C', 0.25), RhythmNote('D', 1), RhythmNote('C', 1),
    RhythmNote('G', 1), RhythmNote('F', 2),
  ]),
  RhythmSong('Old MacDonald', 90, [
    RhythmNote('C', 1), RhythmNote('C', 1), RhythmNote('C', 1), RhythmNote('G', 1),
    RhythmNote('A', 1), RhythmNote('A', 1), RhythmNote('G', 2),
    RhythmNote('E', 1), RhythmNote('E', 1), RhythmNote('D', 1), RhythmNote('D', 1),
    RhythmNote('C', 2),
  ]),
  RhythmSong('Frere Jacques', 85, [
    RhythmNote('C', 1), RhythmNote('D', 1), RhythmNote('E', 1), RhythmNote('C', 1),
    RhythmNote('C', 1), RhythmNote('D', 1), RhythmNote('E', 1), RhythmNote('C', 1),
    RhythmNote('E', 1), RhythmNote('F', 1), RhythmNote('G', 2),
    RhythmNote('E', 1), RhythmNote('F', 1), RhythmNote('G', 2),
  ]),
];

/// Hard (Tempo Challenge): songs with sharps, in their real order,
/// at a faster tempo and with trickier rhythms.
const List<RhythmSong> hardSongs = [
  RhythmSong('Für Elise', 100, [
    RhythmNote('E', 0.5), RhythmNote('D#', 0.5), RhythmNote('E', 0.5), RhythmNote('D#', 0.5),
    RhythmNote('E', 0.5), RhythmNote('B', 0.5), RhythmNote('D', 0.5), RhythmNote('C', 0.5),
    RhythmNote('A', 1.5), RhythmNote('C', 0.5), RhythmNote('E', 0.5), RhythmNote('A', 0.5),
    RhythmNote('B', 1.5),
  ]),
  RhythmSong('Pink Panther', 110, [
    RhythmNote('D#', 0.5), RhythmNote('E', 1.5), RhythmNote('F#', 0.5), RhythmNote('G', 1.5),
    RhythmNote('D#', 0.5), RhythmNote('E', 0.5), RhythmNote('F#', 0.5), RhythmNote('G', 0.5),
    RhythmNote('C', 0.5), RhythmNote('B', 0.5), RhythmNote('A#', 1), RhythmNote('A', 2),
  ]),
  RhythmSong('Canon in D', 120, [
    RhythmNote('F#', 1), RhythmNote('E', 1), RhythmNote('D', 1), RhythmNote('C#', 1),
    RhythmNote('B', 1), RhythmNote('A', 1), RhythmNote('B', 1), RhythmNote('C#', 1),
    RhythmNote('D', 1), RhythmNote('C#', 1), RhythmNote('B', 1), RhythmNote('A', 2),
  ]),
  RhythmSong('Greensleeves', 120, [
    RhythmNote('A', 1), RhythmNote('C', 2), RhythmNote('D', 1),
    RhythmNote('E', 1.5), RhythmNote('F#', 0.5), RhythmNote('E', 1),
    RhythmNote('D', 2), RhythmNote('B', 1),
    RhythmNote('G', 1.5), RhythmNote('A', 0.5), RhythmNote('B', 1),
    RhythmNote('C', 2),
  ]),
  RhythmSong('Mission Impossible', 140, [
    RhythmNote('G', 1.5), RhythmNote('G', 1.5), RhythmNote('A#', 1), RhythmNote('C', 1),
    RhythmNote('G', 1.5), RhythmNote('G', 1.5), RhythmNote('F', 1), RhythmNote('F#', 1),
    RhythmNote('G', 1.5), RhythmNote('G', 1.5), RhythmNote('A#', 1), RhythmNote('C', 1),
  ]),
  RhythmSong('Game of Thrones', 120, [
    RhythmNote('G', 1), RhythmNote('C', 1), RhythmNote('D#', 0.5), RhythmNote('F', 0.5),
    RhythmNote('G', 1), RhythmNote('C', 1), RhythmNote('D#', 0.5), RhythmNote('F', 0.5),
    RhythmNote('D', 2), RhythmNote('A#', 1), RhythmNote('C', 1), RhythmNote('F#', 2),
  ]),
  RhythmSong('Moonlight Sonata', 60, [
    RhythmNote('G#', 1 / 3), RhythmNote('C#', 1 / 3), RhythmNote('E', 1 / 3),
    RhythmNote('G#', 1 / 3), RhythmNote('C#', 1 / 3), RhythmNote('E', 1 / 3),
    RhythmNote('A', 1 / 3), RhythmNote('C#', 1 / 3), RhythmNote('E', 1 / 3),
    RhythmNote('G#', 1 / 3), RhythmNote('C#', 1),
  ]),
];

/// How a tap lined up with the note it was meant for.
enum HitGrade { perfect, good, early, late }

/// Timing windows (± ms either side of the due time).
class TimingWindow {
  final double perfectMs;
  final double goodMs;
  const TimingWindow(this.perfectMs, this.goodMs);
}

/// Medium is generous because it is practice only.
const TimingWindow mediumWindow = TimingWindow(120, 250);

/// Hard is tight because timing is the challenge.
const TimingWindow hardWindow = TimingWindow(60, 120);

/// Grades a tap. [offsetMs] is tap time minus due time
/// (negative = early, positive = late).
HitGrade judgeTap(double offsetMs, TimingWindow w) {
  final a = offsetMs.abs();
  if (a <= w.perfectMs) return HitGrade.perfect;
  if (a <= w.goodMs) return HitGrade.good;
  return offsetMs < 0 ? HitGrade.early : HitGrade.late;
}

/// Hard-mode points for a correct key at a given grade.
int hardPointsFor(HitGrade g) {
  switch (g) {
    case HitGrade.perfect:
      return 100;
    case HitGrade.good:
      return 50;
    case HitGrade.early:
    case HitGrade.late:
      return 0;
  }
}

/// Volume of the metronome tick on a given beat during play
/// (beat 0 = first beat after the count-in).
/// Medium keeps ticking at full volume. Hard fades out over
/// the first bar so the player must keep the beat in their head.
double tickVolume({required bool hard, required int beatAfterCountIn}) {
  if (!hard) return 1.0;
  const fade = [0.6, 0.4, 0.2, 0.1];
  if (beatAfterCountIn < fade.length) return fade[beatAfterCountIn];
  return 0.0;
}

// ── End-of-song feedback (Hard) ─────────────────────────────────────────

/// What happened to each note in one Hard song.
class HardSongResult {
  final int perfect;
  final int good;
  final int early; // right key, tapped too early
  final int late; // right key, tapped too late
  final int wrongKey;
  final int noTap; // note passed with no tap at all

  const HardSongResult({
    this.perfect = 0,
    this.good = 0,
    this.early = 0,
    this.late = 0,
    this.wrongKey = 0,
    this.noTap = 0,
  });

  int get hits => perfect + good;
  int get missed => early + late + wrongKey + noTap;
  int get total => hits + missed;
  double get ratio => total == 0 ? 0 : hits / total;
}

/// Short headline, an emoji and an encouraging line, chosen by how many
/// notes were on time. Every tier stays positive because the goal is
/// learning, not judging.
({String emoji, String title, String message}) encouragementFor(
    HardSongResult r) {
  final p = r.ratio;
  if (p >= 1.0) {
    return (
      emoji: '🏆',
      title: 'Flawless!',
      message: 'Every note right on the beat. Your sense of tempo is excellent.'
    );
  }
  if (p >= 0.8) {
    return (
      emoji: '🌟',
      title: 'Excellent rhythm!',
      message: 'You kept the beat for almost the whole song. You are very close to perfect.'
    );
  }
  if (p >= 0.5) {
    return (
      emoji: '👏',
      title: 'Nice work!',
      message: 'You are getting the feel of the beat. A few more tries and it will click.'
    );
  }
  if (p >= 0.2) {
    return (
      emoji: '💪',
      title: 'Good effort!',
      message: 'Playing in time is a real skill, and every attempt trains your ear.'
    );
  }
  return (
    emoji: '🌱',
    title: 'Keep going!',
    message: 'Every musician starts slow. Learning the song first will make the beat much easier.'
  );
}

/// One practical tip based on the player's most common kind of mistake.
String learningTipFor(HardSongResult r) {
  if (r.missed == 0) {
    return 'Ready for more? Try another song at a different tempo.';
  }
  final counts = <String, int>{
    'late': r.late,
    'early': r.early,
    'wrong': r.wrongKey,
    'noTap': r.noTap,
  };
  final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  switch (top) {
    case 'late':
      return 'You were often a little late. Count "1, 2, 3, 4" in your head and tap on the number, not after it.';
    case 'early':
      return 'You were often a little early. Let each beat arrive before you tap. There is no need to rush.';
    case 'wrong':
      return 'Some keys were wrong. Try this song in Medium (Practice) first to learn where the notes are.';
    default:
      return 'Some notes passed without a tap. After a mistake, look at the highlighted box and jump straight back in.';
  }
}
