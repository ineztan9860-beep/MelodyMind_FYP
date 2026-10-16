import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import 'package:interactive_musical_game/features/profile/data/user_repository.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  final String playerName;
  final String playerRank;
  final String playerXp;
  final String playerImg;

  const PlayerProfileScreen({
    super.key,
    required this.playerName,
    required this.playerRank,
    required this.playerXp,
    required this.playerImg,
  });

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  bool _friendRequestSent = false;
  bool _sendingRequest = false;

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
  }

  Future<void> _checkFriendStatus() async {
    final myUid =
        ref.read(userProfileNotifierProvider).value?.uid ?? '';
    // Use the playerName as a rough uid stand-in (real impl would use uid)
    final already = await UserRepository()
        .hasSentFriendRequest(myUid, widget.playerName);
    if (mounted && already) {
      setState(() => _friendRequestSent = true);
    }
  }

  Future<void> _sendFriendRequest() async {
    final myUid =
        ref.read(userProfileNotifierProvider).value?.uid ?? '';
    if (myUid.isEmpty) return;
    setState(() => _sendingRequest = true);
    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UserRepository()
          .sendFriendRequest(myUid, widget.playerName);
      if (mounted) {
        setState(() {
          _friendRequestSent = true;
          _sendingRequest = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${widget.playerName}! 🎵'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  void _showMoreMenu(BuildContext context) {
    // Capture before async gap
    final messenger = ScaffoldMessenger.of(context);
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: const [
        PopupMenuItem(
          value: 'report',
          child: Row(children: [
            Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
            SizedBox(width: 10),
            Text('Report Player'),
          ]),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(children: [
            Icon(Icons.block, size: 18, color: Colors.red),
            SizedBox(width: 10),
            Text('Block Player'),
          ]),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(children: [
            Icon(Icons.share_outlined, size: 18, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text('Share Profile'),
          ]),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      String msg;
      switch (value) {
        case 'report':
          msg = '${widget.playerName} has been reported.';
          break;
        case 'block':
          msg = '${widget.playerName} has been blocked.';
          break;
        case 'share':
          msg = 'Profile link copied to clipboard!';
          break;
        default:
          return;
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  void _showChallengeDialog(BuildContext context) {
    String? selectedMode;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Challenge ${widget.playerName} ⚡',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a game mode for the challenge:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...[
                ('Note Identification', Icons.music_note),
                ('Rhythm Challenge', Icons.music_note_outlined),
                ('Sequence Memory', Icons.shuffle),
              ].map((item) {
                final isSelected = selectedMode == item.$1;
                return GestureDetector(
                  onTap: () => setDlgState(() => selectedMode = item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(item.$2,
                            color: isSelected
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF94A3B8),
                            size: 20),
                        const SizedBox(width: 12),
                        Text(item.$1,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFF475569))),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Color(0xFF1E3A8A), size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: selectedMode == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Challenge sent to ${widget.playerName} in $selectedMode! 🎯'),
                          backgroundColor: const Color(0xFF1E3A8A),
                        ),
                      );
                    },
              child: const Text('Send Challenge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF22D3EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: Text(
          'Player Profile',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // ── Fixed: 3-dot menu ──────────────────────────────────────────
          IconButton(
            icon: Icon(Icons.more_vert,
                color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => _showMoreMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            // USER HEADER
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF22D3EE), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 68,
                      backgroundImage: NetworkImage(widget.playerImg),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'Global #${widget.playerRank}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              widget.playerName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Rank #${widget.playerRank} • Melody Master',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // ── Action Buttons ──────────────────────────────────────────────
            Row(
              children: [
                // Challenge button — FIXED
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showChallengeDialog(context),
                    icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
                    label: const Text('Challenge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Add Friend button — FIXED with state change
                Expanded(
                  child: _sendingRequest
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _friendRequestSent
                              ? null
                              : _sendFriendRequest,
                          icon: Icon(
                            _friendRequestSent
                                ? Icons.check
                                : Icons.person_add_outlined,
                            color: _friendRequestSent
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            size: 20,
                          ),
                          label: Text(
                            _friendRequestSent ? 'Request Sent' : 'Add Friend',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _friendRequestSent
                                ? const Color(0xFF10B981)
                                : const Color(0xFF22D3EE),
                            foregroundColor: _friendRequestSent
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            disabledBackgroundColor:
                                const Color(0xFF10B981).withValues(alpha: 0.7),
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // STATS GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Total Score', widget.playerXp,
                    Icons.star_border, const Color(0xFFFFF7ED), Colors.amber,
                    isDark: isDark),
                _buildStatCard('Accuracy', '91%', Icons.gps_fixed,
                    const Color(0xFFECFDF5), const Color(0xFF10B981),
                    isDark: isDark),
                _buildStatCard(
                    'Current Streak',
                    '14 Days',
                    Icons.local_fire_department_outlined,
                    const Color(0xFFFEF2F2),
                    const Color(0xFFEF4444),
                    isDark: isDark),
                _buildStatCard('Games Played', '342', Icons.music_note_outlined,
                    const Color(0xFFF0F9FF), const Color(0xFF0EA5E9),
                    isDark: isDark),
              ],
            ),
            const SizedBox(height: 40),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Top Performance',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Note Identification',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF0F172A))),
                        SizedBox(height: 4),
                        Text('Mastery Level 19',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.playerXp,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1E3A8A))),
                      const Text('pts',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bg,
      Color tint, {bool isDark = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 22),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold))),
            ],
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }
}
