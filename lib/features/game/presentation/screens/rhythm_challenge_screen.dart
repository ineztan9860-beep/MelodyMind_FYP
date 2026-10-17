import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/core/providers/audio_provider.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

import 'dart:async';
import 'dart:math';

import '../../domain/rhythm_songs.dart';

/// Piano-keyboard rhythm challenge.
/// The player taps the correct piano keys to match each note in the sequence.
/// Easy mode: Keys show note labels, random notes, no timing.
/// Medium mode (Practice): familiar songs, no key labels, metronome
///   at a slow tempo; timing feedback only, score unaffected by timing.
/// Hard mode (Tempo Challenge): sharp-note songs in their real order,
///   faster tempo, tight timing window, metronome fades after the
///   count-in, and the song does not wait for the player.
class RhythmChallengeScreen extends ConsumerStatefulWidget {
  const RhythmChallengeScreen({super.key});

  @override
  ConsumerState<RhythmChallengeScreen> createState() =>
      _RhythmChallengeScreenState();
}

class _RhythmChallengeScreenState
    extends ConsumerState<RhythmChallengeScreen> {
  final List<String> _allChromaticNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  final Random _random = Random();

  // ── Game state ──────────────────────────────────────────────────────────
  int _score = 0;
  int _correctTaps = 0;
  int _totalTaps = 0;
  int _currentIndex = 0;
  bool _isGameOver = false;
  String _feedback = '';
  Color _feedbackColor = Colors.transparent;
  int _feedbackToken = 0;
  bool _showHint = false; // show label hint after wrong tap
  String _difficulty = 'Easy';
  RhythmSong? _currentSong;
  double _savedAcc = 0;
  int _savedXp = 0;

  late List<String> _sequence;
  String? _activePressedKey;

  // ── Tempo state (Medium & Hard only) ────────────────────────────────────
  static const int _countInBeats = 4;
  static const int _beatsPerBar = 4;

  /// Allowance for the delay between the app playing a tick and the
  /// player hearing it. Players tap to what they hear, so due times are
  /// shifted by this amount. Tune on a real device if taps feel early/late.
  static const double _audioLatencyMs = 50;

  final Stopwatch _clock = Stopwatch();
  Timer? _loop;
  bool _isPlaying = false; // count-in or song in progress
  double _songStartMs = 0; // clock time the first note is due
  int _nextTickBeat = 0; // next metronome tick, counted from count-in start
  int _currentBeat = -1; // latest tick played (for the beat indicator)
  List<double> _dueTimes = const [];
  // Hard: what happened to each note in the current song
  int _songPerfect = 0;
  int _songGood = 0;
  int _songEarly = 0;
  int _songLate = 0;
  int _songWrong = 0;
  int _songNoTap = 0;

  HardSongResult get _songResult => HardSongResult(
        perfect: _songPerfect,
        good: _songGood,
        early: _songEarly,
        late: _songLate,
        wrongKey: _songWrong,
        noTap: _songNoTap,
      );
  bool _hardBriefingSeen = false; // Hard briefing shown once per visit

  bool get _isTempoMode => _difficulty != 'Easy';
  bool get _isHard => _difficulty == 'Hard';
  String? get _currentSongTitle => _currentSong?.title;

  @override
  void initState() {
    super.initState();
    _generateSequence();
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  bool _initializedDifficulty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDifficulty) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null && (args == 'Easy' || args == 'Medium' || args == 'Hard')) {
        _difficulty = args;
        _generateSequence();
      }
      _initializedDifficulty = true;
    }
  }

  /// Picks a random song, avoiding [avoid] when there is a choice,
  /// so "Next Song" never repeats the song just played.
  RhythmSong _pickSong(List<RhythmSong> songs, RhythmSong? avoid) {
    final options =
        songs.length > 1 ? songs.where((s) => s != avoid).toList() : songs;
    return options[_random.nextInt(options.length)];
  }

  void _generateSequence({RhythmSong? avoid}) {
    _stopTempo();
    if (_difficulty == 'Medium') {
      // Medium (Practice): familiar songs in order, slow tempo, metronome on
      _currentSong = _pickSong(mediumSongs, avoid);
      _sequence = _currentSong!.noteNames;
    } else if (_difficulty == 'Hard') {
      // Hard (Tempo Challenge): sharp-note songs in their real order,
      // faster tempo, tight timing, metronome fades after the count-in
      _currentSong = _pickSong(hardSongs, avoid);
      _sequence = _currentSong!.noteNames;
    } else {
      // Easy: random sequence containing all note letters (white & black keys), with key labels visible
      _currentSong = null;
      _sequence = List.generate(10, (i) {
        return _allChromaticNotes[_random.nextInt(_allChromaticNotes.length)];
      });
    }
    _currentIndex = 0;
    _showHint = false;
  }

  /// Sets the feedback text and clears it after 1.2 s, unless newer
  /// feedback has replaced it in the meantime.
  void _setFeedback(String text, Color color) {
    _feedback = text;
    _feedbackColor = color;
    final token = ++_feedbackToken;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && token == _feedbackToken) {
        setState(() => _feedback = '');
      }
    });
  }

  // ── Tempo engine ────────────────────────────────────────────────────────

  /// Cancels the metronome. Does not call setState; callers wrap it.
  void _stopTempo() {
    _loop?.cancel();
    _loop = null;
    _clock.stop();
    _isPlaying = false;
    _currentBeat = -1;
  }

  void _startSong() {
    final song = _currentSong;
    if (song == null || _isPlaying || _isGameOver) return;
    setState(() {
      _currentIndex = 0;
      _showHint = false;
      _songPerfect = 0;
      _songGood = 0;
      _songEarly = 0;
      _songLate = 0;
      _songWrong = 0;
      _songNoTap = 0;
      _feedback = '';
      _dueTimes = song.dueTimesMs;
      _songStartMs = _countInBeats * song.beatMs;
      _nextTickBeat = 0;
      _currentBeat = -1;
      _isPlaying = true;
      _clock
        ..reset()
        ..start();
    });
    _loop?.cancel();
    // A short polling loop against a Stopwatch keeps the beat steady;
    // a Timer firing once per beat would slowly drift.
    _loop = Timer.periodic(const Duration(milliseconds: 10), (_) => _onLoop());
  }

  void _stopSong() {
    setState(() {
      _stopTempo();
      _currentIndex = 0;
      _showHint = false;
      _setFeedback('Stopped', const Color(0xFF64748B));
    });
  }

  void _onLoop() {
    if (!mounted || !_isPlaying || _currentSong == null) return;
    final song = _currentSong!;
    final now = _clock.elapsedMicroseconds / 1000.0;
    final beatMs = song.beatMs;
    bool changed = false;

    // Metronome ticks
    while (now >= _nextTickBeat * beatMs) {
      final beat = _nextTickBeat++;
      _currentBeat = beat;
      changed = true;
      // Skip ticks that are already well past (e.g. app was paused)
      if (now - beat * beatMs > 60) continue;
      final afterCountIn = beat - _countInBeats;
      final volume = afterCountIn < 0
          ? 1.0
          : tickVolume(hard: _isHard, beatAfterCountIn: afterCountIn);
      ref.read(audioServiceProvider).playTick(
            accent: beat % _beatsPerBar == 0,
            volume: volume,
          );
    }

    // Hard: the song does not wait. A note whose timing window has
    // passed without a tap counts as a miss and the song moves on.
    if (_isHard) {
      while (_currentIndex < _sequence.length &&
          now > _noteDueMs(_currentIndex) + hardWindow.goodMs) {
        _totalTaps++;
        _songNoTap++;
        _currentIndex++;
        _setFeedback('Missed!', const Color(0xFFEF4444));
        changed = true;
      }
    }

    if (changed) setState(() {});
    if (_isHard && _currentIndex >= _sequence.length) _finishSong();
  }

  /// Clock time (ms) at which note [i] should be tapped.
  double _noteDueMs(int i) => _songStartMs + _dueTimes[i] + _audioLatencyMs;

  Future<void> _finishSong() async {
    if (!_isPlaying) return; // already finished (guards double calls)

    if (!_isHard) {
      setState(() {
        _score += 500;
        _generateSequence(); // stops the metronome and loads the next song
        _setFeedback('Song Complete! +500 Bonus', const Color(0xFF10B981));
      });
      return;
    }

    // Hard: stop, add the bonus, then show an encouraging summary
    // before the next song, since the aim is learning.
    final song = _currentSong;
    final result = _songResult;
    final bonus = (500 * result.ratio).round();
    setState(() {
      _stopTempo();
      _score += bonus;
    });
    final tryAgain = await _showHardSummary(result, bonus);
    if (!mounted || _isGameOver) return;
    setState(() {
      if (tryAgain == true) {
        // Same song again; player presses Start when ready
        _currentIndex = 0;
        _showHint = false;
        _setFeedback('Same song again. You can do it!',
            const Color(0xFF3B82F6));
      } else {
        _generateSequence(avoid: song);
      }
    });
  }

  /// End-of-song card for Hard. Returns true for "Try Again".
  Future<bool?> _showHardSummary(HardSongResult result, int bonus) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const red = Color(0xFFEF4444);
    final words = encouragementFor(result);
    final tip = learningTipFor(result);

    Widget stat(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
            ],
          ),
        );

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: red.withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(words.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(words.title, style: theme.textTheme.headlineMedium),
              if (_currentSongTitle != null) ...[
                const SizedBox(height: 4),
                Text(_currentSongTitle!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Text('${result.hits} / ${result.total} notes on time',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  stat('Perfect', result.perfect, const Color(0xFF10B981)),
                  stat('Good', result.good, const Color(0xFF3B82F6)),
                  stat('Missed', result.missed, red),
                ],
              ),
              const SizedBox(height: 8),
              Text('+$bonus bonus',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              const SizedBox(height: 16),
              Text(words.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tip,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: red),
                        foregroundColor: red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Try Again',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Next Song',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Taps ────────────────────────────────────────────────────────────────

  void _handleKeyTap(String note) {
    if (_isGameOver) return;
    // Read the clock first, before any other work, for accurate timing
    final tapMs = _clock.elapsedMicroseconds / 1000.0;

    ref.read(audioServiceProvider).playNote(note);
    setState(() => _activePressedKey = note);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _activePressedKey == note) {
        setState(() => _activePressedKey = null);
      }
    });

    if (!_isTempoMode) {
      _judgeEasy(note);
      return;
    }
    if (!_isPlaying) {
      setState(() =>
          _setFeedback('Press Start to begin', const Color(0xFFF59E0B)));
      return;
    }
    final window = _isHard ? hardWindow : mediumWindow;
    if (tapMs < _songStartMs + _audioLatencyMs - window.goodMs) {
      setState(() =>
          _setFeedback('Wait for the count-in…', const Color(0xFFF59E0B)));
      return;
    }
    if (_isHard) {
      _judgeHard(note, tapMs);
    } else {
      _judgeMedium(note, tapMs);
    }
  }

  /// Easy: unchanged from before. No timing; a wrong key restarts the sequence.
  void _judgeEasy(String note) {
    final expected = _sequence[_currentIndex];
    setState(() {
      _totalTaps++;
      if (note == expected) {
        _correctTaps++;
        _score += 100;
        _setFeedback('CORRECT! +100', const Color(0xFF10B981));
        _showHint = false;
        _currentIndex++;
        if (_currentIndex >= _sequence.length) {
          _score += 500; // bonus for completing sequence
          _generateSequence();
          _setFeedback('Sequence Complete! +500 Bonus', const Color(0xFF10B981));
        }
      } else {
        _setFeedback('Wrong key! Try again', const Color(0xFFEF4444));
        _showHint = true; // reveal a brief hint after mistake
        _currentIndex = 0; // reset to start of sequence
      }
    });
  }

  /// Medium (Practice): timing feedback only. Score depends on the key,
  /// not the timing. A wrong key keeps you on the same note.
  void _judgeMedium(String note, double tapMs) {
    final song = _currentSong!;
    final expected = _sequence[_currentIndex];
    bool finished = false;
    setState(() {
      _totalTaps++;
      if (note == expected) {
        _correctTaps++;
        _score += 100;
        _showHint = false;
        final offset = tapMs - _noteDueMs(_currentIndex);
        switch (judgeTap(offset, mediumWindow)) {
          case HitGrade.perfect:
            _setFeedback('Perfect timing! +100', const Color(0xFF10B981));
          case HitGrade.good:
            _setFeedback('Good timing +100', const Color(0xFF3B82F6));
          case HitGrade.early:
            _setFeedback('A little early +100', const Color(0xFFF59E0B));
          case HitGrade.late:
            _setFeedback('A little late +100', const Color(0xFFF59E0B));
        }
        // If the player has drifted more than a beat away, move the
        // schedule by whole beats so it stays in step with the metronome.
        if (offset.abs() > song.beatMs) {
          _songStartMs += (offset / song.beatMs).round() * song.beatMs;
        }
        _currentIndex++;
        finished = _currentIndex >= _sequence.length;
      } else {
        _setFeedback('Wrong key! Try again', const Color(0xFFEF4444));
        _showHint = true;
      }
    });
    if (finished) _finishSong();
  }

  /// Hard (Tempo Challenge): each note gets one chance. Right key inside
  /// the window scores; wrong key or bad timing is a miss and the song
  /// moves on.
  void _judgeHard(String note, double tapMs) {
    final i = _currentIndex;
    if (i >= _sequence.length) return;
    final grade = judgeTap(tapMs - _noteDueMs(i), hardWindow);
    setState(() {
      _totalTaps++;
      if (note != _sequence[i]) {
        _songWrong++;
        _setFeedback('Wrong key — Missed', const Color(0xFFEF4444));
      } else if (grade == HitGrade.perfect || grade == HitGrade.good) {
        _correctTaps++;
        if (grade == HitGrade.perfect) {
          _songPerfect++;
        } else {
          _songGood++;
        }
        final pts = hardPointsFor(grade);
        _score += pts;
        _setFeedback(
          grade == HitGrade.perfect ? 'Perfect! +$pts' : 'Good +$pts',
          grade == HitGrade.perfect
              ? const Color(0xFF10B981)
              : const Color(0xFF3B82F6),
        );
      } else {
        if (grade == HitGrade.early) {
          _songEarly++;
        } else {
          _songLate++;
        }
        _setFeedback(
          grade == HitGrade.early ? 'Too early — Missed' : 'Too late — Missed',
          const Color(0xFFEF4444),
        );
      }
      _currentIndex++;
    });
    if (_currentIndex >= _sequence.length) _finishSong();
  }

  Future<void> _endGame() async {
    double acc = _totalTaps == 0 ? 0.0 : (_correctTaps / _totalTaps) * 100;
    int xp = _score ~/ 10;
    setState(() {
      _stopTempo();
      _isGameOver = true;
      _savedAcc = acc;
      _savedXp = xp;
    });
    await ref.read(userProfileNotifierProvider.notifier).saveGameResult(
          scoreGained: _score,
          xpGained: xp,
          correctAnswers: _correctTaps,
          totalAnswers: _totalTaps,
          incrementStreak: _correctTaps > 0,
          gameMode: 'Rhythm Challenge',
        );
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _correctTaps = 0;
      _totalTaps = 0;
      _isGameOver = false;
      _feedback = '';
      _showHint = false;
      _generateSequence();
    });
  }

  double get _accuracy =>
      _totalTaps == 0 ? 100 : (_correctTaps / _totalTaps) * 100;

  // ── Hard briefing ───────────────────────────────────────────────────────

  /// Start button handler. In Hard, the first Start of each visit shows
  /// a briefing so the player knows the song begins right after the
  /// count-in and will not wait for them.
  Future<void> _onStartPressed() async {
    if (_isHard && !_hardBriefingSeen) {
      final ready = await _showHardBriefing();
      if (!mounted || ready != true) return;
      _hardBriefingSeen = true;
    }
    _startSong();
  }

  /// Opened from the (?) icon. Choosing "I'm Ready!" starts the song.
  Future<void> _openHardBriefing() async {
    final ready = await _showHardBriefing();
    if (!mounted || ready != true) return;
    _hardBriefingSeen = true;
    _startSong();
  }

  Future<bool?> _showHardBriefing() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const red = Color(0xFFEF4444);
    final song = _currentSong;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: red.withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 52, color: red),
              const SizedBox(height: 12),
              Text('Tempo Challenge', style: theme.textTheme.headlineMedium),
              if (song != null) ...[
                const SizedBox(height: 4),
                Text('${song.title} · ${song.bpm} BPM',
                    style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 20),
              _briefingStep('1', '🎧 Count-in',
                  'After you tap "I\'m Ready!", press nothing yet. You will hear 4 ticks counting down 4, 3, 2, 1. The song starts by itself right after the 4th tick.',
                  theme),
              const SizedBox(height: 12),
              _briefingStep('2', '🎯 Follow the highlighted note',
                  'Tap the key shown in the highlighted box of the target sequence, on the beat. It turns green when you hit it, and the next box lights up.',
                  theme),
              const SizedBox(height: 12),
              _briefingStep('3', '⏱️ The song will not wait',
                  'Each note gets one chance. A wrong key, or a tap that is too early or too late, counts as missed and the song moves on.',
                  theme),
              const SizedBox(height: 12),
              _briefingStep('4', '🔇 Keep the beat',
                  'The metronome fades out after the first bar. Keep counting the beat in your head.',
                  theme),
              const SizedBox(height: 12),
              _briefingStep('5', '🏆 Score',
                  'Perfect timing +100, Good +50, plus a bonus for every note you hit on time.',
                  theme),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF64748B)),
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Not yet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("I'm Ready!",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _briefingStep(
      String num, String title, String desc, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  /// Big countdown shown during the count-in: 4, 3, 2, 1, then GO!
  Widget _countdown() {
    String? label;
    if (_isPlaying && _currentBeat >= 0) {
      final afterCountIn = _currentBeat - _countInBeats;
      if (afterCountIn < 0) {
        label = '${_countInBeats - _currentBeat}';
      } else if (afterCountIn == 0) {
        label = 'GO!';
      }
    }
    final color = _isHard ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    if (label == null) return const SizedBox.shrink();
    // Floats over the screen, so it takes no extra space in the layout
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  // ── Tempo bar (Medium & Hard) ───────────────────────────────────────────

  Widget _tempoBar(ThemeData theme, bool isDark) {
    final song = _currentSong;
    if (song == null) return const SizedBox.shrink();
    final afterCountIn = _currentBeat - _countInBeats;
    final inCountIn = _isPlaying && _currentBeat >= 0 && afterCountIn < 0;
    // In Hard the visual beat disappears along with the sound
    final showBeat = _isPlaying &&
        _currentBeat >= 0 &&
        (!_isHard || afterCountIn < 4);
    final activeDot = showBeat ? _currentBeat % _beatsPerBar : -1;
    final accent = _isHard ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    String status;
    if (!_isPlaying) {
      status = '${song.bpm} BPM · 4-beat count-in';
    } else if (_currentBeat < 0 || inCountIn) {
      status = 'Count-in… get ready!';
    } else if (_isHard && afterCountIn >= 4) {
      status = 'Keep the beat in your head!';
    } else {
      status = 'Play along with the beat';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          ...List.generate(_beatsPerBar, (i) {
            final on = i == activeDot;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              margin: const EdgeInsets.only(right: 6),
              width: on ? 14 : 10,
              height: on ? 14 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on
                    ? accent
                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
              ),
            );
          }),
          const SizedBox(width: 6),
          Expanded(
            child: Text(status,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (_isHard && !_isPlaying)
            IconButton(
              tooltip: 'How Tempo Challenge works',
              onPressed: _openHardBriefing,
              icon: Icon(Icons.help_outline, color: accent, size: 22),
            ),
          ElevatedButton.icon(
            onPressed: _isGameOver
                ? null
                : (_isPlaying ? _stopSong : _onStartPressed),
            icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 18),
            label: Text(_isPlaying ? 'Stop' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPlaying ? const Color(0xFF64748B) : accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileNotifierProvider).value;
    final level = profile?.level ?? 0;
    final xp = (profile?.xp ?? 0) + (_score ~/ 10);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Positioned.fill keeps the game layout full-screen inside the Stack
            Positioned.fill(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Icon(Icons.arrow_back,
                              color: isDark
                                  ? const Color(0xFF22D3EE)
                                  : const Color(0xFF1E3A8A),
                              size: 20),
                        ),
                      ),
                      Text('Rhythm Challenge',
                          style: theme.textTheme.headlineMedium),
                      // Logo → navigate to home
                      GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (_) => false),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: ClipOval(
                            child: Image.asset('assets/images/logo.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Stats badges ─────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _badge('Level $level', theme, isDark),
                      const SizedBox(width: 10),
                      _badge('XP $xp', theme, isDark),
                      const SizedBox(width: 10),
                      _badge('${_accuracy.round()}%', theme, isDark),
                    ],
                  ),
                ),

                // ── Difficulty Selector ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Easy'),
                          selected: _difficulty == 'Easy',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _difficulty = 'Easy';
                                _generateSequence();
                              });
                            }
                          },
                          selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(
                            color: _difficulty == 'Easy' ? const Color(0xFF10B981) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Medium (Songs)'),
                          selected: _difficulty == 'Medium',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _difficulty = 'Medium';
                                _generateSequence();
                              });
                            }
                          },
                          selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF3B82F6),
                          labelStyle: TextStyle(
                            color: _difficulty == 'Medium' ? const Color(0xFF3B82F6) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Hard (Tempo Challenge)'),
                          selected: _difficulty == 'Hard',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _difficulty = 'Hard';
                                _generateSequence();
                              });
                            }
                          },
                          selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFFEF4444),
                          labelStyle: TextStyle(
                            color: _difficulty == 'Hard' ? const Color(0xFFEF4444) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Target sequence ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _difficulty == 'Hard' && _currentSongTitle != null
                              ? 'Challenge: $_currentSongTitle — tap in order:'
                              : _currentSongTitle != null
                                  ? 'Song: $_currentSongTitle — tap in order:'
                                  : 'Target Sequence — tap in order:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        // Show the whole sequence without horizontal scrolling.
                        // Tiles wrap onto a second row and shrink slightly when
                        // needed so the full sequence fits in at most two rows.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double gap = 6;
                            const double maxTile = 34;
                            const double minTile = 26;
                            final int n = _sequence.length;
                            final double width = constraints.maxWidth;
                            final int fitAtMax =
                                ((width + gap) / (maxTile + gap)).floor().clamp(1, n).toInt();
                            double tile = maxTile;
                            if ((n / fitAtMax).ceil() > 2) {
                              final int perRow = (n / 2).ceil();
                              tile = ((width - (perRow - 1) * gap) / perRow)
                                  .clamp(minTile, maxTile).toDouble();
                            }
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: List.generate(n, (i) {
                                final isNext = i == _currentIndex && !_isGameOver;
                                final isDone = i < _currentIndex;
                                return Container(
                                  width: tile,
                                  height: tile,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? const Color(0xFF10B981)
                                        : isNext
                                            ? const Color(0xFF1E3A8A)
                                            : (isDark
                                                ? Colors.white10
                                                : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isNext
                                        ? Border.all(
                                            color: const Color(0xFF22D3EE), width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      // Always show the note name in the sequence bar
                                      _sequence[i],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isDone || isNext
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white60
                                                : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tempo bar (Medium & Hard) ────────────────────────────────
                if (_isTempoMode && !_isGameOver) _tempoBar(theme, isDark),

                // ── Score + Feedback ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Score',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 11)),
                          Text('$_score',
                              style: theme.textTheme.headlineLarge
                                  ?.copyWith(fontSize: 22)),
                        ],
                      ),
                      if (_feedback.isNotEmpty)
                        Expanded(
                          child: Text(
                            _feedback,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _feedbackColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Hint strip ───────────────────────────────────────────────
                if (_showHint && !_isGameOver && _currentIndex < _sequence.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Hint: next key is  ${_sequence[_currentIndex]}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                const Spacer(),

                // ── Piano keyboard ────────────────────────────────────────────
                if (!_isGameOver)
                  _PianoKeyboard(
                    onKeyTap: _handleKeyTap,
                    activePressedKey: _activePressedKey,
                    isDark: isDark,
                    // Pass the next expected note so it can glow
                    nextExpectedNote:
                        _sequence[min(_currentIndex, _sequence.length - 1)],
                    difficulty: _difficulty,
                  )
                else
                  _gameOverSheet(context, theme, isDark),

                // Finish game button
                if (!_isGameOver)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _endGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Finish & Save Score',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
              ],
            ),
            ),
            // Count-in countdown in the centre of the screen
            // (IgnorePointer lets taps pass straight through)
            if (_isTempoMode && !_isGameOver)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: _countdown()),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _badge(String text, ThemeData theme, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Text(text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _gameOverSheet(
      BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            const Icon(Icons.piano, size: 48, color: Color(0xFF22D3EE)),
            const SizedBox(height: 12),
            Text('Round Complete!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Final Score: $_score', style: theme.textTheme.titleLarge),
            Text('Accuracy: ${_accuracy.round()}%',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            // See Full Results
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/results',
                  arguments: {
                    'score': _score,
                    'accuracy': _savedAcc,
                    'xpGained': _savedXp,
                    'gameMode': 'rhythm',
                    'difficulty': _difficulty,
                  },
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('See Full Results',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restartGame,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Play Again',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (_) => false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark
                        ? const Color(0xFF22D3EE)
                        : const Color(0xFF64748B)),
                    foregroundColor: isDark
                        ? const Color(0xFF22D3EE)
                        : const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Return Home',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Piano Keyboard Widget ────────────────────────────────────────────────────

class _PianoKeyboard extends StatelessWidget {
  final void Function(String note) onKeyTap;
  final String? activePressedKey;
  final bool isDark;
  final String nextExpectedNote;
  final String difficulty;

  const _PianoKeyboard({
    required this.onKeyTap,
    required this.activePressedKey,
    required this.isDark,
    required this.nextExpectedNote,
    required this.difficulty,
  });

  static const _whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const _blackNoteData = [
    {'note': 'C#', 'pos': 0},
    {'note': 'D#', 'pos': 1},
    {'note': 'F#', 'pos': 3},
    {'note': 'G#', 'pos': 4},
    {'note': 'A#', 'pos': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const keyboardH = 155.0;
      final totalW = constraints.maxWidth;
      final whiteW = totalW / _whiteNotes.length;
      final blackW = whiteW * 0.55;
      const blackH = keyboardH * 0.62;

      return SizedBox(
        height: keyboardH,
        child: Stack(
          children: [
            // White keys — show labels in Easy mode
            Row(
              children: _whiteNotes.map((note) {
                final isActive = activePressedKey == note;
                return GestureDetector(
                  onTapDown: (_) => onKeyTap(note),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: whiteW - 2,
                    height: keyboardH,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF22D3EE)
                          : (isDark
                              ? const Color(0xFFE2E8F0)
                              : Colors.white),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.black54
                            : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: difficulty == 'Easy'
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                note,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF1E3A8A)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            // Black keys — show labels in Easy mode
            ..._blackNoteData.map((data) {
              final note = data['note'] as String;
              final pos = data['pos'] as int;
              final isActive = activePressedKey == note;
              final left = (pos + 1) * whiteW - (blackW / 2);
              return Positioned(
                left: left,
                top: 0,
                child: GestureDetector(
                  onTapDown: (_) => onKeyTap(note),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: blackW,
                    height: blackH,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF22D3EE)
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF1E3A8A)),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: difficulty == 'Easy'
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                note,
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF1E3A8A)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
