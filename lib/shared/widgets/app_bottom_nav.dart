import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/nav_provider.dart';

/// A bottom navigation bar that can be added to any screen.
/// Tapping a tab navigates to /home and sets the correct tab index.
class AppBottomNav extends ConsumerWidget {
  /// Pass -1 if you are inside a sub-screen (game, rhythm, etc.)
  /// and no tab should be highlighted.
  final int currentIndex;

  const AppBottomNav({super.key, this.currentIndex = -1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void goToTab(int index) {
      ref.read(navTabIndexProvider.notifier).state = index;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: goToTab,
        selectedItemColor: const Color(0xFF22D3EE),
        unselectedItemColor:
            isDark ? Colors.white24 : const Color(0xFF94A3B8),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_filled),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.leaderboard_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.leaderboard),
            ),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.emoji_events_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.emoji_events),
            ),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person_outline),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
