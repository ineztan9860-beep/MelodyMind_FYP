import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final level = userProfileAsync.value?.level ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo — pure ClipOval, no square behind it
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Level $level',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(width: 44), // balance
                ],
              ),
              const SizedBox(height: 24),

              Text('Select Game Mode',
                  style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Choose your challenge to earn XP and advance to the next level.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              _buildChallengeCard(
                context,
                theme,
                isDark,
                title: 'Note Identification',
                desc: 'Listen to a note and identify it correctly on the keyboard.',
                difficulty: 'Easy',
                icon: Icons.queue_music,
                badgeBg: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                badgeText: const Color(0xFF22D3EE),
                btnColor: const Color(0xFF22D3EE),
                onTap: () =>
                    Navigator.pushNamed(context, '/game', arguments: 'Easy'),
              ),
              const SizedBox(height: 16),

              _buildChallengeCard(
                context,
                theme,
                isDark,
                title: 'Rhythm Challenge',
                desc: 'Play the piano in time — hit the right keys on the beat.',
                difficulty: 'Medium',
                icon: Icons.speed,
                badgeBg: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                badgeText: const Color(0xFF3B82F6),
                btnColor: const Color(0xFF3B82F6),
                onTap: () => Navigator.pushNamed(context, '/rhythm', arguments: 'Medium'),
              ),
              const SizedBox(height: 16),

              _buildChallengeCard(
                context,
                theme,
                isDark,
                title: 'Sequence Memory',
                desc: 'Listen to the note sequence and repeat it perfectly.',
                difficulty: 'Hard',
                icon: Icons.memory,
                badgeBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                badgeText: const Color(0xFFF59E0B),
                btnColor: const Color(0xFFF59E0B),
                onTap: () => Navigator.pushNamed(context, '/sequence'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required String title,
    required String desc,
    required String difficulty,
    required IconData icon,
    required Color badgeBg,
    required Color badgeText,
    required Color btnColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Matching icon (same as home screen game mode cards)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: isDark ? Colors.white70 : badgeText, size: 24),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? badgeBg.withValues(alpha: 0.15) : badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: isDark ? badgeBg : badgeText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(desc, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Play Mode',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
