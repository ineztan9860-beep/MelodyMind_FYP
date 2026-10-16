import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_musical_game/core/providers/settings_provider.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _appVersion = '1.0.5';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
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
                  const SizedBox(width: 12),
                  Text('Settings', style: theme.textTheme.headlineMedium),
                  const Spacer(),
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

              // ── SOUND & APPEARANCE ──────────────────────────────────────
              _sectionLabel('Sound & Appearance', theme),
              const SizedBox(height: 10),

              _switchTile(
                context,
                theme,
                isDark,
                icon: Icons.volume_up_outlined,
                label: 'Sound Effects',
                subtitle: 'Music notes and UI sounds',
                value: settings.isSoundEnabled,
                onChanged: (v) => notifier.toggleSound(v),
              ),
              const SizedBox(height: 10),
              _switchTile(
                context,
                theme,
                isDark,
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                subtitle: 'Switch app appearance',
                value: settings.isDarkMode,
                onChanged: (v) => notifier.toggleDarkMode(v),
              ),
              const SizedBox(height: 28),

              // ── ACCOUNT ────────────────────────────────────────────────
              _sectionLabel('Account', theme),
              const SizedBox(height: 10),
              _tapTile(
                context,
                theme,
                isDark,
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: 'Push alerts and reminders',
                onTap: () => _showNotificationsDialog(context),
              ),
              const SizedBox(height: 28),

              // ── ABOUT ──────────────────────────────────────────────────
              _sectionLabel('About', theme),
              const SizedBox(height: 10),
              _tapTile(
                context,
                theme,
                isDark,
                icon: Icons.info_outline,
                label: 'About MelodyMind',
                subtitle: 'Version $_appVersion',
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 10),
              _tapTile(
                context,
                theme,
                isDark,
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                subtitle: 'View our data practices',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Privacy policy coming soon')),
                  );
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'MelodyMind v$_appVersion',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, ThemeData theme) => Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          letterSpacing: 0.8,
          fontSize: 11,
          color: const Color(0xFF94A3B8),
        ),
      );

  Widget _switchTile(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleLarge),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _tapTile(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, color: const Color(0xFF1E3A8A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleLarge),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: isDark
                    ? Colors.white24
                    : const Color(0xFFCBD5E1),
                size: 18),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: ClipOval(
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('About MelodyMind',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MelodyMind is an interactive musical training app designed to help you identify notes, build rhythm, and sharpen your musical memory.',
            ),
            SizedBox(height: 14),
            Text('Version: 1.0.5',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('© 2026 MelodyMind. All rights reserved.'),
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

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'MelodyMind wants to send you reminders to keep your streak going and notify you of new challenges.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not now')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications enabled!')),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
