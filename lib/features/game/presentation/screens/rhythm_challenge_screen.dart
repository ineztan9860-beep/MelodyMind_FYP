import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/core/providers/audio_provider.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

/// Piano-keyboard rhythm challenge.
/// The player taps the correct piano keys to match each note in the sequence.
/// Keys show NO labels by default (Hard mode) — only the next expected note
/// glows with a subtle hint after a wrong tap.
class RhythmChallengeScreen extends ConsumerStatefulWidget {
  const RhythmChallengeScreen({super.key});

  @override
  ConsumerState<RhythmChallengeScreen> createState() =>
      _RhythmChallengeScreenState();
}

class _RhythmChallengeScreenState
    extends ConsumerState<RhythmChallengeScreen> {
  final List<String> _naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  // ── Game state ──────────────────────────────────────────────────────────
  int _score = 0;
  int _correctTaps = 0;
  int _totalTaps = 0;
  int _currentIndex = 0;
  bool _isGameOver = false;
  String _feedback = '';
  Color _feedbackColor = Colors.transparent;
  bool _showHint = false; // show label hint after wrong tap
  String _difficulty = 'Medium';

  late List<String> _sequence;
  String? _activePressedKey;

  @override
  void initState() {
    super.initState();
    _generateSequence();
  }

  bool _initializedDifficulty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDifficulty) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        _difficulty = args;
      }
      _initializedDifficulty = true;
    }
  }

  void _generateSequence() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    _sequence = List.generate(10, (i) {
      return _naturalNotes[(rng + i * 37) % _naturalNotes.length];
    });
    _currentIndex = 0;
    _showHint = false;
  }

  void _handleKeyTap(String note) async {
    if (_isGameOver) return;

    ref.read(audioServiceProvider).playNote(note);
    setState(() => _activePressedKey = note);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _activePressedKey = null);

    final expected = _sequence[_currentIndex];
    setState(() {
      _totalTaps++;
      if (note == expected) {
        _correctTaps++;
        _score += 100;
        _feedback = 'CORRECT! +100';
        _feedbackColor = const Color(0xFF10B981);
        _showHint = false;
        _currentIndex++;
        if (_currentIndex >= _sequence.length) {
          _score += 500; // bonus for completing sequence
          _generateSequence();
          _feedback = '🎉 Sequence Complete! +500 Bonus';
        }
      } else {
        _feedback = 'Wrong key! Try again';
        _feedbackColor = const Color(0xFFEF4444);
        _showHint = true; // reveal a brief hint after mistake
        _currentIndex = 0; // reset to start of sequence
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _feedback = '');
    });
  }

  Future<void> _endGame() async {
    setState(() => _isGameOver = true);
    double acc = _totalTaps == 0 ? 0.0 : (_correctTaps / _totalTaps) * 100;
    int xp = _score ~/ 10;
    await ref.read(userProfileNotifierProvider.notifier).saveGameResult(
          scoreGained: _score,
          xpGained: xp,
          correctAnswers: _correctTaps,
          totalAnswers: _totalTaps,
          incrementStreak: _correctTaps > 0,
        );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/results', arguments: {
        'score': _score,
        'accuracy': acc,
        'xpGained': xp,
      });
    }
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _correctTaps = 0;
      _totalTaps = 0;
      _isGameOver = false;
      _feedback = '';
      _showHint = false;
    });
    _generateSequence();
  }

  double get _accuracy =>
      _totalTaps == 0 ? 100 : (_correctTaps / _totalTaps) * 100;

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Medium Mode (Labels)'),
                    selected: _difficulty == 'Medium',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _difficulty = 'Medium';
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
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Hard Mode (No Labels)'),
                    selected: _difficulty == 'Hard',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _difficulty = 'Hard';
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
                    Text('Target Sequence — tap in order:',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_sequence.length, (i) {
                          final isNext = i == _currentIndex && !_isGameOver;
                          final isDone = i < _currentIndex;
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 34,
                            height: 34,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
            if (_showHint && !_isGameOver)
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
                nextExpectedNote: _sequence[_currentIndex],
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
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (_) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Home',
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
            // White keys — NO labels (hard mode)
            Row(
              children: _whiteNotes.map((note) {
                final isActive = activePressedKey == note;
                return GestureDetector(
                  onTap: () => onKeyTap(note),
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
                    child: difficulty == 'Medium'
                        ? Center(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : (isDark
                                            ? const Color(0xFF1F2937)
                                            : const Color(0xFF64748B)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            // Black keys — NO labels
            ..._blackNoteData.map((data) {
              final note = data['note'] as String;
              final pos = data['pos'] as int;
              final isActive = activePressedKey == note;
              final left = (pos + 1) * whiteW - (blackW / 2);
              return Positioned(
                left: left,
                top: 0,
                child: GestureDetector(
                  onTap: () => onKeyTap(note),
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
                    child: difficulty == 'Medium'
                        ? Center(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
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
