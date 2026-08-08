import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/widgets/firebase_options.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/game/presentation/screens/home_screen.dart';
import 'features/scoring/presentation/screens/leaderboard_screen.dart';
import 'features/game/presentation/screens/game_screen.dart';
import 'features/scoring/presentation/screens/results_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/game/presentation/screens/level_details_screen.dart';
import 'features/scoring/presentation/screens/analytics_screen.dart';
import 'features/scoring/presentation/screens/player_profile_screen.dart';
import 'features/game/presentation/screens/rhythm_challenge_screen.dart';
import 'features/game/presentation/screens/sequence_memory_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/providers/audio_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/nav_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MelodyMindApp(),
    ),
  );
}


class MelodyMindApp extends ConsumerWidget {
  const MelodyMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;
    
    return MaterialApp(
      title: 'MelodyMind',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ),
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        fontFamily: 'Inter',
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        dividerColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF22D3EE),
          brightness: isDark ? Brightness.dark : Brightness.light,
        ).copyWith(
          surface: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
          headlineMedium: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E3A8A),
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF1E3A8A),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const AuthScreen(),
        '/home': (context) => const MainNavigation(),
        '/game': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return GameplayScreen(difficulty: args ?? 'Medium');
        },
        '/level_details': (context) => const LevelDetailsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/results': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return ResultsScreen(
              finalScore: args['score'] ?? 0,
              accuracy: args['accuracy'] ?? 0.0,
              xpGained: args['xpGained'] ?? 0,
            );
          }
          return ResultsScreen(finalScore: args is int ? args : 0);
        },
        '/rhythm': (context) => const RhythmChallengeScreen(),
        '/sequence': (context) => const SequenceMemoryScreen(),
        '/player_profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return PlayerProfileScreen(
            playerName: args?['name'] ?? 'David',
            playerRank: args?['rank'] ?? '3',
            playerXp: args?['xp'] ?? '13,900',
            playerImg: args?['img'] ?? 'https://i.pravatar.cc/150?u=david',
          );
        },
      },
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});
  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _screens = [
    const HomeScreen(),        // Home / Dashboard
    const AnalyticsScreen(),   // Progress / Analytics
    const LeaderboardScreen(), // Leaderboard
    const ProfileScreen(),     // Profile
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playBackgroundMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(navTabIndexProvider);
    
    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: Container(
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
          currentIndex: currentIndex,
          onTap: (index) => ref.read(navTabIndexProvider.notifier).state = index,
          selectedItemColor: const Color(0xFF22D3EE),
          unselectedItemColor: isDark ? Colors.white24 : const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
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
      ),
    );
  }
}
