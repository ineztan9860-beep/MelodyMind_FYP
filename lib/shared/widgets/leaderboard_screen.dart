import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/profile/providers/user_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String selectedTab = 'Global';

  String _getAvatar(UserProfile user) {
    if (user.profileImageUrl.isNotEmpty) return user.profileImageUrl;
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=1E3A8A&color=fff&size=128';
  }

  String _fmtScore(int s) => s
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(userProfileNotifierProvider);
    final currentUserId = currentUserAsync.value?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Leaderboard',
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: -1)),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22D3EE)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // TAB BAR (Pill shape)
                    Container(
                      height: 56,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildPillTab('Global'),
                          _buildPillTab('Friends'),
                          _buildPillTab('League'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // STREAM BUILDER FOR LEADERBOARD
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Users')
                          .orderBy('totalScore', descending: true)
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('Error loading leaderboard'));
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No players yet!'));
                        }

                        final users = docs
                            .map((d) => UserProfile.fromMap(
                                d.data() as Map<String, dynamic>, d.id))
                            .toList();

                        // Build Podium
                        Widget podium = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (users.length > 1)
                              _buildPodiumItem(users[1], 2, currentUserId),
                            if (users.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              _buildPodiumItem(users[0], 1, currentUserId),
                            ],
                            if (users.length > 2) ...[
                              const SizedBox(width: 12),
                              _buildPodiumItem(users[2], 3, currentUserId),
                            ]
                          ],
                        );

                        // Build List Items
                        List<Widget> listItems = [];
                        for (int i = 3; i < users.length; i++) {
                          listItems.add(_buildRankItem(i + 1, users[i], currentUserId));
                        }

                        return Column(
                          children: [
                            podium,
                            const SizedBox(height: 24),
                            // WHITE CONTENT AREA
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 32),
                                  // INVITE CARD
                                  _buildInviteCard(),
                                  const SizedBox(height: 32),
                                  ...listItems,
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: CustomPaint(
        painter: DashRectPainter(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.5)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Play with friends',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 4),
                    Text('Earn 500 XP for every friend who joins',
                        style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text('Invite',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(String label) {
    bool isActive = selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = label),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isActive
                    ? const Color(0xFF22D3EE)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(UserProfile user, int rank, String? currentUserId) {
    bool isFirst = rank == 1;
    bool isMe = user.uid == currentUserId;
    String nameDisplay = isMe ? '${user.name} (You)' : user.name;
    double avatarSize = isFirst ? 60 : 45;
    Color medalColor = isFirst
        ? const Color(0xFFFFB800)
        : (rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFCD7F32));

    String img = _getAvatar(user);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: medalColor,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: avatarSize,
                  backgroundImage: NetworkImage(img),
                  onBackgroundImageError: (_, __) {},
                  backgroundColor: const Color(0xFFCBD5E1),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text('$rank',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(nameDisplay,
            style: TextStyle(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1E3A8A),
                letterSpacing: -0.2)),
        Text(_fmtScore(user.totalScore),
            style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRankItem(int rank, UserProfile user, String? currentUserId) {
    bool isMe = user.uid == currentUserId;
    String nameDisplay = isMe ? '${user.name} (You)' : user.name;
    String img = _getAvatar(user);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isMe ? const Color(0xFF7DD3FC) : const Color(0xFFF1F5F9), 
              width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$rank',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      fontSize: 18)),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(img),
              onBackgroundImageError: (_, __) {},
              backgroundColor: const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameDisplay,
                      style: TextStyle(
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.2)),
                  Text('Level ${user.level}',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text(_fmtScore(user.totalScore),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontSize: 16,
                    letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }
}

class DashRectPainter extends CustomPainter {
  double strokeWidth;
  Color color;
  double gap;

  DashRectPainter(
      {this.strokeWidth = 2.0, this.color = Colors.red, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(RRect.fromLTRBR(
        0, 0, size.width, size.height, const Radius.circular(16)));

    Path dashPath = Path();
    double dashWidth = 10.0;
    double dashSpace = 5.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
