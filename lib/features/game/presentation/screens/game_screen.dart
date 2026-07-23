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
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  int _multiplier = 1;
  double _progress = 0.0;
  bool _isGameOver = false;
  String _targetNote = 'C';
  String? _selectedNote;
  bool? _isCorrect;
  late List<String> _notes;
  final Random _random = Random();
  bool _showHint = false;

  int _correctAnswers = 0;
  int _totalAnswers = 0;

  @override
  void initState() {
    super.initState();
    _initializeDifficulties();
    _initializeNotes();
    _pickRandomNote();
  }

  void _initializeDifficulties() {
    if (widget.difficulty == 'Hard') {
      _lives = 1;
    } else if (widget.difficulty == 'Medium') {
      _lives = 3;
    } else {
      _lives = 5;
    }
  }

  void _initializeNotes() {
    if (widget.difficulty == 'Easy') {
      _notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    } else if (widget.difficulty == 'Medium') {
      _notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C#', 'F#'];
    } else {
      _notes = [
        'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
      ];
    }
  }

  void _pickRandomNote() {
    setState(() {
      _targetNote = _notes[_random.nextInt(_notes.length)];
      _selectedNote = null;
      _isCorrect = null;
      _showHint = false;
    });
    Future.microtask(() {
      if (mounted) {
        ref.read(audioServiceProvider).playNote(_targetNote);
      }
    });
  }

  Future<void> _saveGameResults() async {
    await ref.read(userProfileNotifierProvider.notifier).saveGameResult(
          scoreGained: _score,
          xpGained: _score ~/ 10,
          correctAnswers: _correctAnswers,
          totalAnswers: _totalAnswers,
          incrementStreak: _correctAnswers > 0,
        );
    // Also save to high score board
    final playerName =
        ref.read(userProfileNotifierProvider).value?.name ?? 'Guest';
    await ref
        .read(highScoreRepositoryProvider)
        .saveHighScore(playerName, _score);
  }

  void _handleNoteTap(String note) {
    if (_selectedNote != null || _isGameOver) return;
    setState(() {
      _selectedNote = note;
      _isCorrect = (note == _targetNote);
      _totalAnswers++;
      if (_isCorrect!) {
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
        if (widget.difficulty == 'Hard') points = 200;
        if (widget.difficulty == 'Medium') points = 150;

        _score += (points * _multiplier);
        _progress = min(1.0, _progress + 0.05);
        ref.read(audioServiceProvider).playSuccess();
      } else {
        _streak = 0;
        _multiplier = 1;
        _lives = max(0, _lives - 1);
        ref.read(audioServiceProvider).playError();

        if (_lives == 0) {
          _isGameOver = true;
          _saveGameResults();
        }
      }
    });
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 16.0),
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
                                border:
                                    Border.all(color: theme.dividerColor),
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

                  const SizedBox(height: 8),
                  // Lives row
                  Row(
                    children: List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i < _lives
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: i < _lives
                              ? const Color(0xFFEF4444)
                              : theme.dividerColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Progress Bar
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFF22D3EE)
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Identify the Note',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Listen to the pitch and select the correct note.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

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
                          return CustomPaint(
                            size: Size(constraints.maxWidth, 130),
                            painter: StaffPainter(
                                targetNote: _targetNote, isDark: isDark),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Replay & Hint Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            ref.read(audioServiceProvider).playNote(_targetNote),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 6),
                            const Text('Replay Pitch',
                                style: TextStyle(
                                    color: Color(0xFF22D3EE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showHint = !_showHint;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _showHint ? const Color(0xFF10B981) : const Color(0xFF475569),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(_showHint ? 'Hint: $_targetNote' : 'Show Hint',
                                style: TextStyle(
                                    color: _showHint ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Feedback text
                  const SizedBox(height: 16),
                  if (_selectedNote != null && _isCorrect == false)
                    Text(
                      'Watch out! It\'s a $_targetNote.',
                      style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    )
                  else
                    const SizedBox(height: 18),

                  // ← spacing between feedback and note buttons
                  const SizedBox(height: 16),

                  // NOTE BUTTON GRID
                  Column(
                    children: _buildNoteButtons(),
                  ),

                  const SizedBox(height: 16),
                  // NEXT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed:
                          _selectedNote != null ? _pickRandomNote : null,
                      child: const Text('Next Question',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_isGameOver)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sentiment_very_dissatisfied,
                            size: 64, color: Color(0xFF22D3EE)),
                        const SizedBox(height: 16),
                        Text('Game Over',
                            style: theme.textTheme.headlineLarge),
                        const SizedBox(height: 4),
                        Text('Your Score: $_score',
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12))),
                            onPressed: () {
                              double acc = _totalAnswers == 0 ? 0.0 : (_correctAnswers / _totalAnswers) * 100;
                              int xp = _score ~/ 10;
                              Navigator.pushReplacementNamed(
                                context, '/results',
                                arguments: {'score': _score, 'accuracy': acc, 'xpGained': xp},
                              );
                            },
                            child: const Text('See Results',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Home',
                              style:
                                  TextStyle(color: Color(0xFF22D3EE))),
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

  List<Widget> _buildNoteButtons() {
    List<Widget> rows = [];
    const int itemsPerRow = 4;

    for (int i = 0; i < _notes.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < _notes.length) ? i + itemsPerRow : _notes.length;
      List<String> rowNotes = _notes.sublist(i, end);
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowNotes.map((n) => _buildNoteButton(n)).toList(),
        ),
      );
      if (end < _notes.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return rows;
  }

  Widget _buildNoteButton(String note) {
    final bool isSelected = _selectedNote == note;
    final bool isCorrect = note == _targetNote;
    final bool showResult = _selectedNote != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;
    Color textColor =
        isDark ? Colors.white70 : const Color(0xFF64748B);
    Color borderColor = theme.dividerColor;

    if (showResult) {
      if (isCorrect) {
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        borderColor = const Color(0xFF10B981);
      } else if (isSelected) {
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        borderColor = const Color(0xFFEF4444);
      }
    } else if (isSelected) {
      bgColor = const Color(0xFF1E3A8A)
          .withValues(alpha: isDark ? 0.3 : 0.1);
      borderColor = const Color(0xFF1E3A8A);
      textColor = isDark
          ? const Color(0xFF22D3EE)
          : const Color(0xFF1E3A8A);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleNoteTap(note),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 62,
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
        ),
      ),
    );
  }
}

class StaffPainter extends CustomPainter {
  final String targetNote;
  final bool isDark;
  StaffPainter({required this.targetNote, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;

    const double lineSpacing = 18;
    final double startY = (size.height - (4 * lineSpacing)) / 2;

    for (int i = 0; i < 5; i++) {
      double y = startY + (i * lineSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final int pos = _getNotePosition(targetNote);
    final double noteY = startY + (pos * (lineSpacing / 2));
    final double noteX = size.width / 2;

    final notePaint = Paint()
      ..color = isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(noteX, noteY);
    canvas.rotate(-0.2);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 12),
        notePaint);
    canvas.restore();

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
      oldDelegate.targetNote != targetNote || oldDelegate.isDark != isDark;
}
