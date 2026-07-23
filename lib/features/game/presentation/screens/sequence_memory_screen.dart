import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../profile/providers/user_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

class SequenceMemoryScreen extends ConsumerStatefulWidget {
  const SequenceMemoryScreen({super.key});

  @override
  ConsumerState<SequenceMemoryScreen> createState() =>
      _SequenceMemoryScreenState();
}

class _SequenceMemoryScreenState extends ConsumerState<SequenceMemoryScreen> {
  int _localScore = 0;
  int _round = 1;
  int _lives = 3;
  bool _isUsersTurn = false;
  bool _isGameOver = false;
  bool _showTutorial = true; // Show tutorial on first launch
  final List<String> _targetSequence = [];
  List<String> _userSequence = [];
  String? _activeColorNote;

  final List<Map<String, dynamic>> _notes = [
    {'note': 'C', 'color': const Color(0xFF1E3A8A), 'label': 'Do'},
    {'note': 'D', 'color': const Color(0xFF8B5CF6), 'label': 'Re'},
    {'note': 'E', 'color': const Color(0xFF10B981), 'label': 'Mi'},
    {'note': 'F', 'color': const Color(0xFFF59E0B), 'label': 'Fa'},
    {'note': 'G', 'color': const Color(0xFFEF4444), 'label': 'Sol'},
    {'note': 'A', 'color': const Color(0xFF22D3EE), 'label': 'La'},
  ];

  @override
  void initState() {
    super.initState();
    // Don't start the game until tutorial is dismissed
  }

  void _startGame() {
    setState(() => _showTutorial = false);
    _startNewRound();
  }

  void _startNewRound() async {
    setState(() {
      _isUsersTurn = false;
      _userSequence = [];
      _targetSequence.add(_notes[DateTime.now().millisecond % 6]['note']);
    });

    await Future.delayed(const Duration(seconds: 1));
    _playSequence();
  }

  void _playSequence() async {
    setState(() => _isUsersTurn = false);
    int delay = 600 ~/ (1 + (_round * 0.15));
    for (String note in _targetSequence) {
      if (!mounted) return;
      setState(() => _activeColorNote = note);
      ref.read(audioServiceProvider).playNote(note);
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      setState(() => _activeColorNote = null);
      await Future.delayed(Duration(milliseconds: delay ~/ 3));
    }
    if (mounted) setState(() => _isUsersTurn = true);
  }

  Future<void> _finishGame() async {
    setState(() => _isGameOver = true);
    double acc = (_round / (_round + 3 - _lives)) * 100;
    int xp = _localScore ~/ 10;

    await ref.read(userProfileNotifierProvider.notifier).saveGameResult(
          scoreGained: _localScore,
          xpGained: xp,
          correctAnswers: _round - 1,
          totalAnswers: _round + 3 - _lives,
          incrementStreak: _round > 1,
        );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/results', arguments: {
        'score': _localScore,
        'accuracy': acc,
        'xpGained': xp,
      });
    }
  }

  void _handleNoteTap(String note) {
    if (!_isUsersTurn || _isGameOver) return;

    ref.read(audioServiceProvider).playNote(note);
    setState(() => _userSequence.add(note));

    if (_userSequence.last != _targetSequence[_userSequence.length - 1]) {
      ref.read(audioServiceProvider).playError();
      setState(() {
        _lives--;
        _userSequence.clear();
      });
      if (_lives <= 0) {
        _finishGame();
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _playSequence();
        });
      }
    } else if (_userSequence.length == _targetSequence.length) {
      ref.read(audioServiceProvider).playSuccess();
      setState(() {
        _localScore += 500 * _round;
        _round++;
      });
      _startNewRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Icon(Icons.arrow_back,
                              color: isDark
                                  ? const Color(0xFF22D3EE)
                                  : const Color(0xFF1E3A8A),
                              size: 24),
                        ),
                      ),
                      Column(
                        children: [
                          Text('Round $_round',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Sequence Memory',
                              style: theme.textTheme.headlineMedium),
                        ],
                      ),
                      // Logo → home
                      GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (_) => false),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/logo.png',
                                width: 48, height: 48, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // HOW TO PLAY quick-ref banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Watch the colour tiles light up, then tap them back in the same order!',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showTutorial = true),
                          child: const Icon(Icons.help_outline,
                              size: 16, color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LIVES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < _lives ? Icons.favorite : Icons.favorite_border,
                          color: i < _lives
                              ? const Color(0xFFEF4444)
                              : theme.dividerColor,
                          size: 22,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // SCORE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.1 : 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CURRENT SCORE',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text(
                                _localScore.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},'),
                                style: theme.textTheme.headlineLarge
                                    ?.copyWith(fontSize: 28)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Round',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontSize: 11)),
                            Text('$_round',
                                style: theme.textTheme.headlineLarge
                                    ?.copyWith(
                                        fontSize: 28,
                                        color: const Color(0xFF8B5CF6))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_isGameOver) ...[
                    const SizedBox(height: 40),
                    const Text('GAME OVER!',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    Text('You reached Round $_round',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isGameOver = false;
                          _localScore = 0;
                          _round = 1;
                          _lives = 3;
                          _targetSequence.clear();
                        });
                        _startNewRound();
                      },
                      child: const Text('Try Again'),
                    )
                  ],

                  const SizedBox(height: 24),

                  // TURN INDICATOR
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isUsersTurn
                          ? const Color(0xFF10B981)
                          : const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (_isUsersTurn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF1E3A8A))
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isUsersTurn ? Icons.touch_app : Icons.visibility,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isUsersTurn ? 'YOUR TURN — Tap!' : 'WATCH & REMEMBER',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PROGRESS DOTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_targetSequence.length, (index) {
                      bool filled = index < _userSequence.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF8B5CF6)
                              : (isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0)),
                          shape: BoxShape.circle,
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // NOTE GRID (2x3)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final noteData = _notes[index];
                      final bool isActive =
                          _activeColorNote == noteData['note'];
                      return GestureDetector(
                        onTap: () => _handleNoteTap(noteData['note']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isActive
                                ? noteData['color']
                                : noteData['color']
                                    .withValues(alpha: isDark ? 0.4 : 0.8),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (isActive)
                                BoxShadow(
                                  color: noteData['color']
                                      .withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                noteData['note'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900),
                              ),
                              Text(
                                noteData['label'],
                                style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Tutorial overlay ─────────────────────────────────────────
            if (_showTutorial) _buildTutorial(context, theme, isDark),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildTutorial(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory,
                  size: 52, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 16),
              Text('How to Play',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 20),
              _tutorialStep('1', '👀 Watch',
                  'Coloured tiles will light up one by one — remember the order!',
                  theme),
              const SizedBox(height: 12),
              _tutorialStep('2', '👆 Tap',
                  'When "YOUR TURN" appears, tap the tiles in the EXACT same order.',
                  theme),
              const SizedBox(height: 12),
              _tutorialStep('3', '❤️ Lives',
                  'You have 3 lives. A wrong tap costs one life. Lose all 3 and the game ends.',
                  theme),
              const SizedBox(height: 12),
              _tutorialStep('4', '🏆 Score',
                  'Each correct round scores 500 × round number. Sequences get longer every round!',
                  theme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Let's Play!",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tutorialStep(
      String num, String title, String desc, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF8B5CF6),
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
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
