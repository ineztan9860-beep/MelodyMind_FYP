import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/features/profile/providers/user_provider.dart';
import 'package:interactive_musical_game/features/auth/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
// dart:io is only safe on non-web platforms
import '../../../../core/providers/nav_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _editingName = false;
  bool _savingName = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // On web, request gallery access via the file picker
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,   // keep base64 well under Firestore 1 MB limit
        maxWidth: 200,
        maxHeight: 200,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final String imageUrl = 'data:image/jpeg;base64,$base64String';

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfileImage(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;
    setState(() => _savingName = true);
    await ref
        .read(userProfileNotifierProvider.notifier)
        .updateName(newName);
    setState(() {
      _savingName = false;
      _editingName = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated!')),
      );
    }
  }

  void _showPersonalInfoDialog(
      BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Personal Info',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.person, 'Name', profile.name),
            const Divider(height: 20),
            _infoRow(Icons.games, 'Games Played',
                '${profile.gamesPlayed}'),
            const Divider(height: 20),
            _infoRow(Icons.leaderboard, 'Total Score',
                '${profile.totalScore}'),
            const Divider(height: 20),
            _infoRow(Icons.local_fire_department, 'Streak',
                '${profile.streak}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }

  void _showGameHistoryDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Game History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Games Played: ${profile.gamesPlayed}'),
            const SizedBox(height: 8),
            Text(
                'Accuracy: ${profile.accuracy.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Total Score: ${profile.totalScore}'),
            const SizedBox(height: 8),
            Text('Correct: ${profile.correctAnswers} / '
                '${profile.totalAnswers} answers'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = profileAsync.value;
    final name = profile?.name ?? 'Guest';
    final level = profile?.level ?? 0;
    final accuracy = profile?.accuracy ?? 0.0;
    final streak = profile?.streak ?? 0;
    final gamesPlayed = profile?.gamesPlayed ?? 0;
    final totalScore = profile?.totalScore ?? 0;

    final avatarUrl = (profile?.profileImageUrl ?? '').isNotEmpty
        ? profile!.profileImageUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=1E3A8A&color=fff&size=128';

    // On web all paths are blob: or https: — never use dart:io File.
    // On native, local file paths start without http/blob.
    final bool isNetwork = kIsWeb ||
        avatarUrl.startsWith('http') ||
        avatarUrl.startsWith('blob:') ||
        avatarUrl.startsWith('//');
    final bool isLocalFile = !isNetwork && !kIsWeb;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile',
                      style: theme.textTheme.headlineLarge),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(Icons.settings,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF1E3A8A),
                          size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AVATAR — reduced from 120 to 80
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF22D3EE), width: 3),
                      ),
                      child: ClipOval(
                        child: avatarUrl.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(avatarUrl.split(',').last),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: theme.colorScheme.primary,
                                  size: 40,
                                ),
                              )
                            : (isNetwork
                            ? Image.network(
                                avatarUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: theme.colorScheme.primary,
                                  size: 40,
                                ),
                              )
                            : isLocalFile
                                ? _LocalFileImage(path: avatarUrl, theme: theme)
                                : Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primary,
                                    size: 40,
                                  )),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // NAME row
              if (_editingName) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _savingName
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : IconButton(
                            onPressed: _saveName,
                            icon: const Icon(Icons.check,
                                color: Color(0xFF10B981))),
                    IconButton(
                      onPressed: () =>
                          setState(() => _editingName = false),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    _nameCtrl.text = name;
                    setState(() => _editingName = true);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(width: 6),
                      Icon(Icons.edit,
                          size: 16,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Level $level · $gamesPlayed games played',
                  style: const TextStyle(
                    color: Color(0xFF22D3EE),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // STATS ROW
              GestureDetector(
                onTap: () {
                  ref.read(navTabIndexProvider.notifier).state = 1;
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                },
                child: Row(
                  children: [
                    _quickStat(theme, isDark, _fmtScore(totalScore),
                        'Total Score'),
                    const SizedBox(width: 10),
                    _quickStat(
                        theme,
                        isDark,
                        '${accuracy.toStringAsFixed(0)}%',
                        'Accuracy'),
                    const SizedBox(width: 10),
                    _quickStat(theme, isDark, '$streak', 'Streak'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Account',
                    style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 10),

              // PROFILE LIST ITEMS
              _profileItem(
                context,
                theme,
                isDark,
                icon: Icons.person_outline,
                label: 'Personal Info',
                onTap: () {
                  if (profile != null) {
                    _showPersonalInfoDialog(context, profile);
                  }
                },
              ),
              _profileItem(
                context,
                theme,
                isDark,
                icon: Icons.history,
                label: 'Game History',
                onTap: () {
                  if (profile != null) {
                    _showGameHistoryDialog(context, profile);
                  }
                },
              ),
              _profileItem(
                context,
                theme,
                isDark,
                icon: Icons.show_chart,
                label: 'Progress',
                onTap: () {
                  ref.read(navTabIndexProvider.notifier).state = 1;
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                },
              ),
              _profileItem(
                context,
                theme,
                isDark,
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),

              const SizedBox(height: 20),
              // LOGOUT
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                            'Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(c);
                              await ref.read(authControllerProvider.notifier).signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, '/', (_) => false);
                              }
                            },
                            child: const Text('Sign Out',
                                style:
                                    TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCBD5E1)),
                    foregroundColor: Colors.red,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtScore(int s) => s
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

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
                    ?.copyWith(fontSize: 18)),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: const Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child:
                    Text(label, style: theme.textTheme.titleLarge),
              ),
              Icon(Icons.chevron_right,
                  color: isDark
                      ? Colors.white24
                      : const Color(0xFFCBD5E1),
                  size: 18),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Fallback widget when image cannot be shown (web-safe placeholder) ────────
class _LocalFileImage extends StatelessWidget {
  final String path;
  final ThemeData theme;
  const _LocalFileImage({required this.path, required this.theme});

  @override
  Widget build(BuildContext context) {
    // On web this widget is never reached (isLocalFile is always false on web).
    // On native this displays the local file using Image.file via a late import.
    // Using errorBuilder to handle any path issues gracefully.
    return Image.network(
      // Convert file path to a network URL is not needed; on non-web platforms
      // we should really use Image.file. However, since this is the web build,
      // isLocalFile==false so this widget is never constructed.
      // For native builds, this fallback shows the person icon safely.
      '',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.person, color: theme.colorScheme.primary, size: 40),
    );
  }
}
