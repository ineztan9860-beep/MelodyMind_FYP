import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import 'package:interactive_musical_game/core/providers/nav_provider.dart';

// dart:html is only available on web — use conditional import
// ignore: avoid_web_libraries_in_flutter
import 'analytics_download_stub.dart'
    if (dart.library.html) 'analytics_download_web.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _animation;

  /// 'Weekly' or 'Monthly'
  String _reportPeriod = 'Monthly';

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation =
        CurvedAnimation(parent: _progressController, curve: Curves.easeOut);
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // ── Report download ────────────────────────────────────────────────────────
  void _downloadReport(UserProfile profile, bool isWeekly) {
    final int displayGames = isWeekly
        ? (profile.gamesPlayed / 4).ceil()
        : profile.gamesPlayed;
    final int displayCorrect = isWeekly
        ? (profile.correctAnswers / 4).ceil()
        : profile.correctAnswers;
    final int displayTotal = isWeekly
        ? (profile.totalAnswers / 4).ceil()
        : profile.totalAnswers;
    final double displayAccuracy = displayTotal == 0
        ? 0
        : (displayCorrect / displayTotal) * 100.0;
    final double displayHours = (displayGames * 3) / 60.0;

    final now = DateTime.now();
    final reportContent = '''
==============================================
  MelodyMind ${isWeekly ? 'Weekly' : 'Monthly'} Performance Report
==============================================
Generated : ${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}
Player    : ${profile.name}
Level     : ${profile.level}
Days since joining: ${profile.daysSinceCreated}

--- Performance Summary ---
Games Played  : $displayGames
Correct Ans.  : $displayCorrect / $displayTotal
Accuracy      : ${displayAccuracy.toStringAsFixed(1)}%
Training Time : ${displayHours.toStringAsFixed(1)} h
Total XP      : ${profile.xp}
Total Score   : ${profile.totalScore}
Streak        : ${profile.streak} day(s)

--- Skill Snapshot ---
Interval Perception : ${((profile.accuracy / 100.0) * 0.9 * 100).toInt()}%
Melodic Memory      : ${(profile.level * 4).clamp(2, 100)}%
Rhythmic Precision  : ${((profile.accuracy / 100.0) * 0.85 * 100).toInt()}%
Chord Recognition   : ${((profile.xp / 10000.0) * 100).clamp(2, 100).toInt()}%

==============================================
      Keep training — MelodyMind 🎵
==============================================
''';

    final fileName =
        'melodymind_${isWeekly ? 'weekly' : 'monthly'}_report_${now.year}${now.month}${now.day}.txt';

    downloadTextFile(reportContent, fileName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileNotifierProvider).value;

    // Real metrics from Firestore
    final int level = profile?.level ?? 0;
    final int xp = profile?.xp ?? 0;
    final double accuracy = profile?.accuracy ?? 0.0;
    final int correctAnswers = profile?.correctAnswers ?? 0;
    final int totalAnswers = profile?.totalAnswers ?? 0;
    final int gamesPlayed = profile?.gamesPlayed ?? 0;
    final int totalScore = profile?.totalScore ?? 0;
    final int daysSinceCreated = profile?.daysSinceCreated ?? 0;

    // Weekly estimates — approximate split (assume ~4 weeks)
    final int weeklyGames = (gamesPlayed / 4).ceil();
    final int weeklyCorrect = (correctAnswers / 4).ceil();
    final int weeklyTotal = (totalAnswers / 4).ceil();
    final double weeklyAccuracy = weeklyTotal == 0
        ? 0
        : (weeklyCorrect / weeklyTotal) * 100.0;
    final double weeklyHours = (weeklyGames * 3) / 60.0;

    // Select period values
    final bool isWeekly = _reportPeriod == 'Weekly';
    final int displayGames = isWeekly ? weeklyGames : gamesPlayed;
    final double displayAccuracy = isWeekly ? weeklyAccuracy : accuracy;
    final double displayHours =
        isWeekly ? weeklyHours : (gamesPlayed * 3) / 60.0;
    final int displayCorrect = isWeekly ? weeklyCorrect : correctAnswers;
    final int displayTotal = isWeekly ? weeklyTotal : totalAnswers;

    // Skill bars derived from real performance data
    final double accuracyFrac = (accuracy / 100.0).clamp(0.0, 1.0);
    final double intervalPerception = (accuracyFrac * 0.9).clamp(0.02, 1.0);
    final double melodicMemory = (level * 0.04).clamp(0.02, 1.0);
    final double rhythmicPrecision = (accuracyFrac * 0.85).clamp(0.02, 1.0);
    final double chordRecognition = (xp / 10000.0).clamp(0.02, 1.0);

    // ── Report gating ────────────────────────────────────────────────────
    final bool weeklyAvailable = daysSinceCreated >= 7;
    final bool monthlyAvailable = daysSinceCreated >= 30;
    final bool reportAvailable =
        isWeekly ? weeklyAvailable : monthlyAvailable;

    final int daysUntilAvailable = isWeekly
        ? (7 - daysSinceCreated).clamp(0, 7)
        : (30 - daysSinceCreated).clamp(0, 30);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.read(userProfileNotifierProvider.notifier).refreshProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: theme.textTheme.headlineLarge),
                    GestureDetector(
                      onTap: () {
                        ref.read(navTabIndexProvider.notifier).state = 0;
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (_) => false);
                      },
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
                const SizedBox(height: 8),
                Text('Pull to refresh', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),

                // MAIN STATS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.1 : 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow(
                        context,
                        'Accuracy',
                        '${accuracy.toStringAsFixed(1)}%',
                        const Color(0xFF22D3EE),
                        Icons.show_chart,
                        subtitle: '$correctAnswers / $totalAnswers correct',
                      ),
                      Divider(height: 28, color: theme.dividerColor),
                      _buildMetricRow(
                        context,
                        'Notes Identified',
                        '$correctAnswers',
                        const Color(0xFF3B82F6),
                        Icons.music_note,
                        subtitle: '$totalAnswers attempted',
                      ),
                      Divider(height: 28, color: theme.dividerColor),
                      _buildMetricRow(
                        context,
                        'Training Time',
                        '${((gamesPlayed * 3) / 60.0).toStringAsFixed(1)}h',
                        const Color(0xFFF59E0B),
                        Icons.timer,
                        subtitle: '$gamesPlayed games played',
                      ),
                      Divider(height: 28, color: theme.dividerColor),
                      _buildMetricRow(
                        context,
                        'Total Score',
                        _formatScore(totalScore),
                        const Color(0xFF8B5CF6),
                        Icons.emoji_events,
                        subtitle: 'Level $level earned',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                Text('Skill Breakdown', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 14),

                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        _buildSkillBar(theme, isDark, 'Interval Perception',
                            intervalPerception * _animation.value,
                            const Color(0xFF22D3EE)),
                        _buildSkillBar(theme, isDark, 'Melodic Memory',
                            melodicMemory * _animation.value,
                            const Color(0xFF3B82F6)),
                        _buildSkillBar(theme, isDark, 'Rhythmic Precision',
                            rhythmicPrecision * _animation.value,
                            const Color(0xFF8B5CF6)),
                        _buildSkillBar(theme, isDark, 'Chord Recognition',
                            chordRecognition * _animation.value,
                            const Color(0xFFF59E0B)),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── REPORT SECTION ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Performance Report',
                        style: theme.textTheme.headlineMedium),
                    // Weekly / Monthly toggle pill
                    Container(
                      height: 36,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.cardColor
                            : const Color(0xFF22D3EE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Weekly', 'Monthly'].map((period) {
                          final isActive = _reportPeriod == period;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _reportPeriod = period),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (isDark
                                        ? theme.primaryColor
                                        : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                period,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? (isDark
                                          ? Colors.white
                                          : theme.colorScheme.secondary)
                                      : (isDark
                                          ? Colors.white38
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // REPORT CARD (period-aware)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                              const Color(0xFF22D3EE).withValues(alpha: 0.05),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isWeekly ? Icons.calendar_today : Icons.bar_chart,
                        color: const Color(0xFF1E3A8A),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isWeekly ? 'Weekly Report' : 'Monthly Report',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isWeekly
                            ? 'This week: $displayGames games played with ${displayAccuracy.toStringAsFixed(1)}% accuracy\n'
                                '$displayCorrect correct out of $displayTotal • ${displayHours.toStringAsFixed(1)}h training'
                            : 'This month: $displayGames games played with ${displayAccuracy.toStringAsFixed(1)}% accuracy\n'
                                '$displayCorrect correct out of $displayTotal • ${displayHours.toStringAsFixed(1)}h training',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Mini stat row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _miniStat(theme, '$displayGames', 'Games'),
                          _miniStat(theme,
                              '${displayAccuracy.toStringAsFixed(0)}%',
                              'Accuracy'),
                          _miniStat(theme,
                              '${displayHours.toStringAsFixed(1)}h',
                              'Training'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Download button (gated) ──────────────────────────
                      if (!reportAvailable) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_clock,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Text(
                                'Available in $daysUntilAvailable day${daysUntilAvailable == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            if (profile != null) {
                              _downloadReport(profile, isWeekly);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${isWeekly ? 'Weekly' : 'Monthly'} report downloaded!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(
                            'Download ${isWeekly ? 'Weekly' : 'Monthly'} Report',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: const Color(0xFF1E3A8A), fontSize: 18)),
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
      ],
    );
  }

  String _formatScore(int score) {
    return score
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Widget _buildMetricRow(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge),
              if (subtitle != null)
                Text(subtitle,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
            ],
          ),
        ),
        Text(value,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
      ],
    );
  }

  Widget _buildSkillBar(ThemeData theme, bool isDark, String label,
      double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyLarge),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
