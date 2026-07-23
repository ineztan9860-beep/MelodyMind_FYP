import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

class LevelDetailsScreen extends ConsumerWidget {
  const LevelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = userAsync.value;
    final level = profile?.level ?? 0;
    final xp = profile?.xp ?? 0;
    final levelProgress = profile?.levelProgress ?? 0.0;
    final xpInLevel = xp % 1000;
    final accuracy = profile?.accuracy ?? 0.0;
    final gamesPlayed = profile?.gamesPlayed ?? 0;

    // Scale skill bars from accuracy + games as a proxy
    final accuracyFrac = (accuracy / 100.0).clamp(0.0, 1.0);
    final intervalPerception = (accuracyFrac * 0.9).clamp(0.02, 1.0);
    final rhythmPrecision =
        (accuracyFrac * 0.8 + gamesPlayed * 0.005).clamp(0.02, 1.0);
    final patternRecognition =
        (accuracyFrac * 0.95).clamp(0.02, 1.0);

    // Milestone labels based on level
    String milestone = 'Keep practising!';
    if (level >= 20) {
      milestone = 'Master Musician';
    } else if (level >= 10) {
      milestone = 'Advanced Chord Sets Unlocked';
    } else if (level >= 5) {
      milestone = 'Intermediate Patterns Unlocked';
    } else if (level >= 1) {
      milestone = 'Basic Notes Mastered';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
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
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
                          size: 20),
                    ),
                  ),
                  Text(
                    'Level $level Details',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Logo → navigate to home
                  GestureDetector(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // MILESTONE PROGRESS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark 
                    ? const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Color(0xFFF8FAFC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emoji_events,
                              color: Color(0xFF22D3EE), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Milestone',
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                milestone,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: levelProgress,
                        backgroundColor: isDark
                            ? Colors.white10
                            : const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF22D3EE)),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$xpInLevel / 1000 XP',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${(levelProgress * 100).toInt()}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22D3EE),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATS QUICK VIEW
              Row(
                children: [
                  _quickStat(theme, isDark, '$level', 'Level'),
                  const SizedBox(width: 12),
                  _quickStat(theme, isDark, '$gamesPlayed', 'Games'),
                  const SizedBox(width: 12),
                  _quickStat(theme, isDark,
                      '${accuracy.toStringAsFixed(1)}%', 'Accuracy'),
                ],
              ),

              const SizedBox(height: 24),
              Text('Skill Breakdown', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 14),
              _buildSkillBar('Interval Perception', intervalPerception,
                  const Color(0xFF1E3A8A), isDark, theme),
              _buildSkillBar('Rhythm Precision', rhythmPrecision,
                  const Color(0xFF22D3EE), isDark, theme),
              _buildSkillBar('Pattern Recognition', patternRecognition,
                  const Color(0xFF8B5CF6), isDark, theme),

              const SizedBox(height: 24),
              Text('Unlock Requirements',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              _buildRequirement(
                  'Complete 5 games', gamesPlayed >= 5, isDark, theme),
              _buildRequirement(
                  'Reach 60% accuracy', accuracy >= 60, isDark, theme),
              _buildRequirement('Reach Level 5', level >= 5, isDark, theme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _quickStat(
      ThemeData theme, bool isDark, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(value,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 20)),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBar(String label, double value, Color color,
      bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('${(value * 100).toInt()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(
      String text, bool isDone, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone
                ? const Color(0xFF10B981)
                : (isDark
                    ? Colors.white24
                    : const Color(0xFFCBD5E1)),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDone
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark
                        ? Colors.white38
                        : const Color(0xFF64748B)),
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
