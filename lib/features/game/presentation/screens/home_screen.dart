import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import 'package:interactive_musical_game/core/providers/nav_provider.dart';
import 'mode_selection_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnimation =
        CurvedAnimation(parent: _barController, curve: Curves.easeOut);
    // Start after first frame so we can read the value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barController.forward();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = userProfileAsync.value;
    final userName = profile?.name ?? 'Guest';
    final level = profile?.level ?? 0;
    final totalScore = profile?.totalScore ?? 0;
    final streak = profile?.streak ?? 0;
    final accuracy = profile?.accuracy ?? 0.0;
    final levelProgress = profile?.levelProgress ?? 0.0;

    final String avatarUrl = (profile?.profileImageUrl ?? '').isNotEmpty
        ? profile!.profileImageUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=1E3A8A&color=fff&size=128';

    final bool isNetwork = kIsWeb ||
        avatarUrl.startsWith('http') ||
        avatarUrl.startsWith('blob:') ||
        avatarUrl.startsWith('//');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(navTabIndexProvider.notifier).state = 3;
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: theme.dividerColor, width: 2),
                          ),
                          child: ClipOval(
                            child: avatarUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(avatarUrl.split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : (isNetwork
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primary,
                                  )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back,',
                                style: theme.textTheme.bodyMedium),
                            Text(
                              userName,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ModeSelectionScreen()),
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- STATS BANNER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Level',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 2),
                            Text(
                              'Level $level',
                              style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white, fontSize: 28),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${accuracy.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const Text('Accuracy',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatItem(
                            _formatScore(totalScore), 'Total Score', theme),
                        const SizedBox(width: 36),
                        _buildStatItem('$streak', 'Day Streak', theme),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Animated XP progress bar
                    AnimatedBuilder(
                      animation: _barAnimation,
                      builder: (context, _) {
                        final animatedProgress =
                            levelProgress * _barAnimation.value;
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: animatedProgress.clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/level_details'),
                        child: const Text('See Level Details',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Game Modes', style: theme.textTheme.headlineMedium),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ModeSelectionScreen()),
                    ),
                    child: Text('See All', style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- GAME MODE CARDS ---
              _buildGameModeCard(
                context,
                theme,
                isDark,
                'Note Identification',
                'Test your pitch accuracy',
                const Color(0xFF22D3EE),
                Icons.queue_music,
                '/game',
              ),
              const SizedBox(height: 12),
              _buildGameModeCard(
                context,
                theme,
                isDark,
                'Rhythm Challenge',
                'Keep the beat perfectly',
                const Color(0xFF3B82F6),
                Icons.speed,
                '/rhythm',
              ),
              const SizedBox(height: 12),
              _buildGameModeCard(
                context,
                theme,
                isDark,
                'Sequence Memory',
                'Remember the musical pattern',
                const Color(0xFFF59E0B),
                Icons.memory,
                '/sequence',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return score
          .toString()
          .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return score.toString();
  }

  Widget _buildStatItem(String value, String label, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: Colors.white)),
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white70)),
      ],
    );
  }

  Widget _buildGameModeCard(BuildContext context, ThemeData theme, bool isDark,
      String title, String sub, Color bgColor, IconData icon, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.dividerColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(sub, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                size: 20),
          ],
        ),
      ),
    );
  }
}
