import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/core/providers/settings_provider.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import 'package:interactive_musical_game/features/profile/data/user_repository.dart';

// ─── Real-time leaderboard provider ───────────────────────────────────────────
final leaderboardStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return UserRepository().getLeaderboardStream(limit: 20);
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String selectedTab = 'Global';

  // ── Avatar helper ─────────────────────────────────────────────────────────
  /// Returns the correct ImageProvider for a player entry.
  /// Handles: base64 data URIs, plain https URLs, and the ui-avatars fallback.
  ImageProvider _avatarImageProvider(String profileImageUrl, String name) {
    if (profileImageUrl.startsWith('data:image')) {
      try {
        final base64Str = profileImageUrl.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        // fall through to network fallback
      }
    }
    if (profileImageUrl.isNotEmpty &&
        (profileImageUrl.startsWith('http') ||
            profileImageUrl.startsWith('//'))) {
      return NetworkImage(profileImageUrl);
    }
    // ui-avatars fallback
    final url =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&size=128';
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userProfile = ref.watch(userProfileNotifierProvider).value;
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);
    final isDark = settings.isDarkMode;
    final theme = Theme.of(context);

    final myUid = userProfile?.uid ?? '';
    final myName = userProfile?.name ?? 'Guest';
    final myScore = userProfile?.totalScore ?? 0;
    final myLevel = userProfile?.level ?? 0;
    final myImgUrl = userProfile?.profileImageUrl ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: leaderboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load leaderboard.\n$e',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(leaderboardStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (players) {
            // Sort players by total score descending
            final sortedPlayers = players.map((p) {
              final newP = Map<String, dynamic>.from(p);
              String name = newP['name'] ?? '';
              if (name == 'Rozel') {
                newP['name'] = 'Itzak';
              } else if (name == 'marylide') {
                newP['name'] = 'Leena';
              } else if (name == 'roseliney') {
                newP['name'] = 'Sam';
                newP['profileImageUrl'] = '';
              }
              return newP;
            }).toList();
            sortedPlayers.sort((a, b) =>
                (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0));

            // If completely empty, seed with current user
            if (sortedPlayers.isEmpty) {
              sortedPlayers.add({
                'uid': myUid,
                'name': myName,
                'totalScore': myScore,
                'level': myLevel,
                'profileImageUrl': myImgUrl,
              });
            }

            // Build podium: #1, #2, #3
            final top1 =
                sortedPlayers.isNotEmpty ? sortedPlayers[0] : null;
            final top2 =
                sortedPlayers.length > 1 ? sortedPlayers[1] : null;
            final top3 =
                sortedPlayers.length > 2 ? sortedPlayers[2] : null;

            // Rank list (positions 4+)
            final rankList = sortedPlayers.length > 3
                ? sortedPlayers.sublist(3)
                : <Map<String, dynamic>>[];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Leaderboard',
                                style: theme.textTheme.headlineLarge),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: ClipOval(
                                child: Image.asset('assets/images/logo.png',
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Track your progress against others.',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 24),

                        // PILL TABS
                        Container(
                          height: 48,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.cardColor
                                : const Color(0xFF22D3EE)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              _buildPillTab('Global', isDark, theme),
                              _buildPillTab('Friends', isDark, theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // PODIUM — real data
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 2nd place
                            if (top2 != null)
                              _buildPodiumItem(
                                context,
                                top2['name'] ?? 'Player',
                                _formatScore(top2['totalScore'] ?? 0),
                                2,
                                top2['profileImageUrl'] ?? '',
                                top2['level'] ?? 0,
                              )
                            else
                              _buildPodiumItem(
                                  context, '—', '0', 2, myImgUrl, 0),
                            const SizedBox(width: 10),
                            // 1st place
                            if (top1 != null)
                              _buildPodiumItem(
                                context,
                                top1['name'] ?? 'Player',
                                _formatScore(top1['totalScore'] ?? 0),
                                1,
                                top1['profileImageUrl'] ?? '',
                                top1['level'] ?? 0,
                              )
                            else
                              _buildPodiumItem(
                                  context, '—', '0', 1, myImgUrl, 0),
                            const SizedBox(width: 10),
                            // 3rd place
                            if (top3 != null)
                              _buildPodiumItem(
                                context,
                                top3['name'] ?? 'Player',
                                _formatScore(top3['totalScore'] ?? 0),
                                3,
                                top3['profileImageUrl'] ?? '',
                                top3['level'] ?? 0,
                              )
                            else
                              _buildPodiumItem(
                                  context, '—', '0', 3, myImgUrl, 0),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CONTENT AREA
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border:
                          Border.all(color: theme.dividerColor, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // INVITE CARD
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF1E3A8A)
                                            .withValues(alpha: 0.3),
                                        const Color(0xFF0F172A),
                                      ]
                                    : [
                                        const Color(0xFF1E3A8A)
                                            .withValues(alpha: 0.05),
                                        const Color(0xFF22D3EE)
                                            .withValues(alpha: 0.05),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1E3A8A)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Play with friends',
                                          style:
                                              theme.textTheme.titleLarge),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Earn 500 XP for every friend who joins!',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      _showInviteDialog(context, myName),
                                  child: const Text('Invite',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // RANK LIST — real data from Firestore (positions 4+)
                        if (rankList.isEmpty && players.length <= 3)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 20),
                            child: Text(
                              'Only a few players so far — invite friends to compete!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        else
                          ...rankList.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;
                            final rank = idx + 4;
                            return _buildRankItem(
                              context,
                              rank,
                              p['name'] ?? 'Player',
                              _formatScore(p['totalScore'] ?? 0),
                              p['profileImageUrl'] ?? '',
                              p['level'] ?? 0,
                              theme,
                            );
                          }),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatScore(int score) {
    return score
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  void _showInviteDialog(BuildContext context, String referrer) {
    final inviteLink =
        'https://melodymind.app/join?ref=${Uri.encodeComponent(referrer)}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Invite Friends 🎵',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your link — earn 500 XP for every friend who signs up!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(inviteLink,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      ref
                          .read(userProfileNotifierProvider.notifier)
                          .addXP(500);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Invite link copied! You earned 500 XP.')),
                      );
                    },
                    child: const Icon(Icons.copy,
                        color: Color(0xFF1E3A8A), size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String label, bool isDark, ThemeData theme) {
    final bool isActive = selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? theme.primaryColor : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isActive
                    ? (isDark ? Colors.white : theme.colorScheme.secondary)
                    : (isDark ? Colors.white38 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(BuildContext context, String name, String score,
      int rank, String imgUrl, int level) {
    final bool isFirst = rank == 1;
    final double avatarR = isFirst ? 36.0 : 28.0;
    final Color medalColor = isFirst
        ? const Color(0xFFFFB800)
        : (rank == 2
            ? const Color(0xFF94A3B8)
            : const Color(0xFFCD7F32));
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/player_profile', arguments: {
          'name': name,
          'rank': rank.toString(),
          'xp': score,
          'img': imgUrl,
        });
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: medalColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: medalColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: avatarR,
                    backgroundImage:
                        _avatarImageProvider(imgUrl, name),
                    backgroundColor: theme.dividerColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
                child: Text('$rank',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(score,
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRankItem(BuildContext context, int rank, String name,
      String score, String imgUrl, int level, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () {
          if (selectedTab == 'Friends') {
            _showInviteDialog(
                context,
                ref.read(userProfileNotifierProvider).value?.name ??
                    'Guest');
          } else {
            Navigator.pushNamed(context, '/player_profile', arguments: {
              'name': name,
              'rank': rank.toString(),
              'xp': score,
              'img': imgUrl,
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 1.0),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text('$rank',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: _avatarImageProvider(imgUrl, name),
                backgroundColor:
                    isDark ? Colors.white10 : const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(letterSpacing: -0.2)),
                    Text('Level $level',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(score,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(letterSpacing: -0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
