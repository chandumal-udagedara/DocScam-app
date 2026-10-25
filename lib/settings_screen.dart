import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'services/progress_service.dart';

const _kNotificationsKey = 'notifications_enabled';

/// App settings screen.
/// - Notification toggle (stored in SharedPreferences)
/// - Clear all quiz progress
/// - Reset onboarding (for testing / re-runs)
/// - Privacy Policy link
/// - App version
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool(_kNotificationsKey) ?? true;
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsKey, value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _clearProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3A0047),
        title: Text(
          'Clear all progress?',
          style: GoogleFonts.playfairDisplay(color: Colors.white),
        ),
        content: Text(
          'All quiz scores, category history, and your leaderboard entry '
          'will be removed from this device. This cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.inter(
                    color: AppColors.ctaRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final svc = await ProgressService.getInstance();
    await svc.clearAllProgress();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress cleared.')),
      );
    }
  }

  Future<void> _resetOnboarding() async {
    await SharedPreferences.getInstance()
        .then((p) => p.remove('onboarding_complete'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Onboarding will show on next app launch.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, AppColors.headerBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_loading)
                const Expanded(
                  child:
                      Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      // ── Notifications ───────────────────────────────────
                      _sectionLabel('Notifications'),
                      _card(
                        child: SwitchListTile.adaptive(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeThumbColor: AppColors.seedPurple,
                          activeTrackColor: AppColors.seedPurple.withValues(alpha: 0.5),
                          title: Text(
                            'Quiz reminders',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Get a nudge after completing a quiz to try another category.',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Progress ─────────────────────────────────────────
                      _sectionLabel('Progress'),
                      _card(
                        child: ListTile(
                          leading: const Icon(Icons.delete_outline,
                              color: AppColors.ctaRed),
                          title: Text(
                            'Clear all quiz progress',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Removes all scores and history from this device.',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: _clearProgress,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── About ─────────────────────────────────────────────
                      _sectionLabel('About'),
                      _card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.privacy_tip_outlined,
                                  color: Colors.white70),
                              title: Text(
                                'Privacy Policy',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.white38),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/privacy'),
                            ),
                            Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1),
                            ListTile(
                              leading: const Icon(Icons.replay_outlined,
                                  color: Colors.white70),
                              title: Text(
                                'Replay intro',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Show the onboarding walkthrough again.',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: _resetOnboarding,
                            ),
                            Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1),
                            ListTile(
                              leading: const Icon(Icons.info_outline,
                                  color: Colors.white70),
                              title: Text(
                                'Version',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                '2.1.0',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Footer ────────────────────────────────────────────
                      Center(
                        child: Text(
                          '© 2025 ScamSlayers. All rights reserved.',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerTop, AppColors.headerBottom],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Settings',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
