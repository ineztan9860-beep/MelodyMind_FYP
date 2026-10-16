import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/scoring/data/high_score_repository.dart';
import '../../../profile/providers/user_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../core/providers/audio_provider.dart';
import 'dart:math';

class GameplayScreen extends ConsumerStatefulWidget {
  final String difficulty;
  const GameplayScreen({super.key, required this.difficulty});
  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends ConsumerState<GameplayScreen> {
  // Mode configuration: Easy = Learn, Medium = Practise, Hard = Test
  late String _currentDifficulty;

  int _score = 0;
  int _lives = 3;
  static const int _maxLivesHard = 3;
  int _streak = 0;
  int _multiplier = 1;
  double _progress = 0.0;
  bool _isGameOver = false;
  bool _isLevelComplete = false;

  // 9 notes: C to F#
  static const List<String> _nineNotes = [
    'C', 'D', 'E', 'F', 'G', 'A', 'B', 'C#', 'F#'
  ];
  static const int _targetQuestions = 9;

  String _targetNote = 'C';
  String? _selectedNote;
  bool? _isCorrect;
  final Random _random = Random();

  // Mode-specific states
  int _mediumTries = 0; // Up to 2 tries for Medium mode
  bool _mediumShowHintAvailable = false;
  bool _showHint = false;
  final Set<String> _wrongNotes = {}; // Track wrong attempts for current question

  int _hardReplaysLeft = 1; // Only 1 replay allowed in Hard mode
  bool _revealHardNoteBriefly = false; // Shown after a wrong answer in Hard mode

  String _feedbackMessage = '';
  Color _feedbackColor = Colors.transparent;

  int _correctAnswers = 0;
  int _totalAnswers = 0;
  bool _canAdvanceToNext = false;

  @override
  void initState() {
    super.initState();
    _currentDifficulty = widget.difficulty;
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _streak = 0;
      _multiplier = 1;
      _progress = 0.0;
      _isGameOver = false;
      _isLevelComplete = false;
      _correctAnswers = 0;
      _totalAnswers = 0;
      _selectedNote = null;
      _isCorrect = null;
      _showHint = false;
      _mediumTries = 0;
      _mediumShowHintAvailable = false;
      _wrongNotes.clear();
      _hardReplaysLeft = 1;
      _revealHardNoteBriefly = false;
      _feedbackMessage = '';
      _feedbackColor = Colors.transparent;
      _canAdvanceToNext = false;

      if (_currentDifficulty == 'Hard') {
        _lives = _maxLivesHard;
      } else {
        _lives = 0; // No lives needed for Easy and Medium
      }
    });
    _pickNextNote();
  }

  void _pickNextNote() {
    if (_isGameOver || _isLevelComplete) return;
    setState(() {
      _targetNote = _nineNotes[_random.nextInt(_nineNotes.length)];
      _selectedNote = null;
      _isCorrect = null;
      _showHint = false;
      _mediumTries = 0;
      _mediumShowHintAvailable = false;
      _wrongNotes.clear();
      _hardReplaysLeft = 1;
      _revealHardNoteBriefly = false;
      _feedbackMessage = '';
      _feedbackColor = Colors.transparent;
      _canAdvanceToNext = false;
    });

    Future.microtask(() {
      if (mounted) {
        ref.read(audioServiceProvider).playNote(_targetNote);
      }
    });
  }

  void _replayPitch() {
    if (_currentDifficulty == 'Hard') {
      if (_hardReplaysLeft <= 0) return;
      setState(() => _hardReplaysLeft--);
    }
    ref.read(audioServiceProvider).playNote(_targetNote);
  }

  Future<void> _finishAndSave() async {
    if (_isGameOver || _isLevelComplete) return;
    setState(() => _isLevelComplete = true);
    await _saveGameResults();
  }

  Future<void> _saveGameResults() async {
    await ref.read(userProfileNotifierProvider.notifier).saveGameResult(
          scoreGained: _score,
          xpGained: _score ~/ 10,
          correctAnswers: _correctAnswers,
          totalAnswers: _totalAnswers,
          incrementStreak: _correctAnswers > 0,
          gameMode: 'Note Identification',
        );
    final playerName =
        ref.read(userProfileNotifierProvider).value?.name ?? 'Guest';
    await ref
        .read(highScoreRepositoryProvider)
        .saveHighScore(playerName, _score);
  }

  void _handleNoteTap(String note) {
    if (_selectedNote != null && _isCorrect == true) return;
    if (_isGameOver || _isLevelComplete) return;
    if (_currentDifficulty == 'Hard' && _isCorrect == false) return;

    if (_currentDifficulty == 'Medium') {
      if (_mediumTries >= 2 && note != _targetNote) return;
      if (_wrongNotes.contains(note)) return;
    }

    _totalAnswers++;
    final bool correct = (note == _targetNote);

    if (correct) {
      _handleCorrect(note);
    } else {
      _handleIncorrect(note);
    }
  }

  void _handleCorrect(String note) {
    final bool waitForNext = _currentDifficulty == 'Medium' && _showHint;

    setState(() {
      _selectedNote = note;
      _isCorrect = true;
      _correctAnswers++;
      _streak++;
      if (_streak >= 10) {
        _multiplier = 4;
      } else if (_streak >= 5) {
        _multiplier = 2;
      } else {
        _multiplier = 1;
      }

      int points = 100;
      if (_currentDifficulty == 'Hard') points = 200;
      if (_currentDifficulty == 'Medium') points = 150;

      _score += (points * _multiplier);
      _progress = min(1.0, _correctAnswers / _targetQuestions);
      _feedbackMessage = waitForNext
          ? 'Correct! Tap Next Question to continue'
          : 'Correct! +${points * _multiplier}';
      _feedbackColor = const Color(0xFF10B981);
      _canAdvanceToNext = true;
    });

    ref.read(audioServiceProvider).playSuccess();

    if (_correctAnswers >= _targetQuestions || _progress >= 1.0) {
      setState(() => _isLevelComplete = true);
      _saveGameResults();
    } else if (!waitForNext) {
      // Auto-advance after brief pause, or player can tap "Next Question"
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _canAdvanceToNext && !_isGameOver && !_isLevelComplete) {
          _pickNextNote();
        }
      });
    }
  }

  void _handleIncorrect(String note) {
    ref.read(audioServiceProvider).playError();

    if (_currentDifficulty == 'Easy') {
      // Easy Mode (Learn): No lives lost, encouragement to try again
      setState(() {
        _selectedNote = note;
        _isCorrect = false;
        _feedbackMessage = 'Wrong key, try again! Tap $_targetNote';
        _feedbackColor = const Color(0xFFEF4444);
        _canAdvanceToNext = true;
      });
    } else if (_currentDifficulty == 'Medium') {
      // Medium Mode (Practise): 2 tries allowed
      _mediumTries++;
      _wrongNotes.add(note);
      if (_mediumTries < 2) {
        setState(() {
          _selectedNote = note;
          _isCorrect = false;
          _feedbackMessage = 'Wrong Key! Try Again (Attempt 1/2)';
          _feedbackColor = const Color(0xFFEF4444);
          _canAdvanceToNext = false;
        });
      } else {
        // Exceeded 2 tries: unlock hint and wait for user to view hint / select
        setState(() {
          _selectedNote = note;
          _isCorrect = false;
          _mediumShowHintAvailable = true;
          _feedbackMessage = '2 tries used. Tap Hint to see the answer';
          _feedbackColor = const Color(0xFFEF4444);
          _canAdvanceToNext = false;
        });
      }
    } else {
      // Hard Mode (Test): Lose 1 life, brief note reveal & sound, wait for Next Question
      _lives = max(0, _lives - 1);
      setState(() {
        _selectedNote = note;
        _isCorrect = false;
        _streak = 0;
        _multiplier = 1;
        _revealHardNoteBriefly = true;
        _feedbackMessage = 'Wrong! It was $_targetNote. Tap Next Question to continue';
        _feedbackColor = const Color(0xFFEF4444);
        _canAdvanceToNext = true;
      });

      // Briefly replay correct note for ear correction
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) ref.read(audioServiceProvider).playNote(_targetNote);
      });

      if (_lives <= 0) {
        setState(() => _isGameOver = true);
        _saveGameResults();
      }
      // Note: Removed 1.8-second auto-advance. Player taps Next Question to continue.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileNotifierProvider).value;
    final level = profile?.level ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A),
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Level $level',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _score.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                    ],
                  ),

                  const SizedBox(height: 12),

                  // DIFFICULTY SELECTOR CHIPS (Easy = Learn, Medium = Practise, Hard = Test)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDifficultyChip('Easy', 'Easy (Learn)'),
                        const SizedBox(width: 8),
                        _buildDifficultyChip('Medium', 'Medium (Practise)'),
                        const SizedBox(width: 8),
                        _buildDifficultyChip('Hard', 'Hard (Test)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // STATS ROW: Lives (Hard only) & Goal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentDifficulty == 'Hard')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined,
                                  size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                'Lives: $_lives/$_maxLivesHard',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentDifficulty == 'Easy'
                                ? '📖 Learn Mode: No Lives'
                                : '🎯 Practise Mode: 2 Tries',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF22D3EE)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'Goal: $_correctAnswers/$_targetQuestions Notes',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF22D3EE)
                                : const Color(0xFF0284C7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Progress Bar
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Identify the Note',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getModeInstruction(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // EASY MODE: Learning Guide Banner
                  if (_currentDifficulty == 'Easy')
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF22D3EE).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.music_note,
                              color: Color(0xFF22D3EE), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Target Note Letter: $_targetNote',
                            style: const TextStyle(
                              color: Color(0xFF22D3EE),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Musical staff display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border:
                          Border.all(color: theme.dividerColor, width: 1.5),
                    ),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool shouldHideNote =
                              (_currentDifficulty == 'Hard' &&
                                  !_revealHardNoteBriefly &&
                                  _isCorrect != true);

                          return CustomPaint(
                            size: Size(constraints.maxWidth, 130),
                            painter: StaffPainter(
                              targetNote: _targetNote,
                              isDark: isDark,
                              hideNote: shouldHideNote,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Replay & Hint Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // REPLAY PITCH BUTTON
                      GestureDetector(
                        onTap: (_currentDifficulty == 'Hard' &&
                                _hardReplaysLeft <= 0)
                            ? null
                            : _replayPitch,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (_currentDifficulty == 'Hard' &&
                                        _hardReplaysLeft <= 0)
                                    ? Colors.grey
                                    : const Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentDifficulty == 'Hard'
                                  ? (_hardReplaysLeft > 0
                                      ? 'Replay Pitch (1 left)'
                                      : 'No Replays Left')
                                  : 'Replay Pitch',
                              style: TextStyle(
                                color: (_currentDifficulty == 'Hard' &&
                                        _hardReplaysLeft <= 0)
                                    ? Colors.grey
                                    : const Color(0xFF22D3EE),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // HINT BUTTON: Only in Medium mode (after 2 tries)
                      if (_currentDifficulty == 'Medium') ...[
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: _mediumShowHintAvailable
                              ? () => setState(() {
                                    _showHint = !_showHint;
                                    if (_showHint) {
                                      _canAdvanceToNext = true;
                                    }
                                  })
                              : null,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: !_mediumShowHintAvailable
                                      ? Colors.grey.withValues(alpha: 0.3)
                                      : (_showHint
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF475569)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _showHint
                                      ? Icons.lightbulb
                                      : Icons.lightbulb_outline,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                !_mediumShowHintAvailable
                                    ? 'Hint (2 tries)'
                                    : (_showHint
                                        ? 'Hint: $_targetNote'
                                        : 'Show Hint'),
                                style: TextStyle(
                                  color: !_mediumShowHintAvailable
                                      ? Colors.grey
                                      : (_showHint
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF64748B)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Feedback Text
                  const SizedBox(height: 12),
                  if (_feedbackMessage.isNotEmpty)
                    Text(
                      _feedbackMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const SizedBox(height: 18),

                  const SizedBox(height: 12),

                  // NOTE BUTTON GRID (9 Notes: C, D, E, F / G, A, B, C# / F#)
                  Column(
                    children: _buildNoteButtons(),
                  ),

                  const SizedBox(height: 16),

                  // NEXT QUESTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canAdvanceToNext
                            ? const Color(0xFF22D3EE)
                            : (isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0)),
                        foregroundColor: _canAdvanceToNext
                            ? Colors.black87
                            : (isDark ? Colors.white38 : Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (_canAdvanceToNext &&
                              !_isGameOver &&
                              !_isLevelComplete)
                          ? _pickNextNote
                          : null,
                      child: const Text('Next Question',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // FINISH & SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (!_isLevelComplete && !_isGameOver)
                          ? _finishAndSave
                          : null,
                      child: const Text('Finish & Save Score',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A))),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // GAME OVER / LEVEL COMPLETE MODAL
            if (_isGameOver || _isLevelComplete)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLevelComplete
                              ? Icons.emoji_events
                              : Icons.sentiment_very_dissatisfied,
                          size: 64,
                          color: _isLevelComplete
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF22D3EE),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLevelComplete ? 'Level Complete!' : 'Game Over',
                          style: theme.textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Score: $_score',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Accuracy: ${(_totalAnswers == 0 ? 0 : (_correctAnswers / _totalAnswers * 100)).toStringAsFixed(0)}%  •  XP: +${_score ~/ 10}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: () {
                              double acc = _totalAnswers == 0
                                  ? 0.0
                                  : (_correctAnswers / _totalAnswers) * 100;
                              int xp = _score ~/ 10;
                              Navigator.pushReplacementNamed(
                                context,
                                '/results',
                                arguments: {
                                  'score': _score,
                                  'accuracy': acc,
                                  'xpGained': xp,
                                  'gameMode': 'game',
                                  'difficulty': _currentDifficulty,
                                },
                              );
                            },
                            child: const Text('See Full Results',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF22D3EE),
                              side: const BorderSide(color: Color(0xFF22D3EE)),
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _resetGame,
                            child: const Text('Play Again',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (_) => false),
                          child: const Text('Back to Home',
                              style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildDifficultyChip(String mode, String label) {
    final bool isSelected = _currentDifficulty == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _currentDifficulty != mode) {
          setState(() {
            _currentDifficulty = mode;
            _resetGame();
          });
        }
      },
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  String _getModeInstruction() {
    switch (_currentDifficulty) {
      case 'Easy':
        return 'Learn: Listen, read the note letter, and observe staff alignment.';
      case 'Medium':
        return 'Practise: Identify note from staff and pitch. You have 2 tries!';
      case 'Hard':
        return 'Test: Pure ear training! Staff note is hidden. 1 replay, 3 lives.';
      default:
        return 'Listen to the pitch and select the correct note.';
    }
  }

  List<Widget> _buildNoteButtons() {
    // 9 notes in 3 rows: 4 notes, 4 notes, 1 note (F# spanning full row)
    final row1 = _nineNotes.sublist(0, 4); // C, D, E, F
    final row2 = _nineNotes.sublist(4, 8); // G, A, B, C#
    final row3 = [_nineNotes[8]]; // F#

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row1.map((n) => _buildNoteButton(n)).toList(),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row2.map((n) => _buildNoteButton(n)).toList(),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row3.map((n) => _buildNoteButton(n, isFullWidth: true)).toList(),
      ),
    ];
  }

  Widget _buildNoteButton(String note, {bool isFullWidth = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;
    Color textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    Color borderColor = theme.dividerColor;

    final bool isSelected = _selectedNote == note;
    final bool isTarget = note == _targetNote;
    final bool hasAnswered = _selectedNote != null;

    bool revealCorrect = false;
    if (_currentDifficulty == 'Easy') {
      revealCorrect = hasAnswered;
    } else if (_currentDifficulty == 'Hard') {
      revealCorrect = hasAnswered;
    } else if (_currentDifficulty == 'Medium') {
      revealCorrect = (_isCorrect == true) || _showHint;
    }

    if (revealCorrect && isTarget) {
      bgColor = const Color(0xFF10B981);
      textColor = Colors.white;
      borderColor = const Color(0xFF10B981);
    } else if (_wrongNotes.contains(note) || (isSelected && _isCorrect == false)) {
      bgColor = const Color(0xFFEF4444);
      textColor = Colors.white;
      borderColor = const Color(0xFFEF4444);
    }

    Widget button = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          note,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleNoteTap(note),
        child: button,
      ),
    );
  }
}

class StaffPainter extends CustomPainter {
  final String targetNote;
  final bool isDark;
  final bool hideNote;

  StaffPainter({
    required this.targetNote,
    required this.isDark,
    this.hideNote = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;

    const double lineSpacing = 18;
    final double startY = (size.height - (4 * lineSpacing)) / 2;

    // Draw the 5 staff lines
    for (int i = 0; i < 5; i++) {
      double y = startY + (i * lineSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // In Hard mode (or ear training), note is hidden
    if (hideNote) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    final int pos = _getNotePosition(targetNote);
    final double noteY = startY + (pos * (lineSpacing / 2));
    final double noteX = size.width / 2;

    final notePaint = Paint()
      ..color = isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    // Draw accidental '#' sign if sharp note
    if (targetNote.contains('#')) {
      final sharpPainter = TextPainter(
        text: TextSpan(
          text: '♯',
          style: TextStyle(
            color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      sharpPainter.paint(
        canvas,
        Offset(noteX - 22, noteY - (sharpPainter.height / 2)),
      );
    }

    // Draw notehead
    canvas.save();
    canvas.translate(noteX, noteY);
    canvas.rotate(-0.2);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 12),
        notePaint);
    canvas.restore();

    // Draw stem
    canvas.drawLine(
      Offset(noteX + 7, noteY),
      Offset(noteX + 7, noteY - 44),
      Paint()
        ..color = isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A)
        ..strokeWidth = 2.5,
    );
  }

  int _getNotePosition(String note) {
    const Map<String, int> positions = {
      'B': 0,
      'A#': 1,
      'A': 1,
      'G#': 2,
      'G': 2,
      'F#': 3,
      'F': 3,
      'E': 4,
      'D#': 5,
      'D': 5,
      'C#': 6,
      'C': 6,
    };
    return positions[note] ?? 0;
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) =>
      oldDelegate.targetNote != targetNote ||
      oldDelegate.isDark != isDark ||
      oldDelegate.hideNote != hideNote;
}
