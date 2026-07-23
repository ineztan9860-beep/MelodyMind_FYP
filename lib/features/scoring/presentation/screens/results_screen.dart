import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/high_score_repository.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final int finalScore;
  final double accuracy;
  final int xpGained;

  const ResultsScreen({
    super.key, 
    required this.finalScore,
    this.accuracy = 0.0,
    this.xpGained = 0,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = ref.read(userProfileNotifierProvider).value;
    if (user != null) {
      await HighScoreRepository().saveHighScore(user.uid, widget.finalScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(Icons.close, color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A), size: 24),
                    ),
                  ),
                   Text('Level Complete', style: theme.textTheme.headlineMedium),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // --- SCORE RADIAL ---
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: (widget.accuracy / 100).clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: theme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                    ),
                  ),
                  Column(
                    children: [
                       Text('Run Score', 
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        widget.finalScore.toString(),
                        style: theme.textTheme.displayLarge?.copyWith(fontSize: 64, color: isDark ? Colors.white : const Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // --- STATS GRID ---
              Row(
                children: [
                  Expanded(child: _buildResultBadge(context, 'Accuracy', '${widget.accuracy.round()}%', Icons.gps_fixed, const Color(0xFF10B981))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildResultBadge(context, 'Exp Gained', '+${widget.xpGained}', Icons.bolt, const Color(0xFFF59E0B))),
                ],
              ),

              const SizedBox(height: 60),

              // --- ACTIONS ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Play Again',
                  style: TextStyle(color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildResultBadge(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
           Text(value, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
